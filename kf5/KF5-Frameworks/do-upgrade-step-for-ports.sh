#!/bin/sh

POPTS="$1"
STEP="$2"
COPTS="$3"
shift 3

FAILS=""
for J in "$@" ;do
    if [ "${COPTS}" != "" ] ;then
        port ${POPTS} ${STEP} `port-active-variants -echo ${J}` configure.optflags="${COPTS}"
    else
        port ${POPTS} ${STEP} `port-active-variants -echo ${J}`
    fi
    if [ $? != 0 ] ;then
        FAILS="${FAILS} ${J}"
    fi
done

if [ "${FAILS}" != "" ] ;then
    echo "Failures for step \"${STEP}\": ${FAILS}"
fi
