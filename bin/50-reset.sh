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

# Reset Environment
juju-deployer -T "${PROJECT_ID}" 2>/dev/null \
  && log debug Successfully reset "${PROJECT_ID}" \
  || log err Could not reset "${PROJECT_ID}"

juju deploy --to 0 juju-gui 2>/dev/null \
  && log debug Successfully deployed juju-gui to machine-0 \
  || log info juju-gui already deployed or failed to deploy juju-gui

juju expose juju-gui 2>/dev/null \
  && {
		export JUJU_GUI="$(juju api-endpoints | cut -f2 -d' ' | cut -f1 -d':')"
		export JUJU_PASS="$(grep "password" "/home/${USER}/.juju/environments/${PROJECT_ID}.jenv" | cut -f2 -d' ')"
		log info Juju GUI now available on https://${JUJU_GUI} with user admin:${JUJU_PASS}
  } \
  || log info juju-gui already deployed or failed to deploy juju-gui

