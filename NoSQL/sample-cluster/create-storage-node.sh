#!/bin/sh
uuid=$(uuidgen)
name=storage-node-$uuid
machine=$1

if [ "$machine" = "" ]; then
  echo "You must inform the Docker Machine to use as first argument"
  exit 1
fi

echo "Creating NoSQL Storage Node $name on Machine $machine ..."

eval "$(docker-machine env $machine)"

. ./setenv.sh

docker run -d \
  --name=$name \
  --hostname=$name \
  --net=$network \
  $registry/nosql ./sample-cluster/deploy-storage-node.sh
