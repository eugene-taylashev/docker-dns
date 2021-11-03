#!/bin/bash
set -e

#-- Check architecture
ARCH=""
[[ $(uname -m) =~ ^armv7 ]] && ARCH="armv7-"


docker build --no-cache --rm \
  -t etaylashev/dns:${ARCH}latest .
