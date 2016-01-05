# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
prefix=weblogic
orchestrator=$prefix-orchestrator
orchestrator_address=$(docker-machine ip $orchestrator)
registry="$orchestrator_address:5000"
consul="$orchestrator_address:8500"
network=$prefix-net
image=1221-domain
