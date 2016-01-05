#!/bin/sh
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
uuid=$(uuidgen)
name=storage-node-$uuid
machine=$1
swarm=""

. ./setenv.sh

if [ "$machine" = "" ]; then
  echo "No machine specified. Going to use the Swarm then."
  machine="$prefix-admin"
  swarm="--swarm"
else
  echo "Creating NoSQL Storage Node $name on Docker Machine $machine ..."
fi

eval "$(docker-machine env $swarm $machine)"

docker run -d \
  --name=$name \
  --hostname=$name \
  --net=$network \
  $registry/nosql ./sample-cluster/deploy-storage-node.sh

echo ""
echo "Remember to call redistribute-topology.sh afterwards."
echo ""
