#!/bin/sh
# NRPE check for missing  ZFS userquota
# version 1.1

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
USERSPACE=/zhome/.userspace

if [ ! -f "$USERSPACE" ] ; then
    echo  "Can't find ${USERSPACE}"
    exit 2
fi

noquota=$(awk '{if ($NF=="none"&& $3 != "root") print $3} ' ${USERSPACE})
count=$(awk '($3!="root" && $NF=="none") {++c} END {print c}'  ${USERSPACE})

if [ -n "$noquota" ]; then
    [ $count -gt 1 ] && echo "$count Missing Quotas" || echo "$count Missing Quota"
    echo "$noquota"
    exit 1
else
    echo OK - No Missing Quotas
    exit 0
fi
