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

# Run a Kafka Producer Locally sending fake data
log debug Creating Topic "${BIT_STRING}"
ACTION="$(juju action do kafka-broker/0 create-topic topic=${BIT_STRING} partitions=3 replication=1 | cut -f2 -d':')"
sleep 2
juju action fetch ${ACTION}

# Testing
log debug "Writing test to Kafka"
ACTION="$(juju action do kafka-broker/0 write-topic topic=${BIT_STRING} data='\x00\x01' | cut -f2 -d':')"
sleep 2
juju action fetch ${ACTION}

log debug Reading from Hadoop
SPARK_MACHINE=$(juju status spark --format tabular | grep "spark/0" | awk '{ print $5 }')
juju run --machine "${SPARK_MACHINE}" "hadoop fs -ls -R /user/flume"


