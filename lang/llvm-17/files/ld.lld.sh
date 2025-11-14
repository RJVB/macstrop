#!/bin/sh
# lld wrapper for Linux

LLD=@SUBPREFIX@/bin/wrapped/ld.lld

verbose=0
parse_args () {
	# scan $@ in a function so we shift a copy and can still pass "${@}" to the actual binary below
	while [ $# != 0 ] ;do
		case $1 in
			-v|--verbose)
				verbose=1
				;;
		esac
		shift 1
	done
}
parse_args "${@}"

if [ ${verbose} = 1 ] ;then
	# if all went well, "${@}" is exactly the list of argument passed by our caller
	echo "${0}->${LLD} "${@}" ${PV}" 1>&2
fi
exec ${LLD} "${@}" ${PV}
			

