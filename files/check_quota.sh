#!/bin/sh
# NRPE check for missing  ZFS userquota
# version 1.1
limit=$1
limit=${limit:=100}

USERSPACE=/zhome/.userspace

if [ ! -f "$USERSPACE" ] ; then
    echo  "Can't find ${USERSPACE}"
    exit 2
fi

nearlimit=$(awk -v limit=$limit  '($1 !="TYPE" && $NF!="none") {per=$4/$5*100} (per>limit) {print $3":"per }' ${USERSPACE} | sort -t: -n -k2)
if [ -n "$nearlimit" ]; then
    echo "${nearlimit}"
    exit 1
else
   echo OK - None at 100% Quota
   exit 0
fi
