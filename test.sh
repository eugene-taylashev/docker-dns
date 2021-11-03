#!/usr/bin/env bash
#=============================================================================
# Perform functionality tests for the docker-dns image
#
#  Steps:
#  - create the test directory
#  - create the named.conf file
#  - create the zone file
#  - create the TSIG key file
#  - start the container/image
#  - verify it is running
#  - check dns resolution
#  - update dns record + verify
#  - check dns transfer
#  - stop the container
#  - remove fiels and the directory
#=============================================================================

#------------------------------------------------------------------------------------
#
#  Variable declarations
#
#------------------------------------------------------------------------------------
SVER="20211103"     #-- Updated date
VERBOSE=1          #-- 1 - be verbose flag

DIR_RUN=$(pwd)
DIR_DNS=${DIR_RUN}/test-conf
FCFG=${DIR_DNS}/named.conf      #-- configuration file is in the same directory as zone files
FZONE=${DIR_DNS}/test.case.zone #-- test zone file, not for a real domain
OKEY=test_update.key            #-- file with a test TSIG key for update and transfer
FKEY=${DIR_DNS}/${OKEY}
OUPD=update_cmd.txt  #-- command file with dynamic update to Bind
FUPD=${DIR_DNS}/${OUPD}

IMG_NAME=test-dns               #-- container/image name

DIG_PRE="/usr/bin/docker exec ${IMG_NAME} /bin/sh -c '/usr/bin/dig -4 @localhost "


n=0  #-- count number of tests
g=0  #-- count success
b=0  #-- count failure

#=============================================================================
#
#  MAIN()
#
#=============================================================================

source functions.sh        #-- Use common functions

dlog "[ok] - started docker-dns testing script ver $SVER on $(date)"

#-- create the test directory if not exists
if [ ! -d ${DIR_DNS} ] ; then
    mkdir ${DIR_DNS}
    is_critical "[ok] - created directory for test configuration ${DIR_DNS}" \
    "[not ok] - creating directory ${DIR_DNS}"
else
    dlog "[ok] - directory for test configuration ${DIR_DNS} exists"
fi

#-- create the named.conf file if not exists
if [ ! -s ${FCFG} ] ; then
    cat > ${FCFG} <<'EOCFG'

options {
    directory "/var/bind/";
    pid-file "/var/bind/named.pid";

    //-- IPv4 will work on all interfaces
    listen-on port 53 { any;  };

    //-- Disable IPv6:
    listen-on-v6 port 53 { none; };

    //-- Default settings, will be adjusted per zone
    allow-query { any; };
    allow-recursion { any; };
    allow-transfer { none; };
    allow-update { none; };

    //-- Forwarding options
    recursion yes;                 # enables resursive queries
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    //-- DNSSEC
    dnssec-validation auto;
};


//-- Disable command channel for the rndc utility on port 953
controls { };

//-- Redirect logging to STDERR to see with docker logs
logging {
    channel default_stderr { stderr; };
};

#===== TSIG keys =======
key "test_update" {
        algorithm hmac-sha256;
        secret "UvjtjVPz4LvavUhIrZPwQfD+rmFTEDqbBPNB2ZZqw98=";
};

#============== ZONEs =====================
zone "test.case" IN {
    type master;
    file "test.case.zone";
    allow-query { any; };
    allow-update { key test_update; };
	#-- not good security practice to use same key for update and transfer
    allow-transfer { key test_update; };

    //-- DNSSEC
    key-directory "/var/bind";
    auto-dnssec maintain;
    inline-signing yes;
};

EOCFG
    is_good "[ok] - created configuration file ${FCFG}" \
    "[not ok] - creating configuration file ${FCFG}"
else
    dlog "[ok] - configuration file ${FCFG} exists"
fi

#-- create the zone file if not exists
if [ ! -s ${FZONE} ] ; then
    cat > ${FZONE} <<'EOZONE'
$ORIGIN .
$TTL 86400      ; 1 day
test.case               IN SOA  ns1.test.case. admin.test.case. (
                                20210230   ; serial
                                3600       ; refresh (1 hour)
                                1800       ; retry (30 minutes)
                                604800     ; expire (1 week)
                                86400      ; minimum (1 day)
                                )
                        NS      ns1.test.case.
                        MX  5   mail.test.case.
$ORIGIN test.case.
ns1                     A       1.1.1.31
mail                    A       1.1.1.32
EOZONE

    is_good "[ok] - created configuration file ${FZONE}" \
    "[not ok] - creating configuration file ${FZONE}"
else
    dlog "[ok] - configuration file ${FZONE} exists"
fi


#-- create the TSIG key file if not exists
if [ ! -s ${FKEY} ] ; then
    cat > ${FKEY} <<'EOKEY'
key "test_update" {
        algorithm hmac-sha256;
        secret "UvjtjVPz4LvavUhIrZPwQfD+rmFTEDqbBPNB2ZZqw98=";
};
EOKEY

    is_good "[ok] - created key file ${FKEY}" \
    "[not ok] - creating key file ${FKEY}"
else
    dlog "[ok] - key file ${FKEY} exists"
fi


#-- create the update command file FUPD
if [ ! -s ${FUPD} ] ; then
    cat > ${FUPD} <<'EOUPD'
server localhost
update add new.test.case 86400 A 1.1.1.13
send
EOUPD

    is_good "[ok] - created update file ${FUPD}" \
    "[not ok] - creating update file ${FUPD}"
else
    dlog "[ok] - update file ${FUPD} exists"
fi


#-- start the container/image
stop_container   $IMG_NAME
remove_container $IMG_NAME

docker run -d \
  --name $IMG_NAME \
  -p 5353:53/udp \
  -p 5354:53/tcp \
  -v ${DIR_DNS}:/var/bind \
  -e VERBOSE=1 \
etaylashev/dns
is_critical "[ok] - started image ${IMG_NAME}" \
"[not ok] - started image ${IMG_NAME}"


#-- Test 1: container is running
n=$((n+1))

#docker ps
if is_run_container ${IMG_NAME}; then
    dlog "[ok] - ($n) Container docker-dns is running"
    g=$((g+1))
else 
    dlog "[not ok] - ($n) Container docker-dns is NOT running"
    b=$((b+1))

    #-- remove fiels and the directory
    rm -fr ${DIR_DNS}

    derr 'Aborting testing...'
    exit 13
fi


#== Test 2: DNS resolves A record
n=$((n+1))
CMD="${DIG_PRE} +short ns1.test.case'"

#docker exec test-dns /bin/sh -c "/usr/bin/dig -4 @localhost +short ns1.test.case"
RES_ALL=$(eval $CMD)

RES_DNS="1.1.1.31"      #-- expected result

if [ "$RES_ALL" == "$RES_DNS" ] ; then
    dlog "[ok] - ($n) DNS is resolving an A record"
    g=$((g+1))
else
    dlog "[not ok] - ($n) DNS is NOT resolving an A record"
    b=$((b+1))
fi

#== Test 3: DNSSEC
n=$((n+1))
CMD="${DIG_PRE} +dnssec +multiline mail.test.case'"

#docker exec test-dns /bin/sh -c "/usr/bin/dig -4  @localhost  +dnssec +multiline mail.test.case"
RES_ALL=$(eval $CMD)
RES_DNS='RRSIG'      #-- expected result

if grep -q "$RES_ALL" <<< $RES_DNS ; then
    dlog "[ok] - ($n) DNSSEC signing works"
    g=$((g+1))
else
    dlog "[not ok] - ($n) DNSSEC signing does NOT work"
    b=$((b+1))
fi

#== Test 4: dynamic DNS update with the TSIG key
n=$((n+1))
CMD="/usr/bin/docker exec ${IMG_NAME} /bin/sh -c '/usr/bin/nsupdate -k /var/bind/${OKEY} /var/bind/${OUPD}'"

#docker exec test-dns /bin/sh -c "/usr/bin/nsupdate -k /var/bind/test_update /var/bind/update_cmd.txt"
eval $CMD

if [ $? -eq 0 ]; then
    dlog "[ok] - ($n) DNS update is working"
    g=$((g+1))
else
    dlog "[not ok] - ($n) DNS update is NOT working"
    b=$((b+1))
fi

#== Test 5: DNS resolves the updated A record
n=$((n+1))
CMD="${DIG_PRE} +short new.test.case'"

#docker exec test-dns /bin/sh -c "/usr/bin/dig -4 @localhost +short new.test.case"
RES_ALL=$(eval $CMD)

RES_DNS="1.1.1.13"      #-- expected result

if [ "$RES_ALL" == "$RES_DNS" ] ; then
    dlog "[ok] - ($n) DNS is resolving the updated A record"
    g=$((g+1))
else
    dlog "[not ok] - ($n) DNS is NOT resolving the updated A record"
    b=$((b+1))
fi


#== Test 6: Zone Transfer with the TSIG key over 53/tcp
n=$((n+1))
CMD="${DIG_PRE} -k /var/bind/${OKEY} axfr test.case'"

#docker exec test-dns /bin/sh -c "/usr/bin/dig -4 @localhost -k /var/bind/test_update axfr test.case"
RES_ALL=$(eval $CMD)

RES_DNS='1.1.1.13'      #-- expected result
if grep -q "$RES_ALL" <<< $RES_DNS ; then
    dlog "[ok] - ($n) Zone Transfer is working"
    g=$((g+1))
else
    dlog "[not ok] - ($n) Zone Transfer is NOT working"
    b=$((b+1))
fi


#-- stop the container
stop_container   $IMG_NAME
remove_container $IMG_NAME

#-- remove fiels and the directory, 
#   we need root privileges as owneship has changed
sudo rm -fr ${DIR_DNS}
is_good "[ok] - removed test files and directory" \
"[not ok] - removing test files and directory"


#-- Done!
dlog "[ok] - We are done: $g - success; $b - failure; $n total tests"
exit 0

