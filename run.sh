#!/usr/bin/env bash
#-------------------------------------------------------------------------------
#  Sample script to run the DNS image with params
#-------------------------------------------------------------------------------

#-- Main settings
IMG_NAME=dns-test        #-- container/image name
VERBOSE=1                #-- 1 - be verbose flag
SVER="20231115"

#-- Check architecture
[[ $(uname -m) =~ ^armv7 ]] && ARCH="armv7-" || ARCH=""

source functions.sh      #-- Use common functions

stop_container   $IMG_NAME
remove_container $IMG_NAME

docker run -d \
  --name $IMG_NAME \
  -p 5353:53/udp \
  -p 5354:53/tcp \
  -p 8443:443/tcp \
  -v ./test-conf:/var/bind \
  -e VERBOSE=${VERBOSE} \
etaylashev/dns:${ARCH}latest

exit 0
