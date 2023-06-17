#!/bin/sh

prefix=@PREFIX@
exec_prefix=@PREFIX@
libdir=${exec_prefix}/lib

if [ "${LD_PRELOAD}" = "" ] ;then
	LD_PRELOAD=${libdir}/libjemalloc.so.2
else
	LD_PRELOAD="${libdir}/libjemalloc.so.2:${LD_PRELOAD}"
fi
export LD_PRELOAD
exec "$@"
