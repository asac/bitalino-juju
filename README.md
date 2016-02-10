#####################################################################
#
# Demo Name: Solving the Healthcare Innovation Issue
#
#####################################################################

Maintainer: Samuel Cozannet <samuel.cozannet@canonical.com> 

# Purpose of the demo

This demo has 2 goals. 
First it aims at deploying a full ingest pipeline for IoT devices using Kafka
Second, it aims at showing a big data processing pipeline (Lambda Architecture) based on [Spark](https://spark.apache.org/) on YARN, using Spark Streaming for the RT processing and Spark for Batch, and access it through Zeppelin. 

As an example for the IoT side, our context is healthcare, and, more specifically, the use of [Bitalino](http://bitalino.com/) devices. 

# Healthcare: What problem are we trying to solve?
## Healthcare & IoT: revolution & challenges

Since IoT appeared on the technology map, it's been clear that Healthcare would be in the top 3 of the verticals using it. Time has shown that is it true, with a massive thread of innovation, from B2C (quantitative self) to B2B (medical devices). 

However, IoT creates new challenges for an industry used to fewer machines, usually manually installed. The amount of data and the number of devices pose new scale issues that were not envisioned. 

That has a few major consequences, the biggest of which is a growing gap between research and production: 
* Researchers do not have access / do not need a lot of devices individually and can start hacking into the data with just a few of them. Therefore they do not put themselves in the "real" scale context. 
* Big Data is hard. Hadoop, Cassandra, Spark and others are technologies that cannot (and should not) be deployed by non IT people. However, they are required to access the real value of the data collected and leverage the serendipity Big Data allows.

## Canonical: Commoditizing Big Software

One of our mission at Canonical is the enablement of others. We do that by commodizing complex technologies, make sure we can be a driver to innovation.
Ubuntu, the OS for human beings, was only the first iteration. 
Now, in the era of big software, our role is to make sure that any and every one can access complex software, scale it, and use it as close as possible to real conditions.

To us, it means growing a community of passionate IT people, capable of sharing their operational knowledge and express it through "Juju Charms", with the ultimate goal of modelling clever complex applications. 

To the rest of the world, that means reducting the gap between researchers and production. It means every student, every scientist, every human being should (and will) access the tools of the company they might be working for tomorrow. Eventually, it will make humanity evolve better, faster, stronger. 

## Bitalino, Ubuntu & Juju: Winning the innovation lab

A few years ago, [Bitalino](http://bitalino.com/) appeared on our radar. It's a team of passionate scientists, whose desire was to create a board connected to sensors that anyone could use to design healthcare related scientific experiences. 

Over the years, they grew a community of over 4.000 professionals, and an impressive list of APIs and modules to access the board and accessories. 

This board was initially designed for one to one experiments. A scientist would patch someone, do an experiment locally, unpatch, and iterate, which is why the toolset was designed around single machines. 

But now part of the community wants to run long running experiments and scale the number of patients, to identify patterns across a large dataset. 

Looking at this issue, we could see that our Ubuntu and our modeling framework Juju could be leveraged to create an out of the box solution for this. 
We have designed a new way of experimenting, based on a large scale collection of data from the boards, storage in Hadoop, compute with Spark, visualization with Zeppelin and access to Python scientific tools to perform plotting, machine learning and other goodness Big Data provices. 

# Solution Overview
## IoT Side: Bitalino and Raspberry Pi are in a boat

When it comes to experimenting with IoT, the Raspberry Pi cannot be avoided. Our setup is made of 

* Raspberry Pi 2 (model B)
* Bluetooth 4.0 dongle
* Ubuntu 14.04 or Ubuntu Snappy Core 15.04
* [Bitalino Plugged Kit](http://bitalino.com/index.php/plugged-kit)
* Some python code to collect data and ship it to the cloud

## Cloud side: Hadoop, Spark, Kafka and Zeppelin

When anyone a bit tech savvy talks about big data, you'll ear Hadoop, Spark, Kafka and/or Zeppelin in the conversation. These are pillars of Big Software, on which many other things are built. 

* Hadoop was one of the first cheap scalable storage solution that was open sourced
* Kafka is a pub/sub messaging system that scales to billions of messages per second
* Spark is from the second waves, but is now the standard, scalable compute engine for Big Data. It plugs to Hadoop and Kafka natively. 
* Zeppelin is a web notebook that can leverage tens of interpreters to interact with data. 

Problem is they are really hard to set up (at scale) and even harder to combine. That is somehow what we want to fix. 

# Getting things done. Get your code ready! 

First of all, before you start, charge up your Bitalino kit 

## Raspberry Pi

### Snappy Ubuntu Core 16.04
#### Building for x86
On your developer desktop You need to run xenial or be in a xenial chroot to build the snap.

Before you get started install snapcraft from the archive:

```
sudo apt-get install snapcraft
```

Next go into the snap/ directory of this project and run:

```
snapcraft snap
```

This will produce a snap ready for installing on any snappy 16.04 install

#### Building for armhf
On a snappy armhf system, just enable classic-mode, start the classic shell and install snapcraft and git in there.

```
sudo snappy enable-classic
snappy shell classic
apt-get install git snapcraft
```

Afterwards use git to clone the tree and build

```
snapcraft snap
```

Your home in classic is shared with the snappy system, so if you exit the classic shell you can simply run:

```
snappy install bitlano*.snap
```


### Ubuntu 14.04
#### Burning the image

An Ubuntu 14.04 LTS image for the Raspberry Pi 2 is available [here](http://www.finnie.org/software/raspberrypi/2015-04-06-ubuntu-trusty.zip). 

From there, you can burn the image

* From [Windows](https://www.raspberrypi.org/documentation/installation/installing-images/windows.md)
* From [MacOS X](https://www.raspberrypi.org/documentation/installation/installing-images/mac.md)
* From [Linux](https://www.raspberrypi.org/documentation/installation/installing-images/linux.md) 

Use a SD card of more than 8GB for safety (also 4GB should be enough if you really don't have anything else)

#### First boot

This image doesn't come with openssh-server installed so you'll have to do that yourself, with a screen and a proper keyboard. Start the device, and log in with username **ubuntu** and password **ubuntu**

Now run

    sudo apt-get update && sudo apt-get upgrade -yqq
    sudo apt-get install -yqq openssh-server

Once that is done, you can access your device from the network, and you won't need your local display and keyboard anymore as we'll use our device as a headless system. 

Then we'll want to expand the root partition to all the space available on our card (by default it's using only 4GB)

    sudo fdisk /dev/mmcblk0

You’ll then be presented with a ‘Command’ prompt, press the following keystrokes in order to delete the second partition:

    d
    2

Now you need to re-create it but using all the space. Press the following keystrokes at the ‘Command’ prompt

    n
    p
    2
    [enter]
    [enter]

Now exit by typing ```w```

Reboot with ```sudo reboot now```, and, on the second boot after logging in type 

    sudo resize2fs /dev/mmcblk0p2


#### Installing other software

Make sure your Bluetooth Dongle is plugged, ssh into your machine (or keep using your display / keyboard ) and run: 

    sudo apt-get install -yqq --force-yes \
        ntp \
        nano \
        wget \
        curl \
        git \
        htop \
        screen \
        tshark \
        python-virtualenv \
        python-pip \
        python-setuptools \
        nmap \
        software-properties-common \
        apt-transport-https \
        zram-config \
        avahi-daemon \
        libnss-mdns

Now we'll install the latest bluetooth stack

    sudo add-apt-repository -y ppa:vidplace7/bluez5
    sudo apt-get update
    sudo apt-get install -yqq bluetooth \
        bluez \
        bluez-utils \
        libbluetooth-dev

Now we need some python libraries as well

    sudo apt-get install -yqq --force-yes \
        libsnappy-dev \
        python-numpy \
        python-gobject \
        python-dbus \
        python-serial \
        python-bluez \
        python-requests
    sudo pip install --upgrade python-snappy
    sudo pip install --upgrade lz4tools
    sudo pip install --upgrade xxhash

#### Install the modified Bitalino Python API

The default bitalino API doesn't manage time, but rather an index on 2 bytes that is used as a test that all successive data requests have been processed. 

We added a feature to make sure that timestamps are added in the results to manage timeseries in an easy way. 
Note that bluetooth 2.0 is limited in management of time, so we added a delay of 75ms as the average latency for that communication channel. 

    git clone https://github.com/SaMnCo/bitalino-python/
    cd bitalino-python && sudo python setup.py install

#### Install the latest kafka-python library

    git clone https://github.com/dpkp/kafka-python
    cd kafka-python && sudo python setup.py install

#### Edit the code skeleton

Using your favorite code editor, create a new file ```get-bitalino-kafka.py```

    nano get-bitalino-kafka.py

And copy the content below

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

What this does is pretty simple. It will connect to the bluetooth device, collect data every 10ms, aggregate 100 hits (1 sec) and ship to the cloud. If the message doesn't pass, we ask Kafka to block it and retry to make sure we collect all messages. 

#### Configure your bitalino & code

After all this, you should have enough juice in the bitalino to start it up and collect data about it. 

Start the bitalino, and, on the Raspberry Pi type: 

    sudo bluetoothctl -a

Then follow the below sequence 

    [NEW] Controller 00:1A:7D:DA:71:13 matchbox-0 [default]
    Agent registered
    [bluetooth]# power on
    Changing power on succeeded
    [bluetooth]# scan on
    Discovery started
    [CHG] Controller 00:1A:7D:DA:71:13 Discovering: yes
    [NEW] Device 14:99:E2:12:B1:1E 14-99-E2-12-B1-1E
    [CHG] Device 14:99:E2:12:B1:1E RSSI: -77
    [NEW] Device 88:0F:10:76:EB:7E MI
    [CHG] Device 14:99:E2:12:B1:1E RSSI: -85
    [CHG] Device 14:99:E2:12:B1:1E RSSI: -76
    [NEW] Device 20:15:10:26:63:81 bitalino
    [bluetooth]# scan off
    [CHG] Device 20:15:10:26:63:81 RSSI is nil
    [CHG] Device 88:0F:10:76:EB:7E RSSI is nil
    [CHG] Device 14:99:E2:12:B1:1E RSSI is nil
    [CHG] Controller 00:1A:7D:DA:71:13 Discovering: no
    Discovery stopped
    [bluetooth]# pair 20:15:10:26:63:81
    Attempting to pair with 20:15:10:26:63:81
    [CHG] Device 20:15:10:26:63:81 Connected: yes
    Request PIN code
    [agent] Enter PIN code: 1234
    [CHG] Device 20:15:10:26:63:81 UUIDs: 00001101-0000-1000-8000-00805f9b34fb
    [CHG] Device 20:15:10:26:63:81 Paired: yes
    Pairing successful
    [CHG] Device 20:15:10:26:63:81 Connected: no
    [bluetooth]# trust 20:15:10:26:63:81
    [CHG] Device 20:15:10:26:63:81 Trusted: yes
    Changing 20:15:10:26:63:81 trust succeeded
    [bluetooth]# exit
    Agent unregistered
    [DEL] Controller 00:1A:7D:DA:71:13 matchbox-0 [default]

What did we do? 

First, we started the bluetooth device, in case it was not already (```power on```)

Then, we activated the scan of the environment (```scan on```)

That gave us a a list of the devices around, and we identified the bitalino device (**   [NEW] Device 20:15:10:26:63:81 bitalino**)

Then we paired the device (```pair 20:15:10:26:63:81```) which required the default password 1234

Finally, as we want to connect automatically to it without having to use a password anymore, we added the device to the trusted list (```trust 20:15:10:26:63:81```)

Now you need to update the get-bitalino-kafka.py script and modify topic and macAddress to match (use the MAC Address you got of course): 

    topic = 'bit-20-15-10-26-63-81'
    macAddress = '20:15:10:26:63:81'

OK!! We're all set on the device side. Now let's move to the cloud. 

# Deploying Kafka, Hadoop, Spark in minutes

## [Hadoop](https://hadoop.apache.org/) Cluster

In this example the [Hadoop](https://hadoop.apache.org/) Cluster is production ready. It has 2 HDFS namenodes (master & secondary), 3 compute slaves and a YARN Master. 

It can scale out by adding more compute-slave units.

## [Spark](https://spark.apache.org/) 

[Spark](https://spark.apache.org/) is deployed and connected to YARN to scale to all HDFS nodes. 

## GUIs
### [Zeppelin](https://zeppelin.incubator.apache.org/)

[Zeppelin](https://zeppelin.incubator.apache.org/) (from NFLabs) is deployed on the [Spark](https://spark.apache.org/) unit, and provides an interface to publish [Spark](https://spark.apache.org/) Apps into [Spark](https://spark.apache.org/) in real time. 

# Usage

This assumes you have Juju up & running on your machine, and access to a public cloud. 

## Configuration

Edit ./etc/demo.conf to change: 

* PROJECT_ID : This is the name of your environment
* FACILITY (default to local0): Log facility to use for logging demo activity
* LOGTAG (default to demo): A tag to add to log lines to ease recognition of demos
* MIN_LOG_LEVEL (default to debug): change verbosity. Only logs above this in ./etc/syslog-levels will show up
* BIT_STRING="MY_BITALINO": change that to the topic name with your MAC address (bit-20-15-10-26-63-81)

## Bootstrapping 

	./bin/00-bootstrap.sh

Will set up the environment 

## Deploying  

	./bin/01-deploy-bitalino.sh

Will deploy the charms required for the demo.

## Additional Scripts & Configuration

All the scripts starting in "1X-XXXXXXX.sh" are demo scripts you can run

###  Access to GUIs and interfaces

	./bin/10-get-links.sh

This will give you the Zeppelin access, as well as the Kafka endpoint. 

    $ ./bin/10-get-links.sh 
    [mar feb 9 09:53:56 CET 2016] [demo] [local0.debug] : Successfully switched to my_environment
    [mar feb 9 09:53:56 CET 2016] [demo] [local0.info] : Point your browser at http://1.2.3.4:9090
    [mar feb 9 09:53:57 CET 2016] [demo] [local0.info] : Point your devices at Kafka: 5.6.7.8:9092

On your Raspberry Pi, edit get-bitalino-kafka.py to update the below line with the Kafka information: 

    producer = KafkaProducer(bootstrap_servers='5.6.7.8:9092',

### Configure Kafka & Flume

    ./bin/11-config-kafka.sh

This will configure the Flume Kafka charm to connect on the right topic to send to HDFS. 

## Resetting 

	./bin/50-reset.sh

Will reset the environment but keep it alive

## Clean

	./bin/99-cleanup.sh

Will completely rip of the environment and delete local files

# Sample Outputs
## Bootstrapping

    :~$ ./bin/00-bootstrap.sh 
    [Wed Sep 2 17:52:36 CEST 2015] [demo] [local0.debug] : Validating dependencies
    [Wed Sep 2 17:52:37 CEST 2015] [demo] [local0.debug] : Successfully switched to canonical
    [Wed Sep 2 17:56:53 CEST 2015] [demo] [local0.debug] : Succesfully bootstrapped canonical
    [Wed Sep 2 17:57:04 CEST 2015] [demo] [local0.debug] : Successfully deployed juju-gui to machine-0
    [Wed Sep 2 17:57:06 CEST 2015] [demo] [local0.info] : Juju GUI now available on https://52.18.73.57 with user admin:869ab5e5049321d54a8fca0f27d6cdf0
    [Wed Sep 2 17:57:18 CEST 2015] [demo] [local0.debug] : Bootstrapping process finished for canonical. You can safely move to deployment.

## Deployment

    :~$ ./bin/01-deploy-bitalino.sh 
    [Wed Sep 2 18:00:04 CEST 2015] [demo] [local0.debug] : Successfully switched to canonical
    [Wed Sep 2 18:00:16 CEST 2015] [demo] [local0.debug] : Successfully deployed hdfs-master
    [Wed Sep 2 18:00:19 CEST 2015] [demo] [local0.debug] : Successfully set constraints "mem=7G cpu-cores=2 root-disk=32G" for hdfs-master
    [Wed Sep 2 18:00:33 CEST 2015] [demo] [local0.debug] : Successfully deployed secondary-namenode
    [Wed Sep 2 18:00:36 CEST 2015] [demo] [local0.debug] : Successfully set constraints "mem=7G cpu-cores=2 root-disk=32G" for secondary-namenode
    [Wed Sep 2 18:00:37 CEST 2015] [demo] [local0.debug] : Successfully created relation between hdfs-master and secondary-namenode
    [Wed Sep 2 18:00:50 CEST 2015] [demo] [local0.debug] : Successfully deployed yarn-master
    [Wed Sep 2 18:00:53 CEST 2015] [demo] [local0.debug] : Successfully set constraints "mem=7G cpu-cores=2" for yarn-master
    [Wed Sep 2 18:01:07 CEST 2015] [demo] [local0.debug] : Successfully deployed compute-slave
    [Wed Sep 2 18:01:10 CEST 2015] [demo] [local0.debug] : Successfully set constraints "mem=3G cpu-cores=2 root-disk=32G" for compute-slave
    [Wed Sep 2 18:01:24 CEST 2015] [demo] [local0.debug] : Successfully added 2 units of compute-slave
    [Wed Sep 2 18:01:29 CEST 2015] [demo] [local0.debug] : Successfully deployed plugin
    [Wed Sep 2 18:01:30 CEST 2015] [demo] [local0.debug] : Successfully created relation between yarn-master and hdfs-master
    [Wed Sep 2 18:01:32 CEST 2015] [demo] [local0.debug] : Successfully created relation between compute-slave and yarn-master
    [Wed Sep 2 18:01:33 CEST 2015] [demo] [local0.debug] : Successfully created relation between compute-slave and hdfs-master
    [Wed Sep 2 18:01:36 CEST 2015] [demo] [local0.debug] : Successfully created relation between plugin and yarn-master
    [Wed Sep 2 18:01:37 CEST 2015] [demo] [local0.debug] : Successfully created relation between plugin and hdfs-master
    [Wed Sep 2 18:01:48 CEST 2015] [demo] [local0.debug] : Successfully deployed [Spark](https://spark.apache.org/)
    [Wed Sep 2 18:01:51 CEST 2015] [demo] [local0.debug] : Successfully set constraints "mem=3G cpu-cores=2" for [Spark](https://spark.apache.org/)
    [Wed Sep 2 18:01:52 CEST 2015] [demo] [local0.debug] : Successfully created relation between [Spark](https://spark.apache.org/) and plugin
    [Wed Sep 2 18:01:57 CEST 2015] [demo] [local0.debug] : Successfully deployed [Zeppelin](https://zeppelin.incubator.apache.org/)
    [Wed Sep 2 18:01:58 CEST 2015] [demo] [local0.debug] : Successfully created relation between between [Spark](https://spark.apache.org/) and [Zeppelin](https://zeppelin.incubator.apache.org/)
    [Wed Sep 2 18:01:59 CEST 2015] [demo] [local0.debug] : Successfully exposed [Zeppelin](https://zeppelin.incubator.apache.org/)
    ........
    ........


## Reset

    :~$ ./bin/50-reset.sh 

# References

Many thanks to the owners and writers of the below links:

* http://blog.bobbyallen.me/2015/05/17/setting-up-and-running-a-server-with-ubuntu-server-14-04-on-raspberry-pi-2/
