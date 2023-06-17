#!/bin/sh

prefix=@PREFIX@
exec_prefix=@PREFIX@
libdir=${exec_prefix}/lib

if [ "${DYLD_INSERT_LIBRARIES}" = "" ] ;then
	DYLD_INSERT_LIBRARIES=${libdir}/libjemalloc.2.dylib
else
	DYLD_INSERT_LIBRARIES="${libdir}/libjemalloc.2.dylib:${DYLD_INSERT_LIBRARIES}"
fi
export DYLD_INSERT_LIBRARIES
exec "$@"
