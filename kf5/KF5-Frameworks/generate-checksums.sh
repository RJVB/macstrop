#!/bin/sh

if [ "${prefix}" = "" ] ;then
    prefix=/opt/local
fi
export PATH="${prefix}/bin:${PATH}"

version=5.60.0
branch=${version%.0}

METAPORT="KF5-Frameworks"
PORTFILE=`port file ${METAPORT}`
FRAMEWORKS="`grep '^[   ]*subport ' ${PORTFILE} | sed -e 's|subport \(.*\) {|\1|g'`"
# # use the set_kf5_framework command which give us the actual remove filenames but leaves us to guess the portname
# FRAMEWORKS="`sed -e ':a' -e '/^#/d; /\\\\$/N; s|\\\\\n||g; ta' < ${PORTFILE} \
#     | fgrep 'set_kf5_framework' \
#     | fgrep -v 'proc set_kf5_framework' \
#     | sed -e 's|set_kf5_framework[ \t][ \t]*\(.*\)|\1|g'`"
# echo "Framework list: ${FRAMEWORKS}" 1>&2
MASTERSITE="https://download.kde.org/stable/frameworks/${branch}"
MASTERSITEPA="${MASTERSITE}/portingAids"

echo "# checksums for KF5 Frameworks ${version}" 
echo "\narray set checksumtable {"

DISTDIR="${prefix}/var/macports/distfiles/${METAPORT}"
mkdir -p "${DISTDIR}"

for F in ${FRAMEWORKS} ;do
    # remove the "kf5-" prefix (which shouldn't be there anymore)
    FW="${F#kf5-}"
    case ${FW} in
        ksyntaxhighlighting)
            FW="syntax-highlighting"
            ;;
        bluezqt)
            FW="bluez-qt"
            ;;
        networkmanagerqt)
            FW="networkmanager-qt"
            ;;
    esac
    DISTFILE="${DISTDIR}/${FW}-${version}.tar.xz"
    DISTNAME="${MASTERSITE}/${FW}-${version}.tar.xz"
#     echo "${F} -> ${DISTNAME} -> ${DISTFILE}" 1>&2
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
