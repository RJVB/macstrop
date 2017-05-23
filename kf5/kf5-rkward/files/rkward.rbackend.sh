#!/bin/sh

if [ "${LD_LIBRARY_PATH}" != "" ] ;then
	# make sure that our Qt5 rpath is not masked by one from the host
	# R tends to mess this up so we have to clean up behind it
	export LD_LIBRARY_PATH="@QTLIBDIR@:${LD_LIBRARY_PATH}"
	printenv 1>&2
fi

exec ${0}.bin "$@"
