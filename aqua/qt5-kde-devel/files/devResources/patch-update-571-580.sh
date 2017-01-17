#!/bin/bash

# This script expects to be executed in a directory containing at least
# qtbase qtconnectivity qttools
# all part of a local git repo that's uptodate and at the HEAD of a personal
# topic branch corresponding to stock/upstream

PDIR=/opt/local/site-ports/aqua/qt5-kde-devel/files

# we skip fix-qstandardpaths-headerspri.patch because the qtbase git repo doesn't have headers.pri
PATCHES="patch-machtest.diff		\
    patch-tst_benchlibcallgrind.diff		\
    patch-shared.diff		\
    patch-no-icons-in-menus.diff		\
    patch-configure-find-opengl-and-correct-rpath.diff		\
    fix-qstandardpaths6.patch		\
    fix-qstandardpaths-linux.patch		\
    patch-lookup-css-monospace-font.diff		\
    patch-qtdiag-all-locations-and-qspmode.diff		\
    patch-qtpaths-all-locations.diff		\
    patch-qtpaths-qspmode.diff		\
    patch-missing-autoreleasepools.diff		\
    patch-enable-qgenericunixthemes.diff		\
    patch-enable-qgenericunixservices.diff		\
    patch-enable-fontconfig.diff		\
    patch-nonull-setAsDockMenu.diff		\
    patch-qkqueuefilesystemwatcher_addPaths.diff		\
    patch-dont-unload-plugins.diff		\
    always_include_private_headers.diff		\
    patch-better-menuitem-insert-warning.diff		\
    dont-warn-missing-fallback-fonts.patch		\
    remove_icon_from_example.patch		\
    remove_google_adsense.patch		\
    load_testability_from_env_var.patch		\
    disable-generic-plugin-when-others-available.patch		\
    patch-qFatal-no-abort.diff		\
    patch-qmenuAddSection.diff		\
    patch-improve-fontweight-support9.diff		\
    patch-fontpanel.diff		\
    patch-cocoatheme-icontheme-support.diff		\
    patch-respect-DontSwapCtrlMeta.diff		\
    patch-fix-build-when-system-freetype-is-detected.diff		\
    patch-freetype-gamma-cocoa.diff		\
    patch-silence-qnsview-warnings.diff		\
    patch-silence-qpixmap-warnings.diff		\
    patch-silence-setscreen-warning.diff		\
    patch-restore-pc-files.diff		\
    patch-fix-dbus-crash-at-exit.diff		\
    patch-qtconn-for-10.12.diff		\
    patch-qttools-skip-assistant.diff		\
    patch-designer-show-menubar-on-xcb.diff		\
    patch-sdk.prf-xcrun-not-for-compilers.diff		\
    patch-enable-dumpObjectInfo.diff		\
    deactivate-menurole-heuristics.patch		\
    debug-negative-qtimerint.patch		\
    patch-cmake-warn-compile_features.diff      \
    patch-to-build-xcb.diff     \
    patch-xcb-XOpenGL-full.diff     \
    patch-toolchainprf.diff     \
    patch-configurejsons.diff       \
    patch-reintroduce-configsummary.diff"

DONEPATCHES=""

# http://stackoverflow.com/questions/8063228/how-do-i-check-if-a-variable-exists-in-a-list-in-bash
function contains {
    if [[ "$1" =~ (^|[[:space:]])"$2"($|[[:space:]]) ]] ;then
        #echo "$2: contained" 1>&2
        ret=1
    else
        #echo "$2: excluded" 1>&2
        ret=0
    fi
    return $ret
}

for F in $PATCHES ;do
     # nb: don't put `contains` inside []!
#     if `contains "${DONEPATCHES}" "${F}"` ;then
    if [ ! -e ".pc/${F}" ] ;then
        if [ -f ${PDIR}/qt580/${F} ] ;then
            PF=${PDIR}/qt580/${F} 
        elif [ -f ${PDIR}/qt571/${F} ] ;then
            PF=${PDIR}/qt571/${F} 
        elif [ -f ${PDIR}/${F} ] ;then
            PF=${PDIR}/${F}
        else
            echo "Patchfile \"${F}\" doesn't exist in \"${PDIR}\""
            exit 1
        fi
        patch -Np1 -i ${PF}
        if [ $? != 0 ] ;then
            echo "Done: ${DONEPATCHES}"
            echo "FAILED: ${PF}"
            exit 1
        fi
        DONEPATCHES="${DONEPATCHES} ${F}"
        git add qtbase qtconnectivity qttools
        git-diff > .pc/${F}
        git commit -m "${PF}" qtbase qtconnectivity qttools
        xxdiff -D .pc/${F} ${PF}
    fi
done
