#!/usr/bin/env bash

# chdir to the port directory
cd `dirname $0`
PORT=`port -q info --name`
PORTDIR=`basename ${PWD}`
cd ..
CATDIR=`basename ${PWD}`
cd ..

EXTRAFILES="_resources/port1.0/group/kf5-1.1.tcl _resources/port1.0/group/locale_select-1.0.tcl "

# echo ${PORT} ${CATDIR} ${PORTDIR}
tar -cvjf ${PORT}.tar.bz2 ${EXTRAFILES} ${CATDIR}/${PORTDIR}
mv ${PORT}.tar.bz2 KF5-Frameworks.tar.bz2
ll -h KF5-Frameworks.tar.bz2
