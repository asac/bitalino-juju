#!/bin/bash
#####################################################################
#
# Initialize Demo environment
#
# Notes: 
# 
# Maintainer: Samuel Cozannet <samuel.cozannet@canonical.com> 
#
#####################################################################

# Validating I am running on debian-like OS
[ -f /etc/debian_version ] || {
	echo "We are not running on a Debian-like system. Exiting..."
	exit 0
}

# Load Configuration
MYNAME="$(readlink -f "$0")"
MYDIR="$(dirname "${MYNAME}")"
MYCONF="${MYDIR}/../etc/demo.conf"
MYLIB="${MYDIR}/../lib/bashlib.sh"
JUJULIB="${MYDIR}/../lib/jujulib.sh"

for file in "${MYCONF}" "${MYLIB}" "${JUJULIB}"; do
	[ -f ${file} ] && source ${file} || { 
		echo "Could not find required files. Exiting..."
		exit 0
	}
done 

if [ $(is_sudoer) -eq 0 ]; then
	die "You must be root or sudo to run this script"
fi

# Check install of all dependencies

# Switching env
switchenv "${PROJECT_ID}"

juju destroy-environment --yes --force "${PROJECT_ID}" 2>/dev/null && log debug Successfully destroyed "${PROJECT_ID}" || log err Could not destroy "${PROJECT_ID}"

# Cleanup demo files
rm -rf ${MYDIR}/../tmp/*