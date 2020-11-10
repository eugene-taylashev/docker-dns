#!/bin/bash
#==============================================================================
# Entry point script for a Docker container to start a Bind9 DNS server
#==============================================================================
set -e
#=============================================================================
#
#  Variable declarations
#
#=============================================================================
SVER="20201104"     #-- Updated by Eugene Taylashev
#VERBOSE=1          #-- 1 - be verbose flag
DIR_DNS=/var/named
DIR_TMP=/tmp
FCFG=${DIR_DNS}/named.conf  #-- configuration file is in the same directory as zone files

#=============================================================================
#
#  Function declarations
#
#=============================================================================
#-----------------------------------------------------------------------------
#  Output debugging/logging message
#------------------------------------------------------------------------------
dlog(){
  MSG="$1"
#  echo "$MSG" >>$FLOG
  [ $VERBOSE -eq 1 ] && echo "$MSG"
}
# function dlog


#-----------------------------------------------------------------------------
#  Output error message
#------------------------------------------------------------------------------
derr(){
  MSG="$1"
#  echo "$MSG" >>$FLOG
  echo "$MSG"
}
# function derr

#-----------------------------------------------------------------------------
#  Output good or bad message based on return status $?
#------------------------------------------------------------------------------
is_good(){
    STATUS=$?
    MSG_GOOD="$1"
    MSG_BAD="$2"
    
    if [ $STATUS -eq 0 ] ; then
        dlog "${MSG_GOOD}"
    else
        derr "${MSG_BAD}"
    fi
}
# function is_good

#-----------------------------------------------------------------------------
#  Output important parametrs of the container 
#------------------------------------------------------------------------------
get_container_details(){
    
    if [ $VERBOSE -eq 1 ] ; then
        echo '[ok] - getting container details:'
        echo '---------------------------------------------------------------------'

        #-- for Linux Alpine
        if [ -f /etc/alpine-release ] ; then
            OS_REL=$(cat /etc/alpine-release)
            echo "Alpine $OS_REL"
            apk -v info | sort
        fi
        #-- Ubuntu and other
        if [ -f /etc/os-release ] ; then
            sed -ne 's/PRETTY_NAME=//p' /etc/os-release
            apt list --installed 
        fi

        uname -a
        ip address
	id named
        echo '---------------------------------------------------------------------'
    fi
}
# function get_container_details


#=============================================================================
#
#  MAIN()
#
#=============================================================================
dlog '============================================================================='
dlog "[ok] - starting entrypoint.sh ver $SVER"

get_container_details


dlog "URL:${URL_CONF}"

#-- Check configuration URL
if [ "${URL_CONF}" == "none" ]; then

    #-- Check if configuration and zone files are mounted
    if [ ! - s ${FCFG} ] ; then
        derr "No configuration and Zone files"
        derr "Aborting..."
        derr "[not ok] - finish of entrypoint.sh"
        exit 1
    fi
else

    #-- Get configuration file
    wget -q --no-check-certificate -O ${DIR_TMP}/conf.7z ${URL_CONF}
    is_good "[ok] - downloaded Bind DNS configuration and zone files" \
            "[not ok] - downloading Bind DNS configuration and zone files"

    #-- Unpack configuration file with 7zip
    7z e -o${DIR_DNS} -p${SKEY} ${DIR_TMP}/conf.7z
    is_good "[ok] - unpacked DNS configuration and zone files" \
            "[not ok] - unpacking DNS configuration and zone files"

    if [ $VERBOSE -eq 1 ] ; then
        echo "List of files in ${DIR_DNS}:"
        ls -l ${DIR_DNS}/
    fi
fi 

#-- Adjust permission
chown -R named:named ${DIR_DNS}


#-- check configuration 
dlog "       Checking configuration in $FCFG"
named-checkconf ${FCFG}
is_good "[ok] - Bind DNS configuration in $FCFG is good" \
    "[not ok] - Bind DNS configuration in $FCFG is NOT good"

#-- start named with given config
dlog "[ok] - strating Bind9 DNS: "
/usr/sbin/named -g -u named -c $FCFG
derr "[not ok] - finish of entrypoint.sh"
