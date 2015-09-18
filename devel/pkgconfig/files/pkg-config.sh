#!/bin/sh

if [ "${PKG_CONFIG_MACPORTS_ONLY}" = "" ] ;then
	if [ "${PKG_CONFIG}" = "" ] ;then
		PKG_CONFIG="/usr/bin/pkg-config"
	fi
	if [ "${PKG_CONFIG_PATH}" != "" ] ;then
		PKG_CONFIG_PATH="@PREFIX@/lib/pkgconfig:${PKG_CONFIG_PATH}"
	else
		PKG_CONFIG_PATH="@PREFIX@/lib/pkgconfig"
	fi
	export PKG_CONFIG_PATH
	exec "${PKG_CONFIG}" "$@"
else
	exec pkg-config-mp "$@"
fi
