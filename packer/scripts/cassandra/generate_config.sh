#!/bin/bash

###
### Generates cassandra.yaml and other files based on environment variables
###

export AZ=$(ec2metadata --availability-zone)
export REGION=$(echo $AZ | sed 's/.$//')
export PRIVATE_IP=$(ec2metadata --local-ipv4)

# Replace cassandra.yaml file
cp dse/resources/cassandra/conf/cassandra.yaml dse/resources/cassandra/conf/cassandra.yaml.ori
cp cassandra.yaml dse/resources/cassandra/conf/

cd dse/resources/cassandra/conf

# Set DC and RACK on cassandra-rackdc.properties
cp cassandra-rackdc.properties cassandra-rackdc.properties.ori
printf 'dc=%s\nrack=%s\n' $REGION $AZ > cassandra-rackdc.properties

# Remove cassandra-topology.properties file
mv cassandra-topology.properties cassandra-topology.properties.ori

# Set seeds and listen address
printf '\nlisten_address: "%s"' $PRIVATE_IP >> cassandra.yaml
printf '\nrpc_address: "%s"' $PRIVATE_IP >> cassandra.yaml
printf '\nseed_provider:\n    - class_name: org.apache.cassandra.locator.SimpleSeedProvider\n      parameters:\n          - seeds: ' >> cassandra.yaml
printf '"%s"\n' $1 >> cassandra.yaml

cd
