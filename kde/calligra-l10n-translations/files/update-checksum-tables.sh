#!/bin/sh

VERSION="`port info --version calligra-translations | sed -e 's|version: ||g'`"
echo "Calligra version: ${VERSION}"
PFILE="`port dir calligra-translations`/Portfile"
LANGS="`fgrep 'set languages' ${PFILE} | sed -e 's|set languages.*{\(.*\)}|\1|g'`"
FILES=""

set -e
echo "Fetching distfiles ..."
for J in ${LANGS} ;do
    FILE="`port distfiles calligra-l10n-$J | grep '^\[' | sed -e 's|.*\] ||g'`"
    if [ ! -r ${FILE} ] ;then
        port fetch calligra-l10n-$J
        echo "Fetched distfile ${FILE} for language $J"
    fi
    FILES="${FILES} ${FILE}"
done

echo "set rmd160s     {"
for J in $FILES ;do
    LANG=`echo $J | sed -e "s|.*calligra-l10n-\(.*\)-${VERSION}.tar.xz|\1|g"`
    echo "                    {`openssl rmd160 $J | sed -e 's/.*)= //g'` ${LANG}}"
done
echo "                }"

echo "set sha256s     {"
for J in $FILES ;do
    LANG=`echo $J | sed -e "s/.*calligra-l10n-\(.*\)-${VERSION}.tar.xz/\1/g"`
    echo "                    {`openssl sha256 $J | sed -e 's/.*)= //g'` ${LANG}}"
done
echo "                }"
