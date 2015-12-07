#!/usr/bin/env bash

# chdir to the port directory
cd `dirname $0`
PORT=`port -q info --name`
PORTDIR=`basename ${PWD}`
cd ..
CATDIR=`basename ${PWD}`
cd ..

EXTRAFILES="_resources/port1.0/group/kf5-1.1.tcl"

# echo ${PORT} ${CATDIR} ${PORTDIR}
tar -cvjf ${PORT}.tar.bz2 ${EXTRAFILES} ${CATDIR}/${PORTDIR}
ll -h ${PORT}.tar.bz2