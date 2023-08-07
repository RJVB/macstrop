#!/bin/sh

if [ "${DYLD_INSERT_LIBRARIES=}" = "" ] ;then
	DYLD_INSERT_LIBRARIES=@PREFIX@/lib/libmimalloc.2.dylib
else
	DYLD_INSERT_LIBRARIES="@PREFIX@/lib/libmimalloc.2.dylib:${DYLD_INSERT_LIBRARIES=}"
fi
export DYLD_INSERT_LIBRARIES
exec "$@"
