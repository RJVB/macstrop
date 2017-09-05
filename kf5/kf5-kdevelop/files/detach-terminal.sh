#!/bin/sh

exec 0>&- # close stdin
exec 1>&- # close stdout
exec 2>&- # close stderr

exec "${0}.bin" "$@"
