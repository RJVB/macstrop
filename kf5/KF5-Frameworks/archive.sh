#!/usr/bin/env bash

# chdir to the port directory
cd `dirname $0`
PORT=`port -q info --name`
PORTDIR=`basename ${PWD}`
cd ..
CATDIR=`basename ${PWD}`
cd ..

EXTRAFILES="_resources/port1.0/group/kf5-1.1.tcl _resources/port1.0/group/kf5-frameworks-1.0.tcl _resources/port1.0/group/locale_select-1.0.tcl _resources/port1.0/group/cmake-1.1.tcl _resources/port1.0/group/code-sign-1.0.tcl"
EXTRAFILES="${EXTRAFILES} kf5/kf5-gpgmepp kf5/kf5-breeze-icons kf5/kf5-oxygen-icons5 kf5/kf5-osx-integration kde/QtCurve"

# echo ${PORT} ${CATDIR} ${PORTDIR}
tar -c  --exclude "*.kdev4" --exclude ".DS_Store" --exclude="*.orig" -vjf ${PORT}.tar.bz2 ${EXTRAFILES} ${CATDIR}/${PORTDIR}
mv ${PORT}.tar.bz2 KF5-Frameworks.tar.bz2
ll -h KF5-Frameworks.tar.bz2
