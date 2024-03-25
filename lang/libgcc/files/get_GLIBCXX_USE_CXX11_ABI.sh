#!/bin/sh

getDefines () {
	echo "#include <cstddef>" | "$@" -x c++ -CC -dD -E -o - -
}

getDefines "$@" | grep "_GLIBCXX_USE_CXX11_ABI.*[01]" | sed -e "s/#define/set/g"
