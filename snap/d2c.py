import sys
sys.path.append('.')

import bitalino
from kafka import KafkaProducer
import json
import time

device = bitalino.BITalino()
producer = KafkaProducer(bootstrap_servers='KAFKA_HOST:KAFKA_PORT',
    api_version="0.9",
    acks=1,
    value_serializer=json.dumps
    )

topic = 'MY_BITALINO'
macAddress = 'BITALINO_MAC_ADDRESS'
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

