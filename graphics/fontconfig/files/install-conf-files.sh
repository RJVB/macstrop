#!/bin/sh

prefix="${1}"
workpath="$2"
destroot="$3/${prefix}"
release="$4"

set -e
set -x

FCU="${prefix}/share/fonts/fontconfig-ultimate/${release}"

if [ -d ${workpath} -a -d ${destroot} -a -d ${FCU} ] ;then
	cd ${FCU}
	mkdir -p ${destroot}/etc/fonts/conf.avail.infinality
	mkdir -p ${destroot}/etc/fonts/conf.avail
	mkdir -p ${destroot}/bin
	chmod 755 fc-presets
	ln -s ${FCU}/fc-presets ${destroot}/bin/fc-presets
	ln -s ${FCU}/combi ${FCU}/combi-complete ${FCU}/free ${FCU}/ms ${destroot}/etc/fonts/conf.avail.infinality/
	ln -s ${FCU}/fonts-settings/*.conf ${destroot}/etc/fonts/conf.avail/
else
	echo "One or more of ${workpath}, ${destroot} or ${FCU} don't exist"
	exit 1
fi
