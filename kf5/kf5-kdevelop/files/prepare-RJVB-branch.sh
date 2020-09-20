#!/bin/sh

### setup and simple function to apply and commit patches from my MacPorts port
if [ "${TMPDIR}" = "" ] ;then
    export TMPDIR=/tmp
fi

LOGNAME="`basename $0`"

patch_and_commit () {
    echo $2 > "${TMPDIR}/${LOGNAME}.out"
    echo >> "${TMPDIR}/${LOGNAME}.out"
    gpatch "$1" -i "$2" 2>&1 >> "${TMPDIR}/${LOGNAME}.out"
    if [ $? = 0 ] ;then
        # add new = not-yet-tracked files:
        UNTRACKED="`git ls-files -o --exclude-standard`"
        if [ "${UNTRACKED}" != "" ] ;then
            echo "New files:" >> "${TMPDIR}/${LOGNAME}.out"
            git add  -v ${UNTRACKED} 2>&1 >> "${TMPDIR}/${LOGNAME}.out"
        fi
        git commit -v -a --file="${TMPDIR}/${LOGNAME}.out"
    else
        RET=$?
        echo "Failed to apply $2:" 1>&2
        cat "${TMPDIR}/${LOGNAME}.out" 1>&2
        rm "${TMPDIR}/${LOGNAME}.out"
        exit $RET
    fi
    rm -f "${TMPDIR}/${LOGNAME}.out"
}

# we handle errors ourselves
set +e

FILESPATH="`port dir kf5-kdevelop-devel`/files"

###
### Below this line: invoke the applicable patches in the correct order.
###

patch_and_commit -Np0 ${FILESPATH}/devel56/patch-decorated-version.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-separate-ide-and-parser.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-verbose-find_meson.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-bg-parser-tweaks.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-outputfilteringstrats.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-projectman-shortcuts-simple.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-grep-improved-exclude-filter.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-check-oosource-build-dir.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-kdevplatform-add-style-menu.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-use-what-dialogs.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-temp-fixes-devel.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-projman-horizscroll.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-x11-no-dockmenu.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-patchreview-active-state.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-problemreport-focus.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-avoid-duchain-hang-on-exit.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-topcontext-crashfix.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-revert-D22424.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-no-ctxmenu-dupes.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-gitdiff-noprefix.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-docview.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-regular-undocked-windows.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-docview-standalone.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-better-projectname-support.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-qtb-help-browser2.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-tearoff-menus.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-kdevelop-tempdir.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-height-dep-combined-tooltips.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-temp-fixes.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-prevent-patchreview-crash.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-cmake-normalise-builddir.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-defer-parsing.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-other3-dirwatching.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-no-krunner.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-rename-kdevexclam.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-open-docs-from-Finder-and-env-profile.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-menu-under-x11.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-cmake-macports-first.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-extended-support4Objc-parser.patch
patch_and_commit -Np0 ${FILESPATH}/55x/patch-signal-handler+rlimit.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-clangproblem.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-prevent-beachballing.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-no-registry-abort.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-announce-legacy-import.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-use-external-qtassistant.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-disable-gdbugger.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-kdevformatsource.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-cleanup-tempfiles.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-build-clang5-linux.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-safer-qmake-plugin.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-completion-popup.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-restore-ctags-plugin.diff
patch_and_commit -Np0 ${FILESPATH}/55x/patch-cache-qcursorpos.diff
patch_and_commit -Np0 ${FILESPATH}/devel56/patch-bgjobbs-controller.diff
patch_and_commit -Np1 ${FILESPATH}/devel56/patch-commit-msg-width.diff
patch_and_commit -Np1 ${FILESPATH}/devel56/patch-diff-context4.diff
patch_and_commit -Np1 ${FILESPATH}/55x/patch-topcontexts.diff
