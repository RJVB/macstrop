#!/bin/sh

for J in "$@" ;do
	echo "{`openssl rmd160 $J | sed -e 's/.*)= //g'` `echo $J | sed -e 's/.*calligra-l10n-\(.*\)-2.9.2.tar.xz/\1/g'`}"
done

for J in "$@" ;do
	echo "{`openssl sha256 $J | sed -e 's/.*)= //g'` `echo $J | sed -e 's/.*calligra-l10n-\(.*\)-2.9.2.tar.xz/\1/g'`}"
done
