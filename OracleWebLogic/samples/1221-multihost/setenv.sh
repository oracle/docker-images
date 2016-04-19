# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
prefix=weblogic
orchestrator=$prefix-orchestrator
orchestrator_address=$(docker-machine ip $orchestrator)
registry="$orchestrator_address:5000"
consul="$orchestrator_address:8500"
network=$prefix-net
#Images for Admin Server and Managed Server
image=1221-appdeploy
adminimage=1221-servlet-proxy
DOCKER_CONTAINER_INSTANCE_OPTIONS="-e ADMIN_HOST=${prefix}01"
DOCKER_CONTAINER_INSTANCE_CMD="sh createServer.sh"

POST_BOOTSTRAP_DOCKER_OPTS="-p 8001:8001"
POST_BOOTSTRAP_MESSAGE='You may now access the WebLogic Admin Console at http://$(docker-machine ip $prefix-master):8001/console'
