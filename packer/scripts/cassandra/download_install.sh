#!/bin/bash

# install packages
sudo apt-get update -y -qq
sudo apt-get install -y openjdk-8-jdk-headless
sudo apt-get install -y cloud-utils
sudo apt-get install -y python-dev python-setuptools python-yaml
sudo apt-get install -y apt-transport-https tar openssl sysstat libaio1

# download and uncompress DSE
mkdir dse; wget -c https://downloads.datastax.com/enterprise/dse-6.8.tar.gz -O - | tar -xz -C dse --strip-components=1

# download DSE packages
echo "deb https://debian.datastax.com/enterprise stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
curl -L https://debian.datastax.com/debian/repo_key | sudo apt-key add -
sudo apt-get update
sudo apt install --download-only -y dse-full datastax-agent
