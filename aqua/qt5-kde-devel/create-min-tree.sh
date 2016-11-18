#!/usr/bin/env bash
# create a minimal ports tree containing for port:qt5-kde*

if [ $# -lt 1 -o -f "$1" ] ;then
    echo "Usage: $0 <target directory>"
    exit -1
fi

ECHO="echo"

case $1 in
    /*)
        DEST="$1"
        ;;
    *)
        DEST="`pwd`/$1"
        ;;
esac

# chdir to the port directory
cd `dirname $0`
PORT=`port -q info --name`
PORTDIR=`basename ${PWD}`
cd ..
CATDIR=`basename ${PWD}`
cd ..

# we're now in the port tree itself

# required portgroups. 
PORTGROUPS="_resources/port1.0/group/qt5*-1.0.tcl \
    _resources/port1.0/group/qmake5-1.0.tcl"

${ECHO} mkdir -p "${DEST}/_resources/port1.0/group/"
${ECHO} rsync -aAXHv --delete ${PORTGROUPS} "${DEST}/_resources/port1.0/group/"

${ECHO} mkdir -p "${DEST}/${CATDIR}"
${ECHO} rsync -aAXHv --delete "${CATDIR}/${PORTDIR}" "${CATDIR}/qt5-kde" "${DEST}/${CATDIR}/"

${ECHO} mkdir -p "${DEST}/kde"
${ECHO} rsync -aAXHv --delete kde/Ciment-icons kde/OSXdg-icons "${DEST}/kde/"
