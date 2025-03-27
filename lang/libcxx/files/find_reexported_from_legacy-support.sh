#!/bin/sh

if [ $# -ge 1 ] ;then
	so="`tput smso`"
	se="`tput rmso`"

	dlsym "$1" `nm --defined-only --just-symbol-name /opt/local/lib/libMacportsLegacySupport.a 2>&1 | sed -e 's/^_//g'` 2>&1 \
		| egrep 'libMacportsLegacySupport.a| 0x' | sed -e "s/ 0x/${so}&${se}/g"
	echo
	echo "Check the presence of any of the symbols found in "$1" in `port work libcxx`/llvm*.src/libcxx/lib/libc++unexp.exp"
	echo " and remember that they need to have an underscore prepended in that file!!"
fi
