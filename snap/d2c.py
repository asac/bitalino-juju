#!/usr/bin/env python2.7

import sys
sys.path.append('.')

import bitalino
from kafka import KafkaProducer
import json
import time
import yaml
import os
import shutil

KAFKA_HOST="localhost"
KAFKA_PORT="8080"
BITALINO_TOPIC="bitalino-snappy"
BITALINO_MAC_ADDRESS="00:00:00:00:00:"

config_yaml=None

# if we are run in snap environment, get config from yaml
if os.environ['SNAP_APP_DATA_PATH'] is not None:
	config_path = os.path.join(os.environ['SNAP_APP_DATA_PATH'], "bitalino.yaml")
	default_path = os.path.join(os.environ['SNAP'], "bitalino.yaml.default")
	if not os.path.exists(config_path):
		shutil.copy(default_path, config_path)
	with open(config_path, 'r') as stream:
		config_yaml = yaml.load(stream)["config"]
	bitalino_yaml = config_yaml['bitalino']

if bitalino_yaml is not None:
	if 'kafka-host' in bitalino_yaml:
		KAFKA_HOST = bitalino_yaml['kafka-host']
	if 'kafka-port' in bitalino_yaml:
		KAFKA_PORT = bitalino_yaml['kafka-port']
	if 'topic' in bitalino_yaml:
		BITALINO_TOPIC = bitalino_yaml['topic']
	if 'mac-address' in bitalino_yaml:
		BITALINO_MAC_ADDRESS = bitalino_yaml['mac-address']

device = bitalino.BITalino()
producer = KafkaProducer(bootstrap_servers=KAFKA_HOST +':'+ str(KAFKA_PORT),
    api_version="0.9",
    acks=1,
    value_serializer=json.dumps
    )

print "KAFKA_HOST" + KAFKA_HOST
print "KAFKA_PORT" + str(KAFKA_PORT)
print "BITALINO_TOPIC" + BITALINO_TOPIC
print "BITALINO_MAC_ADDRESS " + BITALINO_MAC_ADDRESS

topic = BITALINO_TOPIC
macAddress = BITALINO_MAC_ADDRESS
# We collect data every 10ms
SamplingRate = 100

# Initializing device
device.open(macAddress, SamplingRate)
# We won't stop until we have less than 5% of battery
th = device.battery(5)

# Infinite data collection loop
while True:
    try:
        # We collect all channels
        device.start([0,1,2,3,4,5])
        # We collect 1sec of data
        dataAcquired = device.read(100)
        message = dataAcquired.T.tolist()
        producer.send(topic,message)
    except KeyboardInterrupt as ke:
        break
    except Exception as e:
        print e
        time.sleep(1000)

device.stop()
device.close()

