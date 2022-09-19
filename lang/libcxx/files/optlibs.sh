#!/bin/sh

if [ -x @PREFIX@/lib/libcxx/libc++.1.dylib ] ;then
	LIBCXXPATH=@PREFIX@/lib/libcxx
else
	LIBCXXPATH=@PREFIX@/lib
fi

if [ "${DYLD_INSERT_LIBRARIES}" != "" ] ;then
	DYLD_INSERT_LIBRARIES="${DYLD_INSERT_LIBRARIES}:${LIBCXXPATH}/libc++abi.1.dylib:${LIBCXXPATH}/libc++.1.dylib"
else
	DYLD_INSERT_LIBRARIES="${LIBCXXPATH}/libc++abi.1.dylib:${LIBCXXPATH}/libc++.1.dylib"
fi
export DYLD_INSERT_LIBRARIES

exec "$@"
