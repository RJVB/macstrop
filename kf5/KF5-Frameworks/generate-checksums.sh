#!/bin/sh

if [ "${prefix}" = "" ] ;then
    prefix=/opt/local
fi

version=5.35.0
branch=${version%.0}

METAPORT="KF5-Frameworks"
PORTFILE=`port file ${METAPORT}`
FRAMEWORKS="`grep '^[   ]*subport ' ${PORTFILE} | sed -e 's|subport \(.*\) {|\1|g'`"
MASTERSITE="http://download.kde.org/stable/frameworks/${branch}"
MASTERSITEPA="${MASTERSITE}/portingAids"

echo "# checksums for KF5 Frameworks ${version}"
echo "\narray set checksumtable {"

DISTDIR="${prefix}/var/macports/distfiles/${METAPORT}"
mkdir -p "${DISTDIR}"

for F in ${FRAMEWORKS} ;do
    # remove the "kf5-" prefix
    FW="${F#kf5-}"
    if [ "${FW}" = "ksyntaxhighlighting" ] ;then
        FW="syntax-highlighting"
    fi
    DISTFILE="${DISTDIR}/${FW}-${version}.tar.xz"
    DISTNAME="${MASTERSITE}/${FW}-${version}.tar.xz"
    if [ ! -e "${DISTFILE}" ] ;then
        wget -P "${DISTDIR}" "${DISTNAME}"
        if [ $? != 0 ] ;then
            # could have been a portingAid framework; try here:
            DISTNAME="${MASTERSITEPA}/${FW}-${version}.tar.xz"
            wget -P "${DISTDIR}" "${DISTNAME}"
        fi
    fi
    if [ -r "${DISTFILE}" ] ;then
        echo "\t# ${DISTNAME}"
        echo "\t${F} {"
        echo "\t\t`openssl rmd160 ${DISTFILE} | sed -e 's|.*= ||g'`"
        echo "\t\t`openssl sha256 ${DISTFILE} | sed -e 's|.*= ||g'`"
        echo "\t}"
    fi
done

echo "}"
