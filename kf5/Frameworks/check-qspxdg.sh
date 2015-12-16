#!/bin/sh

PORT=""
OPTS=""
MULTIPLE=0
QSPXDGLIB=""

while [ $# != 0 ] ;do
	case $1 in
		-qsplib)
			QSPXDGLIB="$2"
			shift
			;;
		-*)
			OPTS="${OPTS} $1"
			;;
		*)
			if [ "${PORT}" != "" ];then
				MULTIPLE=1
			fi
			PORT="${PORT} $1"
			;;
	esac
	shift
done

DNAME="`dirname $0`"

if [ "${PORT}" != "" ] ;then
	for p in $PORT ;do
		pWD="`port work ${p}`" ; export pWD
		cd ${pWD}/destroot
		BINARIES="`find . -name '*.dylib' -o -name '*.so'`"
		echo "Port ${p}:"
		for b in ${BINARIES} ;do
			otool -L ${b} | fgrep QtQspXDG 2>&1 > /dev/null
			if [ $? = 0 ] ;then
				echo "\t\tdestroot:${b}: OK"
			else
				echo "\tdestroot:${b} does not link to the QtQspXDG activator"
			fi
		done
		if [ "${QSPXDGLIB}" != "" ] ;then
			otool -L opt/local/${QSPXDGLIB} | fgrep QtQspXDG 2>&1 > /dev/null
			if [ $? = 0 ] ;then
				echo "\t\tdestroot:./opt/local/${QSPXDGLIB}: OK"
			else
				echo "\tdestroot:./opt/local/${QSPXDGLIB} does not link to the QtQspXDG activator!!!"
			fi
		fi
		BINARIES=""
		if [ -d ./opt/local/bin ] ;then
			BINARIES="${BINARIES} `ls -1d ./opt/local/bin/* 2>/dev/null`"
		fi
		if [ -d ./opt/local/libexec/kde5/kf5 ] ;then
			BINARIES="${BINARIES} `ls -1d ./opt/local/libexec/kde5/kf5/* 2>/dev/null`"
		fi
		for b in ${BINARIES} ;do
			otool -L ${b} | fgrep QtQspXDG 2>&1 > /dev/null
			if [ $? = 0 ] ;then
				echo "\tdestroot:${b} links to the QtQspXDG activator"
			else
				if [ "${QSPXDGLIB}" != "" ] ;then
					otool -L ${b} | fgrep "${QSPXDGLIB}" 2>&1 > /dev/null
					if [ $? = 0 ] ;then
						echo "\t\tdestroot:${b}: OK"
					else
						otool -L ${b} | fgrep lib/libKF5 2>&1 > /dev/null
						if [ $? = 0 ] ;then
							echo "\tdestroot:${b} does not link to the QtQspXDG activator nor ${QSPXDGLIB} but links to other KF5 libs"
						else
							echo "\t\tdestroot:${b}: will use native QSPs!"
						fi
					fi
				else
					otool -L ${b} | fgrep lib/libKF5 2>&1 > /dev/null
					if [ $? = 0 ] ;then
						echo "\tdestroot:${b} does not link to the QtQspXDG activator but links to other KF5 libs!"
					else
						echo "\t\tdestroot:${b}: will use native QSPs!"
					fi
				fi
			fi
		done
	done
else
	echo "Usage: `basename $0` [-options] <port1> [port2 [port3 [...]]]"
fi
