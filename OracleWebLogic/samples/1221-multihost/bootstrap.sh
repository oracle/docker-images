#!/bin/sh
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# Author: Bruno Borges <bruno.borges@oracle.com>
# 
echo "Bootstraping the required elements for sample WebLogic Dynamic Clustering on Docker ..."
echo ""

. ./setenv.sh

# Booting up a Docker Machine instance to orchestrate Multihost Network (with Consul and Registry)
echo "Creating Multihost Orchestrator Machine ..."
docker-machine create -d virtualbox --engine-insecure-registry 127.0.0.1:5000 $orchestrator 
eval "$(docker-machine env $orchestrator)"

# update variables
. ./setenv.sh

echo "Starting Registry Server ..."
docker run -d -p 5000:5000 --restart=always --name registry -h registry registry:2

echo "Starting Consul Machine ..."
docker run -d -p 8500:8500 --restart=always --name consul -h consul progrium/consul -server -bootstrap

# Booting up the WebLogic Admin Server Machine
echo "Creating machine weblogic-admin ..."
docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --swarm \
  --swarm-master \
  --swarm-discovery="consul://$consul" \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  weblogic-admin

# Create overlay Docker Multihost Network and set Docker environment pointing to Machine
eval "$(docker-machine env --swarm weblogic-admin)"
echo "Creating the Docker Network Overlay '$network' ..."
docker network create --driver overlay $network

# Save existing defined image to a file to be loaded later into the registry created above
eval "$(docker-machine env -u)"
docker save $image > weblogic.img

# Load, tag, and publish WebLogic Image based on 1221-domain sample (by default; see setenv.sh)
eval "$(docker-machine env $orchestrator)"
docker load -i weblogic.img && rm weblogic.img
docker tag $image 127.0.0.1:5000/weblogic
docker push 127.0.0.1:5000/weblogic

# Deploy WebLogic Admin Server
eval "$(docker-machine env weblogic-admin)"
docker run -d \
  --name=wlsadmin \
  --hostname=wlsadmin \
  -p 8001:8001 \
  --net=$network \
  --ulimit nofile=16384:16384 \
  $registry/weblogic

echo ""
echo "You may now access the WebLogic Admin Console at http://$(docker-machine ip weblogic-admin):8001/console"
echo ""
