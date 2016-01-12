#!/bin/sh
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
uuid=$(uuidgen)
name=$prefix-instance-$uuid
machine=$1
swarm=""

if [ "$machine" = "" ]; then
  echo "No machine specified. Going to use the Swarm then."
  machine="${prefix}01"
  swarm="--swarm"
  echo "Creating container instance $name on the Swarm of master $machine..."
else
  echo "Creating container instance $name on specific Docker Machine $machine ..."
fi

eval "$(docker-machine env $swarm $machine)"

. ./setenv.sh

docker run -d $DOCKER_CONTAINER_INSTANCE_OPTIONS \
  --name=$name \
  --hostname=$name \
  --net=$network \
  --ulimit nofile=16384:16384 \
  $registry/$image $DOCKER_CONTAINER_INSTANCE_CMD
