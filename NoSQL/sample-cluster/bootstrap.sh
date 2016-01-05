#!/bin/sh
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
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
docker run -d -p 8500:8500 --restart=always --name consul -h consul progrium/consul -server -bootstrap

# Booting up the NoSQL Admin Machine 
echo "Creating machine $prefix-admin ..."
docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --swarm \
  --swarm-master \
  --swarm-discovery="consul://$(docker-machine ip $orchestrator):8500" \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  $prefix-admin

echo "Creating the Docker Network Overlay '$network' ..."
eval "$(docker-machine env $prefix-admin)"
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
