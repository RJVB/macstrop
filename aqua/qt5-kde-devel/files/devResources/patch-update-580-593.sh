#!/bin/bash

# This script expects to be executed in a directory containing at least
# qtbase qtconnectivity qttools
# all part of a local git repo that's uptodate and at the HEAD of a personal
# topic branch corresponding to stock/upstream

PDIR=/opt/local/site-ports/aqua/qt5-kde-devel/files
HERE="`pwd`"
if [ "$1" != "" -a -d "$1" ] ;then
    cd $1
    echo "working in `pwd` ($1)"
fi

# obsolete:    patch-retain-foreign-nsviews.diff
# obsolete:    patch-silence-setscreen-warning.diff (after silence-qpixmap-warnings.diff)
# obsolete:    patch-keyboard-mapping.diff (after patch-cmake-warn-compile_features.diff)
# obsolete:    patch-define-qtnoexceptions.diff (after patch-firstObject-109)
# obsolete:    patch-qttools-qthelp-warnings.diff (after patch-enable-vnc-qpa.diff)
# obsolete:    patch-no-native-crossbuilds.diff (after patch-handle-null-corefonts.diff)
# obsolete:    patch-install-headeronly-frameworks.diff (after patch-handle-null-corefonts.diff)
# obsolete:    patch-ibus-fix2.diff (after patch-ibus-fix.diff)
# obsolete:    patch-reintroduce-configsummary.diff (after patch-configurejsons.diff)
PATCHES="patch-machtest.diff \
    patch-tst_benchlibcallgrind.diff \
    patch-shared.diff \
    patch-no-icons-in-menus.diff \
    patch-find-opengl.diff \
    fix-qstandardpaths6.patch \
    fix-qstandardpaths-headerspri.patch \
    fix-qstandardpaths-linux.patch \
    patch-lookup-css-monospace-font.diff \
    patch-qtdiag-all-locations-and-qspmode.diff \
    patch-qtpaths-all-locations.diff \
    patch-qtpaths-qspmode.diff \
    patch-missing-autoreleasepools.diff \
    patch-enable-qgenericunixthemes.diff \
    patch-enable-qgenericunixservices.diff \
    patch-enable-fontconfig.diff \
    patch-nonull-setAsDockMenu.diff \
    patch-qkqueuefilesystemwatcher_addPaths.diff \
    always_include_private_headers.diff \
    patch-better-menuitem-insert-warning.diff \
    dont-warn-missing-fallback-fonts.patch \
    load_testability_from_env_var.patch \
    disable-generic-plugin-when-others-available.patch \
    patch-qFatal-no-abort.diff \
    patch-qmenuAddSection.diff \
    patch-improve-fallback-fullscreen-mode.diff \
    patch-improve-fontweight-support9.diff \
    patch-assistant-fontpanel.diff \
    patch-respect-DontSwapCtrlMeta.diff \
    patch-fix-build-when-system-freetype-is-detected.diff \
    patch-freetype-gamma-cocoa.diff \
    patch-silence-qpixmap-warnings.diff \
    patch-restore-pc-files.diff \
    patch-fix-dbus-crash-at-exit.diff \
    patch-qtconn-for-10.12.diff \
    patch-qttools-skip-assistant.diff \
    patch-cmake-warn-compile_features.diff \
    patch-no-pulseaudio+gstreamer.diff \
    patch-readable-selected-tab-109.diff \
    patch-keyboard-support-menukey.diff \
    patch-use-openssl-mp.diff \
    patch-firstObject-109.diff \
    patch-enable-vnc-qpa.diff \
    patch-handle-null-corefonts.diff \
    patch-ibus-fix.diff \
    patch-wdate-time.diff \
    patch-toolchainprf.diff \
    patch-configurejsons.diff \
    patch-designer-show-menubar-on-xcb.diff \
    patch-to-build-xcb.diff \
    patch-xcb-XOpenGL-full.diff \
    patch-sdk.prf-xcrun-not-for-compilers.diff \
    patch-clangconf.diff \
    patch-enable-dumpObjectInfo.diff \
    deactivate-menurole-heuristics.patch \
    debug-negative-qtimerint.patch \
    remove_icon_from_example.patch \
    remove_google_adsense.patch \
    patch-assistant-with-qtwebkit.diff \
    patch-assistant-without-qtwebkit.diff"

# New patches (most copied from port:kf5-osx-integration)
# or related to running on 10.9
PATCHES="${PATCHES} \
    patch-backport-corelib-109.diff \
    patch-fix-qtMacWindow-WIP.diff \
    patch-macstyle-checks-if-cocoa.diff \
    patch-macstyle-build-on-109.diff \
    patch-col+font-dialog-fix.diff \
    patch-qcocoa-build-on-109.diff \
    patch-qcocoa-add-aqua-themehint.diff \
    patch-disable-bearer-109.diff \
    patch-xcb-use-qgenunixfontdb.diff \
    patch-mkspecs.diff \
    patch-no-app_ext-only-109.diff \
    patch-xcb-fontgamma.diff"

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

QT59x=qt593
UPDDIR=${QT59x}

for F in $PATCHES ;do
     # nb: don't put `contains` inside []!
#     if `contains "${DONEPATCHES}" "${F}"` ;then
    if [ ! -e ".pc/${F}" ] ;then
        if [ -f ${PDIR}/${QT59x}/${F} ] ;then
            PF=${PDIR}/${QT59x}/${F} 
        elif [ -f ${PDIR}/qt580/${F} ] ;then
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
            echo "Should become: ${PDIR}/${UPDDIR}/${F}"
            exit 1
        fi
        DONEPATCHES="${DONEPATCHES} ${F}"
        git add qtbase qtconnectivity qttools qtmultimedia
        git-diff > .pc/${F}
        git commit -m "${PF}" qtbase qtconnectivity qttools qtmultimedia
        echo "Comparing old and new patches;"
        echo "Consider doing cp -pv ${PWD}/.pc/${F} ${PDIR}/${UPDDIR}/${F}"
        xxdiff -D .pc/${F} ${PF}
    fi
done
