#!/bin/sh

if [ "${1}" != "" ] ;then
    CXX="${1}"
elif [ "${CXX}" = "" ] ;then
    CXX=c++
fi

# see http://libcxx.llvm.org/docs/BuildingLibcxx.html to understand the selection and replacement logic
echo | ${CXX} -Wp,-v -x c++ - -fsyntax-only 2>&1 | grep '^ .*/c++' | tr '\n' ';' | tr -d ' ' | sed -e 's/;$//g'
