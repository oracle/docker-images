#!/bin/sh
# 
# author: Bruno Borges <bruno.borges@oracle.com>
# 
echo "Bootstraping the required elements for sample WebLogic Dynamic Clustering on Docker ..."
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

# Booting up the WebLogic Admin Server Machine
echo "Creating machine weblogic-admin ..."
docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  weblogic-admin

echo "Creating the Docker Network Overlay '$network' ..."
eval "$(docker-machine env weblogic-admin)"
docker network create --driver overlay $network

# Build and publish WebLogic Empty Domain Image
docker build -t oracle/weblogic:12.2.1-dev -f ../../dockerfiles/12.2.1/Dockerfile.developer ../../dockerfiles/12.2.1/
docker build -t weblogic ../1221-domain/
docker tag weblogic $registry/weblogic
docker push $registry/weblogic

# Deploy WebLogic Admin Server
docker run -d \
  --name=wlsadmin \
  --hostname=wlsadmin \
  -p 8001:8001 \
  --net=$network \
  $registry/weblogic
