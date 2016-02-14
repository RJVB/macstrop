#!/bin/sh

POPTS="$1"
STEP="$2"
COPTS="$3"
shift 3

for J in "$@" ;do
    if [ "${COPTS}" != "" ] ;then
        port ${POPTS} ${STEP} `port-active-variants -echo ${J}` configure.optflags="${COPTS}"
    else
        port ${POPTS} ${STEP} `port-active-variants -echo ${J}`
    fi
done
