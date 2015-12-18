#!/bin/sh
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
. ./setenv.sh

random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
name=$prefix-storage-machine-$random

echo "Creating NoSQL Storage Machine $name ..."

docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
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
