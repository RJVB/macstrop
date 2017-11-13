#!/usr/bin/env bash

set -x

# chdir to the port directory
cd `dirname $0`
PORT=`port -q info --name`
PORTDIR=`basename ${PWD}`
cd ..
CATDIR=`basename ${PWD}`
cd ..

EXTRAFILES=
EXCLUDEFILES="--exclude ${CATDIR}/${PORTDIR}/files/old --exclude ${CATDIR}/${PORTDIR}/.DS_Store"

# echo ${PORT} ${CATDIR} ${PORTDIR}
/opt/local/bin/bsdtar -c ${EXCLUDEFILES} \
    -vjf ${PORT}.tar.bz2 ${EXTRAFILES} ${CATDIR}/${PORTDIR}
ll -h ${PORT}.tar.bz2
