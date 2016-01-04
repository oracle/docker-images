#!/bin/sh
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
. ./setenv.sh

random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
name=$prefix-machine-$random

echo "Creating WebLogic Docker Machine $name ..."

docker-machine create -d virtualbox \
  --virtualbox-cpu-count=2 \
  --swarm \
  --swarm-discovery="consul://$(docker-machine ip $orchestrator):8500" \
  --engine-insecure-registry $registry \
  --engine-opt="cluster-store=consul://$consul" \
  --engine-opt="cluster-advertise=eth1:2376" \
  $name

eval "$(docker-machine env --swarm $name)"

sh create-weblogic-server.sh $name

echo ""
echo "Machine $name successfuly created with one containerized WebLogic Managed Server."
echo "Deploy more Managed Servers in this same machine by calling:"
echo ""
echo "  $ ./create-weblogic-server.sh $name"
echo ""
echo "Or just call the script above without arguments, and a new container will be created in the Swarm'
