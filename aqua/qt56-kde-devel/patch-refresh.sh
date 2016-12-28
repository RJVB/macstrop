#!/bin/sh

if [ $# -lt 3 ] ;then
    echo "`basename $0` portname sourcedir patchlist_filename"
    echo "\tthe patchlist filename is relative to 'port dir portname'/files"
    exit -1
fi

PORT="$1"
SRCDIR="$2"
PORTDIR="`port dir $1 | sed -e 's|/Volumes/Debian/MP9|/opt/local|g'`"
PORTFILE="`port file $1`"
PATCHLIST="$3"

if [ ! -d "${PORTDIR}" -o ! -d "${SRCDIR}" -o ! -r "${PORTDIR}/files/${PATCHLIST}" ] ;then
    exit -2
fi

cd ${SRCDIR}

gitdiff () {
    git diff --no-ext-diff HEAD -- .
}

PATCHLIST="`cat ${PORTDIR}/files/${PATCHLIST}`"
# unpatch:
# gitdiff | patch -Np1 -R
# 
# for P in ${PATCHLIST} ;do
#     PF="${PORTDIR}/files/${P}"
#     if [ -e ${PF} ] ;then
#         echo ${PF}
#         patch -Np1 -i ${PF}
#         mkdir -p "${PORTDIR}/files/refreshed"
#         gitdiff > "${PORTDIR}/files/refreshed/${P}"
#         patch -Np1 -R -i ${PF}
#         sleep 1
#     fi
# done

for P in "${PORTDIR}/files"/*.{diff,patch} ;do
    if [ -f ${P} ] ;then
        if [ ! -f "${PORTDIR}/files/refreshed/`basename ${P}`" ] ;then
            fgrep "`basename ${P}`" ${PORTFILE} 2>&1 > /dev/null
            if [ $? != 0 ] ;then
                echo "@@@ ${P} may be obsolete"
            fi
        else
            ls -ltr ${P} "${PORTDIR}/files/refreshed/`basename ${P}`"
        fi
    fi
done
