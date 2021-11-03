#!/bin/bash
#-----------------------------------------------------------------------------
# Sample script to backup the DNS configuration and data 
#   from the running container
#
# Alternatevely backup files from the mounted volume
#
# Updated on 2021-11-02 by Eugene Taylashev
#-----------------------------------------------------------------------------

#-- Main settings
IMG_NAME=test-dns      #-- container/image name
FILE_BACKUP=dns-$(date "+%Y%m%d").tgz
DIR_BACKUP=./

VERBOSE=1                #-- 1 - be verbose flag
SVER="20211102"


source functions.sh #-- Use common functions

dlog "[ok] - started backup script ver $SVER on $(date)"

#-- Test that the container is running
if is_run_container ${IMG_NAME}; then
    dlog "[ok] - Container ${IMG_NAME} is running"
else
    derr "[not ok] - Container ${IMG_NAME} is NOT running"
    derr 'Aborting backup...'
    exit 13
fi

#-- Create the archive on the running container
docker exec ${IMG_NAME} /bin/sh -c "/bin/tar cvzf /tmp/${FILE_BACKUP} /var/bind"
is_critical "[ok] - created backup ${FILE_BACKUP} inside ${IMG_NAME}" \
"[not ok] - creating backup ${FILE_BACKUP} inside ${IMG_NAME}"

#-- Copy it to the host
docker cp ${IMG_NAME}:/tmp/${FILE_BACKUP} ${DIR_BACKUP}
is_critical "[ok] - copied ${FILE_BACKUP} to ${DIR_BACKUP}" \
"[not ok] - copying ${FILE_BACKUP} to ${DIR_BACKUP}"

#-- Remove achive from container
docker exec ${IMG_NAME} /bin/sh -c "rm /tmp/${FILE_BACKUP}"
is_good "[ok] - removed ${FILE_BACKUP} from the container" \
"[not ok] - removing ${FILE_BACKUP} from the container"

#-- We done
dlog "[ok] - We done. Backup file is ${DIR_BACKUP}/${FILE_BACKUP}"
exit 0
