#!/bin/sh

exported () {
	dlsym "$1" ${MPLSSYMBOLS} 2>&1 \
		| egrep 'libMacportsLegacySupport.a| 0x' | gsed -e '/: symbol not found/d' -e "s/ 0x/${so}&${se}/g"
}

exported2 () {
	dlsym "$1" ${MPLSSYMBOLS} 2>&1 \
		| egrep 'libMacportsLegacySupport.a| 0x' | gsed -e '/: symbol not found/d' \
			-e "s;^$1::;;g" \
			-e "s/0x[0-9a-fA-F]* /   /g" \
			-e 's: (/usr/lib: IGNORE (/usr/lib:g'
}

if [ $# -ge 1 ] ;then
	so="`tput smso`"
	se="`tput rmso`"

	# build our own dlsym copy?
	MPLSSYMBOLS="`nm --defined-only --just-symbol-name /opt/local/lib/libMacportsLegacySupport.a 2>&1 | sed -e 's/^_//g'`"
	exported "$1"
	echo
	exported2 "$1"
	echo
	echo "Check the presence of any of the symbols found in "$1" in `port work libcxx`/llvm*.src/libcxx/lib/libc++unexp.exp"
	echo " and remember that they need to have an underscore prepended in that file!!"
fi
