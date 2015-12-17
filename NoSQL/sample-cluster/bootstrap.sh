#!/bin/sh
# 
# author: Bruno Borges <bruno.borges@oracle.com>
# 
echo "Bootstraping the required elements for the sample NoSQL cluster on Docker ..."
echo ""


# Booting up Consul on a Docker Machine instance
echo "Creating Multi Host Keystore ..."
docker-machine create -d virtualbox mh-keystore

echo "Starting Consul Machine ..."
eval "$(docker-machine env mh-keystore)"
docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap

# Booting up the NoSQL Admin Node
echo "Creating machine node-admin ..."
docker-machine create -d virtualbox --virtualbox-cpu-count=2 --engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" --engine-opt="cluster-advertise=eth1:2376"  node-admin

echo "Creating the Docker Network Overlay 'nosql-net' ..."
eval "$(docker-machine env node-admin)"
docker network create --driver overlay nosql-net

# TEMPORARY
docker build -t admin inner-scripts/

docker run -d \
  --name=admin \
  --hostname=admin \
  -p 5001:5001 \
  --net=nosql-net \
  admin ./sample-cluster/deploy-admin.sh

