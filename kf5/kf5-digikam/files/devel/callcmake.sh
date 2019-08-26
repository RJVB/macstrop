#!/bin/sh

export HOME=/Volumes/VMs/MPbuild/1868242797/kf5/kf5-digikam/work/.home
export COLUMNS=132
export LANG=en_US.UTF-8
export CCACHE_DIR=/opt/local/var/macports/build/.ccache
export GROUP=bertin
export NO_PROXY=localhost,192.1.1.1,*facebook.com,*.icloud.com,*.belastingdienst.nl
export DISPLAY=:0
export TMPDIR=/Volumes/VMs/MPbuild/1868242797/kf5/kf5-digikam/work/.tmp
export http_proxy=http://127.0.0.1:8001
export LINES=84
export HTTPS_PROXY=http://127.0.0.1:8001
export DYLD_INSERT_LIBRARIES=/opt/local/lib/libc++.1.dylib
export MACPORTS_COMPRESS_WORKDIR=1
export PATH=/opt/local/bin:/opt/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export USER=bertin
export PATH=/opt/local/libexec/qt5/bin:/opt/local/bin:/opt/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export MYSQLD_PATH=/opt/local/lib/mariadb/bin
export MYSQL_TOOLS_PATH=/opt/local/lib/mariadb/bin
export AR=/opt/local/bin/llvm-ar-mp-5.0
export NM=/opt/local/bin/llvm-nm-mp-5.0
export RANLIB=/bin/echo
export CPP="/usr/bin/cpp"
export CC="/opt/local/bin/clang-mp-5.0"
export CXX="/opt/local/bin/clang++-mp-5.0"
export CFLAGS="-O3 -march=native -g -DNDEBUG -isystem/opt/local/include -DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_ALT_DEFAULT=true"
export CXXFLAGS="-O3 -march=native -g -DNDEBUG -isystem/opt/local/include -DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_ALT_DEFAULT=true -stdlib=libc++"
export OBJCFLAGS="-O3 -march=native -g -isystem/opt/local/include -DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_ALT_DEFAULT=true"
export OBJCXXFLAGS="-O3 -march=native -g -DNDEBUG -isystem/opt/local/include -isystem/opt/local/include -DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_ALT_DEFAULT=true -stdlib=libc++"
export LDFLAGS="-Wl,-headerpad_max_install_names"

cd `dirname $0`
HERE="${PWD}"

if [ "${1}" = "-E" ] ;then
    case $2 in
        server|capabilities)
            if [ "$2" = "server" ] ;then
                # emulate the error message from an older CMake version
                (   echo "CMake Error: cmake version 3.0.1 (faked to avoid server mode)"
                    echo "Usage: ${PREFIX}/bin/cmake -E [command] [arguments ...]"
                ) 1>&2
                exit 1
            fi
            exec /opt/local/bin/cmake "$@"
            ;;
        *)
			/opt/local/bin/cmake  "$@" -G "CodeBlocks - Unix Makefiles" -DCMAKE_BUILD_TYPE=MacPorts -DCMAKE_INSTALL_PREFIX="/opt/local" -DCMAKE_INSTALL_NAME_DIR="/opt/local/lib" -DCMAKE_SYSTEM_PREFIX_PATH="/opt/local;/usr" -DCMAKE_C_COMPILER_LAUNCHER=/opt/local/bin/ccache -DCMAKE_CXX_COMPILER_LAUNCHER=/opt/local/bin/ccache -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DCMAKE_POLICY_DEFAULT_CMP0025=NEW -DCMAKE_POLICY_DEFAULT_CMP0060=NEW -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_COLOR_MAKEFILE=ON -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_MODULE_PATH="/opt/local/share/cmake/Modules" -DCMAKE_PREFIX_PATH="/opt/local/share/cmake/Modules" -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON -DCMAKE_INSTALL_RPATH="/opt/local/lib" -Wno-dev -DAPPLE_FORCE_UNIX_DIRS=ON -DAPPLE_SUPPRESS_INSTALLDIRS_WARNING=OFF -DPLUGIN_INSTALL_DIR=/opt/local/share/qt5/plugins -DKDE_INSTALL_QTPLUGINDIR=/opt/local/share/qt5/plugins -DQML_INSTALL_DIR=/opt/local/share/qt5/qml -DKDE_INSTALL_MANDIR=/opt/local/share/man -DBUILD_SHARED_LIBS=ON -DCMAKE_STRIP:FILEPATH=/bin/echo -DBUNDLE_INSTALL_DIR=/Applications/MacPorts/KF5 -DAPPLE_SUPPRESS_X11_WARNING=ON -DCMAKE_INSTALL_LIBEXECDIR=/opt/local/libexec -DKDE_INSTALL_LIBEXECDIR=/opt/local/libexec/kde5 -DCMAKE_MACOSX_RPATH=ON -DSYSCONF_INSTALL_DIR="/opt/local/etc" -DPYTHON_EXECUTABLE=/opt/local/bin/python2.7 -DENABLE_APPSTYLES=ON -DENABLE_KFILEMETADATASUPPORT=ON -DENABLE_OPENCV3=ON -DENABLE_MEDIAPLAYER=OFF -DCMAKE_DISABLE_FIND_PACKAGE_QtAV=ON -DENABLE_DBUS=ON -DDIGIKAMSC_COMPILE_DOC=on -DENABLE_INTERNALMYSQL=on -DENABLE_MYSQLSUPPORT=on -DCMAKE_AR="/opt/local/bin/llvm-ar-mp-5.0" -DCMAKE_NM="/opt/local/bin/llvm-nm-mp-5.0" -DCMAKE_RANLIB="/bin/echo" -DCMAKE_MKSPEC=macx-clang -DCMAKE_OSX_ARCHITECTURES="x86_64" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.9" -DCMAKE_OSX_SYSROOT="/" ..
			;;
	esac
else
	/opt/local/bin/cmake  -G "CodeBlocks - Unix Makefiles" -DCMAKE_BUILD_TYPE=MacPorts -DCMAKE_INSTALL_PREFIX="/opt/local" -DCMAKE_INSTALL_NAME_DIR="/opt/local/lib" -DCMAKE_SYSTEM_PREFIX_PATH="/opt/local;/usr" -DCMAKE_C_COMPILER_LAUNCHER=/opt/local/bin/ccache -DCMAKE_CXX_COMPILER_LAUNCHER=/opt/local/bin/ccache -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DCMAKE_POLICY_DEFAULT_CMP0025=NEW -DCMAKE_POLICY_DEFAULT_CMP0060=NEW -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_COLOR_MAKEFILE=ON -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_MODULE_PATH="/opt/local/share/cmake/Modules" -DCMAKE_PREFIX_PATH="/opt/local/share/cmake/Modules" -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON -DCMAKE_INSTALL_RPATH="/opt/local/lib" -Wno-dev -DAPPLE_FORCE_UNIX_DIRS=ON -DAPPLE_SUPPRESS_INSTALLDIRS_WARNING=OFF -DPLUGIN_INSTALL_DIR=/opt/local/share/qt5/plugins -DKDE_INSTALL_QTPLUGINDIR=/opt/local/share/qt5/plugins -DQML_INSTALL_DIR=/opt/local/share/qt5/qml -DKDE_INSTALL_MANDIR=/opt/local/share/man -DBUILD_SHARED_LIBS=ON -DCMAKE_STRIP:FILEPATH=/bin/echo -DBUNDLE_INSTALL_DIR=/Applications/MacPorts/KF5 -DAPPLE_SUPPRESS_X11_WARNING=ON -DCMAKE_INSTALL_LIBEXECDIR=/opt/local/libexec -DKDE_INSTALL_LIBEXECDIR=/opt/local/libexec/kde5 -DCMAKE_MACOSX_RPATH=ON -DSYSCONF_INSTALL_DIR="/opt/local/etc" -DPYTHON_EXECUTABLE=/opt/local/bin/python2.7 -DENABLE_APPSTYLES=ON -DENABLE_KFILEMETADATASUPPORT=ON -DENABLE_OPENCV3=ON -DENABLE_MEDIAPLAYER=OFF -DCMAKE_DISABLE_FIND_PACKAGE_QtAV=ON -DENABLE_DBUS=ON -DDIGIKAMSC_COMPILE_DOC=on -DENABLE_INTERNALMYSQL=on -DENABLE_MYSQLSUPPORT=on -DCMAKE_AR="/opt/local/bin/llvm-ar-mp-5.0" -DCMAKE_NM="/opt/local/bin/llvm-nm-mp-5.0" -DCMAKE_RANLIB="/bin/echo" -DCMAKE_MKSPEC=macx-clang -DCMAKE_OSX_ARCHITECTURES="x86_64" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.9" -DCMAKE_OSX_SYSROOT="/" ..
fi

cd ..
if [ ! -e /tmp/dk-620 ] ;then
	ln -s $PWD /tmp/dk-620
fi

set -x
/usr/local/bin/reinplace.tcl 's|/Volumes/VMs/MPbuild/1868242797/kf5/kf5-digikam/work/digikam-6.2.0|/tmp/dk-620|g' ${HERE}/compile_commands.json
/usr/local/bin/reinplace.tcl 's|/Volumes/Debian/MP9|/opt/local|g' ${HERE}/compile_commands.json
