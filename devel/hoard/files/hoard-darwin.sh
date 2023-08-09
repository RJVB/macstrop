#!/bin/sh

if [ "${DYLD_INSERT_LIBRARIES}" != "" ] ;then
    export DYLD_INSERT_LIBRARIES="@PREFIX@/lib/libhoard.dylib:${DYLD_INSERT_LIBRARIES}"
else
    export DYLD_INSERT_LIBRARIES="@PREFIX@/lib/libhoard.dylib"
fi
exec "$@"
