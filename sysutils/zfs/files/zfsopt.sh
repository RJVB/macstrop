#!/bin/sh

RESTORE=""
COMP=""
COPIES=""
NOCHECKSUM=0
SYNC=""
DATASET=""
ECHO=""
OK=0

while [ $# != 0 ] ;do
    case $1 in
        -dataset|-d)
            shift
            DATASET="$1"
            ;;
        -compression|-T)
            shift
            COMP="$1"
            ;;
        -copies|-#)
            shift
            COPIES="$1"
            ;;
        -sync|-s)
            shift
            SYNC="$1"
            ;;
        -nc)
            NOCHECKSUM=1
            ;;
        -dry-run)
            ECHO=echo
            ;;
        --)
            OK=1
            shift
            break
            ;;
    esac
    shift
done

OCMP=""
OCPS=""
OSNC=""
OCHK=""

CleanUp() {
    # we're only install when all is well, so no need for more checking here
    echo "Restoring ZFS settings: compression=${OCMP} copies=${OCPS} checksum=${OCHK} sync=${OSNC}" 1>&2
    ${ECHO} zfs set "compression=${OCMP}" "checksum=${OCHK}" "sync=${OSNC}" "copies=${OCPS}" "${DSET}"
}

if [ "${DATASET}" != "" -a ${OK} = 1 ];then

    # allow the user to specify a file on the dataset instead of the dataset name itself
    DSET="`zfs list -H -o name ${DATASET}`"
    if [ $? = 0 ] ;then
        if [ "${DSET}" != "${DATASET}" ] ;then
            echo "Warning: applying ZFS settings to dataset \"${DSET}\" which holds \"${DATASET}\"" 1>&2
        fi
        OCMP="`zfs list -H -o compression ${DSET}`"
        OCPS="`zfs list -H -o copies ${DSET}`"
        OSNC="`zfs list -H -o sync ${DSET}`"
        OCHK="`zfs list -H -o checksum ${DSET}`"
        echo "Current ZFS settings: compression=${OCMP} copies=${OCPS} checksum=${OCHK} sync=${OSNC}" 1>&2
        trap "CleanUp" 0
        trap "CleanUp" 1
        trap "CleanUp" 2
        trap "CleanUp" 15
        if [ "${COMP}" != "" ] ;then
            ${ECHO} zfs set compression=${COMP} ${DSET}
        fi
        if [ ${NOCHECKSUM} != 0 ] ;then
            ${ECHO} zfs set checksum=off ${DSET}
        fi
        if [ "${SYNC}" != "" ] ;then
            ${ECHO} zfs set sync=${SYNC} ${DSET}
        fi
        if [ "${COPIES}" != "" ] ;then
            ${ECHO} zfs set copies=${COPIES} ${DSET}
        fi
        ${ECHO} "$@"
        RET=$?
        
    else
        echo "Dataset for \"${DATASET}\" could not be determined" 1>&2
        exit 2
    fi
else
    echo "No dataset and/or command specified!" 1>&2
    exit 1
fi
