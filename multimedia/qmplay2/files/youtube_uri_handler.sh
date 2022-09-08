#!/bin/sh

URL=""
if [ $# = 1 ] ;then
	case ${1} in
		youtube:*)
			URL="--open http://www.youtube.com/watch?v=`echo ${1} | cut -sd : -f 2`"
			;;
		*)
			echo "Ignoring unknown URI type \"${1}\"" 1>&2
			;;
	esac
fi

if [ "${URL}" != "" ] ;then
	exec QMPlay2 --show ${URL}
else
	echo "Usage: ${0} youtube:VID1" 1>&2
fi
