#!/bin/bash

if [ ! -f /usr/local/tomcat/bin/kafka-console-producer.sh ]; then
    curl http://apache.mirrors.spacedump.net/kafka/0.11.0.2/kafka_2.11-0.11.0.2.tgz | tar xvz --strip-components=1
fi
