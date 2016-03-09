#!/bin/sh

SCRIPT="${TMPDIR}/RunInTerminal.$$.sh"

CleanUp() {
	rm -f "${SCRIPT}"
}

trap CleanUp 0
trap CleanUp 1
trap CleanUp 2
trap CleanUp 15

if [ $# != 0 ] ;then
	echo "$@" > "${SCRIPT}"
else
	cat - > "${SCRIPT}"
fi
chmod 700 "${SCRIPT}"

echo "Running the requested command(s) in a new Terminal instance"
echo "Remember to quit the Terminal application!"

open -W -n -F -a Terminal.app "${SCRIPT}"
