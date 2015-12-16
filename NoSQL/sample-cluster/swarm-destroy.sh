#!/bin/bash
echo "Destroying Swarm cluster ..."
docker-machine rm -f mh-keystore swarm-master swarm-node-01 swarm-node-02 swarm-node-03
