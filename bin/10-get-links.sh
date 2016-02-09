#!/bin/bash
#####################################################################
#
# Configure Demo
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

# Switching to project 
switchenv "${PROJECT_ID}" 

# Collecting info for Zeppelin
EXT_IP_ADDR="$(juju status zeppelin --format tabular | grep "zeppelin/0" | awk '{ print $6 }')"
EXT_PORT=9090

log info Point your browser at http://${EXT_IP_ADDR}:${EXT_PORT}

# Collecting info for Zeppelin
EXT_IP_ADDR="$(juju status kafka-broker --format tabular | grep "kafka-broker/0" | awk '{ print $7 }')"
EXT_PORT=9092

log info Point your devices at Kafka: ${EXT_IP_ADDR}:${EXT_PORT}
