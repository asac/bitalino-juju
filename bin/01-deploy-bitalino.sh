#!/bin/bash
#####################################################################
#
# Deploy Demo
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
# log debug Validating dependencies

# Switching to project 
switchenv "${PROJECT_ID}" 

#####################################################################
#
# Deploy HBase Environment
# https://jujucharms.com/u/bigdata-dev/apache-hbase/trusty/14
#
#####################################################################

# Deploy HDFS 
deploy apache-hadoop-hdfs-master hdfs-master "mem=7G cpu-cores=2 root-disk=60G"
deploy apache-hadoop-hdfs-secondary secondary-namenode "mem=7G cpu-cores=2 root-disk=60G"

add-relation hdfs-master secondary-namenode
# Deploy YARN 
deploy apache-hadoop-yarn-master yarn-master "mem=7G cpu-cores=2"

# Deploy Compute slaves
deploy apache-hadoop-compute-slave compute-slave "mem=3G cpu-cores=2 root-disk=60G"
add-unit compute-slave 2

# Deploy Hadoop Plugin
deploy apache-hadoop-plugin plugin

# Relations
add-relation yarn-master hdfs-master
add-relation compute-slave yarn-master
add-relation compute-slave hdfs-master
add-relation plugin yarn-master
add-relation plugin hdfs-master

#####################################################################
#
# Deploy Apache Spark 
# https://jujucharms.com/apache-spark/trusty/2
#
#####################################################################

# Deploy Spark
deploy apache-spark spark "mem=3G cpu-cores=2"

# Relations
add-relation spark plugin

# Deploy Zeppelin
deploy apache-zeppelin zeppelin 
# Relations
add-relation spark zeppelin
# Expose
expose zeppelin

#####################################################################
#
# Deploy Apache Kafka
#
#####################################################################

# Now deploying ZK Server
deploy apache-zookeeper zookeeper "mem=2G cpu-cores=2"

# Now deploying Kafka
deploy apache-kafka kafka-broker "mem=2G cpu-cores=2"
# deploy apache-kafka kafka mem=2G cpu-cores=2

# Add relation 
add-relation kafka-broker zookeeper

# Expose
expose kafka-broker

#####################################################################
#
# Deploy Flume pipeline Part 1: flume-kafka
#
#####################################################################

# Wait until Kafka up
until [ "$(get-status kafka-broker)" = "active" ] 
do 
	log debug waiting for Kafka to be up and running
	sleep 30
done

# Get machine id and other settings
KAFKA_MACHINE=$(juju status kafka-broker --format tabular | grep "kafka-broker/0" | awk '{ print $5 }')

until [ "x${ZK_CONFIG}" != "x" ]; do
	ACTION="$(juju action do kafka-broker/0 list-zks | cut -f2 -d':')"
	sleep 3
	ZK_CONFIG="$(juju action fetch ${ACTION} | grep 'zookeepers' | cut -f2- -d':')"
done 

# deploy with colocation on Kafka broker
# deploy-to "cs:~bigdata-dev/trusty/apache-flume-kafka" "flume-kafka" "${KAFKA_MACHINE}"
deploy cs:~bigdata-dev/trusty/apache-flume-kafka flume-kafka

juju set flume-kafka kafka_topic="${BIT_STRING}"
juju set flume-kafka zookeeper_connect="${ZK_CONFIG}"

add-relation kafka-broker flume-kafka
add-relation flume-kafka flume-hdfs

#####################################################################
#
# Deploy Flume pipeline Part 2: flume-hdfs
#
#####################################################################

# Wait until plugin up
until [ "$(get-status spark)" = "active" ] 
do 
	log debug waiting for Apache Spark to be up and running
	sleep 30
done

# Get machine id and other settings
SPARK_MACHINE=$(juju status spark --format tabular | grep "spark/0" | awk '{ print $5 }')

deploy apache-flume-hdfs flume-hdfs
# deploy-to "apache-flume-hdfs" "flume-hdfs" "${SPARK_MACHINE}"

add-relation flume-hdfs plugin

#####################################################################
#
# Recap for user
#
#####################################################################

log debug Finishing installation. Showing results

juju status --format tabular

exit 0
