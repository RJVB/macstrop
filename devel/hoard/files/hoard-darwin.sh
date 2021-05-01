#!/bin/sh

export DYLD_INSERT_LIBRARIES=@PREFIX@/lib/libhoard.dylib:${LD_PRELOAD}
exec "$@"
