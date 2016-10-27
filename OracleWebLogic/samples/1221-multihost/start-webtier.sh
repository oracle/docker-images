#!/bin/sh
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# Author: Monica Riccelli <monica.riccelli@oracle.com>
# 
echo "Creating  the Apache WebTier to load balance requests to a WLS cluster for Multi Host Environment ..."
echo ""
machine=$1
swarm=""
webtierimage=1221-webtier
wlscluster=""
. ./setenv.sh

if [ "$machine" = "" ]; then
  echo "No machine specified. Going to use the Swarm then."
  machine="${prefix}-master"
  swarm="--swarm"
  echo "Running webtier container with config to instance $name on specific Docker Machine $machine ..."
else
  echo "Running webtier container with iconfig to instance $name on specific Docker Machine $machine ..."
fi

# Get Managed Server Container IP Address running on machine 
eval "$(docker-machine env $swarm $machine)"

for HOST in $(docker ps -a --format "{{.Names}}" | grep -i weblogic-instance )
do
    n=$(expr $(expr index $HOST /) + 1)
    length=$(expr "$HOST" : '.*')
    HOST=$(echo $HOST | cut -c$n-$length)
    wlscluster=$wlscluster"$HOST:7001,"
done

wlscluster=$(echo $wlscluster | sed 's/.$//')

# Save existing defined image to a file to be loaded later into the registry created above
eval "$(docker-machine env -u)"
docker save  $webtierimage > _tmp_docker.img 

# Load, tag, and publish the webtier image 
eval "$(docker-machine env $orchestrator)"
docker load -i _tmp_docker.img && rm _tmp_docker.img
docker tag $webtierimage 127.0.0.1:5000/$webtierimage
docker push 127.0.0.1:5000/$webtierimage

# Run Webtier container on weblogic-master
eval "$(docker-machine env $prefix-master)"
docker run -d \
  -e WEBLOGIC_CLUSTER=$(echo $wlscluster) \
  -p 80:80 \
  --net=$network \
  $registry/$webtierimage

echo ""
echo "WebTier Container now running in  $prefix-master."
echo ""
echo "You may now access the sample application deployed to the DockerCluster http://$(docker-machine ip $prefix-master):80/sample"

