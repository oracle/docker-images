#!/bin/sh
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
uuid=$(uuidgen)
name=managedserver-$uuid
machine=$1
swarm=""

if [ "$machine" = "" ]; then
  echo "No machine specified. Going to use the Swarm then."
  machine="weblogic-admin"
  swarm="--swarm"
  echo "Creating WebLogic Managed Server $name on Docker Machine Swarm of $machine..."
else
  echo "Creating WebLogic Managed Server $name on specific Docker Machine $machine ..."
fi

eval "$(docker-machine env $swarm $machine)"

. ./setenv.sh

docker run -d \
  --name=$name \
  --hostname=$name \
  --net=$network \
  --ulimit nofile=16384:16384 \
  $registry/weblogic sh createServer.sh

