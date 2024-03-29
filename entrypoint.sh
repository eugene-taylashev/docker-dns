#!/bin/sh
#==============================================================================
# Entry point script for a Docker container to start a Bind9 DNS server
#==============================================================================

#=============================================================================
#
#  Variable declarations
#
#=============================================================================
SVER="20210219"     #-- Updated by Eugene Taylashev
#VERBOSE=1          #-- 1 - be verbose flag
DIR_DNS=/var/bind
FCFG=${DIR_DNS}/named.conf  #-- configuration file is in the same directory as zone files

source /functions.sh #-- Use common functions

#=============================================================================
#
#  MAIN()
#
#=============================================================================
dlog '============================================================================='
dlog "[ok] - starting entrypoint.sh ver $SVER"

get_container_details
id named  #-- get UID, GID

#-- Adjust permission
chown -R named:named ${DIR_DNS}

#-- Delete old pid file
if [ -f ${DIR_DNS}/named.pid ] ; then
    rm -f ${DIR_DNS}/named.pid
fi

#-- Verify that a configuration file exists, or create a simple one
if [ ! -s ${FCFG} ] ; then
    cat > ${FCFG} <<EOF

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
EOF
fi

#-- check configuration 
dlog "       Checking configuration in $FCFG"
named-checkconf ${FCFG}
is_good "[ok] - Bind DNS configuration in $FCFG is good" \
    "[not ok] - Bind DNS configuration in $FCFG is NOT good"

#-- start named with given config
dlog "[ok] - strating Bind9 DNS: "
/usr/sbin/named -4 -g -u named -c $FCFG
derr "[not ok] - finish of entrypoint.sh"

