#!/bin/sh
uuid=$(uuidgen)
name=storage-node-$uuid

echo "Creating NoSQL Storage Node $name ..."

docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" \
  --engine-opt="cluster-advertise=eth1:2376" $name

eval "$(docker-machine env $name)"

# TEMPORARY
docker build -t storage inner-scripts/

docker run -d \
  --name=$name \
  --hostname=$name \
  --net=nosql-net storage ./sample-cluster/deploy-storage-node.sh 
