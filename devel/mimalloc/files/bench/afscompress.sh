#!/bin/sh

wdir=`port work mimalloc-bench`
#dirs="${wdir}/mimalloc-bench-git/ ${wdir}/build/"
dirs="${wdir}/build/"

afsctool -di ${dirs}
afsctool -c -n -9 -J${1} -S -L ${dirs} > /dev/null
