#!/bin/sh

export LD_PRELOAD=@PREFIX@/lib/libhoard.so:${LD_PRELOAD}
exec "$@"
