#!/bin/bash
set -e

docker build --no-cache --rm \
  -t etaylashev/dns .
