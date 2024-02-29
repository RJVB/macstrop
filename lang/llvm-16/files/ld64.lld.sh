#!/bin/sh

LLD=@SUBPREFIX@/bin/wrapped/ld64.lld

ARGS="$@"
PV=""
verbose=0
while [ $# != 0 ] ;do
	case $1 in
		-macosx_version_min)
			PV="-platform_version macos $2 $2"
			;;
		-v|--verbose)
			verbose=1
			;;
	esac
	shift 1
done
if [ ${verbose} = 1 ] ;then
	echo "${0}->${LLD} ${ARGS} ${PV}" 1>&2
fi
exec ${LLD} ${ARGS} ${PV}
			

