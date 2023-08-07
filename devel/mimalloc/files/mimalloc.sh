#!/bin/sh

if [ "${LD_PRELOAD}" = "" ] ;then
	LD_PRELOAD=@PREFIX@/lib/libmimalloc.so.2
else
	LD_PRELOAD="@PREFIX@/lib/libmimalloc.so.2:${LD_PRELOAD}"
fi
export LD_PRELOAD
exec "$@"
