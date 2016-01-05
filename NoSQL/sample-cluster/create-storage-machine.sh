#!/bin/sh
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
. ./setenv.sh

random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
name=$prefix-storage-machine-$random

echo "Creating NoSQL Storage Machine $name ..."

docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --swarm \
  --swarm-discovery="consul://$(docker-machine ip $orchestrator):8500" \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  $name

sh create-storage-node.sh $name

echo ""
echo "Machine $name created with one NoSQL SN. Deploy more Storage Nodes with:"
echo ""
echo "  $ ./create-storage-node.sh $name"
echo ""
echo "Or just call the script above without arguments, and a new container will be created in the Swarm"
