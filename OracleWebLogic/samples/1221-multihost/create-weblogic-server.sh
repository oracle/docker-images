#!/bin/sh
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
uuid=$(uuidgen)
name=managedserver-$uuid
machine=$1

if [ "$machine" = "" ]; then
  echo "You must inform which Docker Machine to use as first argument"
  exit 1
fi

echo "Creating WebLogic Managed Server $name on Docker Machine $machine ..."

eval "$(docker-machine env $machine)"

. ./setenv.sh

docker run -d \
  --name=$name \
  --hostname=$name \
  --net=$network \
  --ulimit nofile=16384:16384 \
  $registry/weblogic sh createServer.sh

