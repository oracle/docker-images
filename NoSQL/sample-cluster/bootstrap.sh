#!/bin/sh
# 
# author: Bruno Borges <bruno.borges@oracle.com>
# 
echo "Bootstraping the required elements for the sample NoSQL cluster on Docker ..."
echo ""

. ./setenv.sh

# Booting up a Docker Machine instance to orchestrate Multihost Network (with Consul and Registry)
echo "Creating Multihost Orchestrator Machine ..."
docker-machine create -d virtualbox $orchestrator
eval "$(docker-machine env $orchestrator)"

# update variables
. ./setenv.sh

echo "Starting a Registry Server ..."
docker run -d -p 5000:5000 --restart=always --name registry -h registry registry:2

echo "Starting Consul Machine ..."
docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap

# Booting up the NoSQL Admin Node
echo "Creating machine nosql-admin ..."
docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  nosql-admin

echo "Creating the Docker Network Overlay '$network' ..."
eval "$(docker-machine env nosql-admin)"
docker network create --driver overlay $network

# Build and publish custom NoSQL image with deploy scripts
docker build -t nosql inner-scripts/
docker tag nosql $registry/nosql
docker push $registry/nosql

# Deploy Oracle NoSQL Admin
docker run -dit \
  --name=admin \
  --hostname=admin \
  -p 5001:5001 \
  --net=$network \
  $registry/nosql ./sample-cluster/deploy-admin.sh
