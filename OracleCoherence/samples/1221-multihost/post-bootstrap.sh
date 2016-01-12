#!/bin/sh
#
# Deploy Project Specific First Container 
#

. ./setenv.sh

eval "$(docker-machine env $prefix-master)"
docker run -d ${POST_BOOTSTRAP_DOCKER_OPTS} \
  --name=${prefix}01 \
  --hostname=${prefix}01 \
  --net=$network \
  --ulimit nofile=16384:16384 \
  $registry/$image

# Output some message to the user
echo ""
echo ""
