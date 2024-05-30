#!/bin/sh

UDIR="files-updated"

if [ $# -lt 3 ] ;then
    echo "Usage: `dirname $0` <portname> <series-file> <source directory> [<updated-subdir>=${UDIR}]"
    echo "NB: the source dir is supposed to be a properly initialised git repo to which"
    echo "    commits can be made and files deleted without risk."
    echo "    Create a temp branch, or better, a work copy to run this script!"
    exit 255
fi

PORT="$1"
SERIES="$2"
# easier to ask this one!
WSRCPATH="$3"
if [ $# -gt 3 ] ;then
    UDIR="$4"
fi

PORTDIR="`port dir ${1}`"
FILESPATH="${PORTDIR}/files"

if [ -r ${SERIES} -a -d ${FILESPATH} -a -d ${WSRCPATH} ] ;then
    PATCHFILES="`cat ${SERIES}`"
    cd ${WSRCPATH}
    mkdir -p ${PORTDIR}/${UDIR}
    git clean -f -d
    NDIR="${PORTDIR}/${UDIR}/"
    if [ ! -r "${NDIR}/rejorig-ignored.state" ] ;then
        echo '*.rej' >> .gitignore
        echo '*orig' >> .gitignore
        git commit -m "${0} : ignore patch artifacts" .gitignore
        touch "${NDIR}/rejorig-ignored.state"
    fi
    for p in ${PATCHFILES} ;do
        mkdir -p "${NDIR}/`dirname ${p}`"
        if [ ! -r "${NDIR}/${p}" ] ;then
            patch -Np1 -i "${FILESPATH}/${p}"
            if [ $? = 0 ] ;then
                git add -v .
                git commit -m "${p}" .
                git show > "${NDIR}/${p}"
                echo "Updated patch stored as ${NDIR}/${p}"
            else
                echo "Patch failed:"
                echo "${FILESPATH}/${p}"
                exit 255
            fi
        else
            echo "Skipping already updated patch ${p}"
        fi
    done
fi
