#!/usr/bin/env bash
#-------------------------------------------------------------------------------
#  Sample script to run the DNS image with params
#-------------------------------------------------------------------------------

#-- Main settings
IMG_NAME=dns-master      #-- container/image name
VERBOSE=1                #-- 1 - be verbose flag
SVER="20211103"

source functions.sh #-- Use common functions

stop_container   $IMG_NAME
remove_container $IMG_NAME

docker run -d \
  --name $IMG_NAME \
  -p 5353:53/udp \
  -p 5354:53/tcp \
  -v ./test-conf:/var/bind \
  -e VERBOSE=${VERBOSE} \
etaylashev/dns

exit 0