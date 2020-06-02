#!/bin/bash

# install packages
sudo apt-get update -y -qq
sudo apt-get install -y openjdk-8-jdk-headless
sudo apt-get install -y cloud-utils
sudo apt-get install -y python-dev python-setuptools python-yaml

# download and uncompress DSE
mkdir dse; wget -c https://downloads.datastax.com/enterprise/dse-6.8.tar.gz -O - | tar -xz -C dse --strip-components=1

