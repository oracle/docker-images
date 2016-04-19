#!/bin/sh
#
# Deploy Project Specific First Container
#

. ./setenv.sh

#start WLS Admin Server
eval "$(docker-machine env $prefix-master)"
docker run -d ${POST_BOOTSTRAP_DOCKER_OPTS} \
  --name=${prefix}01 \
  --hostname=${prefix}01 \
  --net=$network \
  --ulimit nofile=16384:16384 \
  $registry/$adminimage

# Output some message to the user
echo ""
eval "POST_BOOTSTRAP_MESSAGE=\"$POST_BOOTSTRAP_MESSAGE\""
echo $POST_BOOTSTRAP_MESSAGE
echo ""
