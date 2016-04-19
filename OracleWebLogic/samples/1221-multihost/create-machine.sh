#!/bin/sh
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
. ./setenv.sh

random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
name=$prefix-$random

echo "Creating new Docker Machine $name ..."

docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --swarm \
  --swarm-discovery="consul://$(docker-machine ip $orchestrator):8500" \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  $name

echo ""
echo "Machine $name successfuly created."
echo "Deploy containers on this machine by calling:"
echo ""
echo "  $ ./create-container.sh $name <unique server name suffix>"
echo ""
echo "Or just call the script above without arguments, and a new container will be created in the Swarm."
echo ""
