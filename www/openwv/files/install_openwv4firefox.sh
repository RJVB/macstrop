#!/bin/bash

if [ $# != 1 ] ;then
	echo "Usage: `basename $0` <profiledirectory>" 1>&2
	exit 1
fi

if [ ! -d "$1" -o ! -e "$1/search.json.mozlz4" ] ;then
	echo "Error: \"$1\" is not a Firefox profile directory" 1>&2
	exit 1
fi

echo "Checking the profile directory..."
lsof "$1/.parentlock" > /dev/null
if [ $? == 0 ] ;then
	echo "The selected profile appears to be open in a running browser!" 1>&2
	exit 1
fi

realpath () {
	(cd "$1"; pwd;)
}

SRCDIR="$(realpath "$(dirname "$(dirname "$0")")")"

cd "$1"
DSTDIR="gmp-widevinecdm/@VERSTRING@"

echo "Now in profile directory \"`pwd`\"; destination dir is \"${DSTDIR}\""

mkdir -p "${DSTDIR}"

# the easy part:
cp -pv "${SRCDIR}"/libwidevinecdm.* "${DSTDIR}/"
cp -pv "${SRCDIR}"/firefox/manifest.json "${DSTDIR}/"

# the "fun" part:
PREFSBACKUP="prefs.js.openwv_installed_backup"
echo "Backing up the preferences store (prefs.js)"
cp -p prefs.js "${PREFSBACKUP}"

echo "Registering the newly installed OpenWV v@VERSION@"
set -x
gsed \
	-e '/user_pref("media.gmp-widevinecdm.autoupdate",.*/d' \
	-e '/user_pref("media.gmp-widevinecdm.version",.*/d' \
	-e '$auser_pref("media.gmp-widevinecdm.autoupdate", false);' \
	-e '$auser_pref("media.gmp-widevinecdm.version", "@VERSTRING@");' \
	< "${PREFSBACKUP}" > prefs.js

set +x

echo
echo "All done!"
echo "A backup of the previous preferences store was left as \"$1/${PREFSBACKUP}\""
