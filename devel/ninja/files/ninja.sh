#!/bin/sh

if [ "${NINJA_JOBS}" != "" ] ;then
	exec ninja.bin -j "${NINJA_JOBS}" "$@"
else
	exec ninja.bin "$@"
fi
