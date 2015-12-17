#!/bin/sh
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
name=nosql-storage-machine-$random

. ./setenv.sh

echo "Creating NoSQL Storage Machine $name ..."

docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" $name

sh create-storage-node.sh $name

echo "Machine $name created with one NoSQL SN. Deploy more Storage Nodes with:"
echo "  $ ./create-storage-node.sh $name"
