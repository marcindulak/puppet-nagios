#!/bin/sh
# NRPE check for zpool
# Written by: S�ren Klintrup <soren at klintrup.dk>
# Get your copy from http://soren.klintrup.dk/zpool/
# version 1.1

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
if [ -x "/sbin/zpool" ]
then
 DEVICES="$(zpool list -H -o name)"
else
 ERRORSTRING="zpool binary does not exist on system"
 ERR=3
fi
unset ERRORSTRING
unset OKSTRING
unset ERR

for DEVICE in ${DEVICES}
do
 DEVICESTRING="$(zpool list -H -o health ${DEVICE})"
 if [ "$(echo ${DEVICESTRING}|tr [:upper:] [:lower:]|sed -Ee 's/.*(degraded|faulted|offline|online|removed|unavail).*/\1/')" = "" ]
 then
  ERRORSTRING="${ERRORSTRING} / ${DEVICE}: unknown state"
  if ! [ "${ERR}" = 2 ];then ERR=3;fi
 else
  case $(echo ${DEVICESTRING}|tr [:upper:] [:lower:]|sed -Ee 's/.*(degraded|faulted|offline|online|removed|unavail).*/\1/') in
   degraded)
     ERR=2
     ERRORSTRING="${ERRORSTRING} / ${DEVICE}: DEGRADED"
    ;;
   faulted)
     ERR=2
     ERRORSTRING="${ERRORSTRING} / ${DEVICE}: FAULTED"
    ;;
   offline)
     ERR=2
     ERRORSTRING="${ERRORSTRING} / ${DEVICE}: OFFLINE"
    ;;
   removed)
     ERR=2
     ERRORSTRING="${ERRORSTRING} / ${DEVICE}: REMOVED"
    ;;
   unavail)
     ERR=2
     ERRORSTRING="${ERRORSTRING} / ${DEVICE}: UNAVAIL"
    ;;
   faulted)
    ERR=3
    ERRORSTRING="${ERRORSTRING} / ${DEVICE}: FAULTED"
    ;;
   online)
    OKSTRING="${OKSTRING} / ${DEVICE}: online"
    ;;
   esac
 fi
done
if [ "${1}" ]
then
 if [ "${ERRORSTRING}" ]
 then
  echo "${ERRORSTRING} ${OKSTRING}"|sed s/"^\/ "//|mail -s "$(hostname -s): ${0} reports errors" -E ${*}
 fi
else
 if [ "${ERRORSTRING}" -o "${OKSTRING}" ]
 then
  echo "${ERRORSTRING} ${OKSTRING}"|sed s/"^\/ "//
  exit ${ERR}
 else
  echo no zpool volumes found
  exit 3
 fi
fi
