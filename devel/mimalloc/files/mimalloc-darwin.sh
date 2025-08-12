#!/bin/sh

if [ "${DYLD_INSERT_LIBRARIES=}" = "" ] ;then
	DYLD_INSERT_LIBRARIES=@PREFIX@/lib/libmimalloc.3.dylib
else
	DYLD_INSERT_LIBRARIES="@PREFIX@/lib/libmimalloc.3.dylib:${DYLD_INSERT_LIBRARIES=}"
fi
export DYLD_INSERT_LIBRARIES
exec "$@"
