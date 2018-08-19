#!/bin/sh
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Author: Bruno Borges <bruno.borges@oracle.com>
#
echo "Bootstraping the required elements for Docker Machine and Swarm ..."
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

# Booting up Swarm Master
echo "Creating machine $prefix-master ..."
docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --swarm \
  --swarm-master \
  --swarm-discovery="consul://$consul" \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  $prefix-master

# Create overlay Docker Multihost Network and set Docker environment pointing to Machine
eval "$(docker-machine env --swarm $prefix-master)"
echo "Creating the Docker Network Overlay '$network' ..."
docker network create --driver overlay $network

# Save existing defined image to a file to be loaded later into the registry created above
eval "$(docker-machine env -u)"
docker save $image > _tmp_docker.img

# Load, tag, and publish the image set in setenv.sh
eval "$(docker-machine env $orchestrator)"
docker load -i _tmp_docker.img && rm _tmp_docker.img
docker tag $image 127.0.0.1:5000/$image
docker push 127.0.0.1:5000/$image

# Call post-bootstrap.sh if present and executable
if [ -x ./post-bootstrap.sh ]; then
  . ./post-bootstrap.sh
fi
