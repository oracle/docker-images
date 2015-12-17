prefix=nosql
orchestrator=$prefix-orchestrator
orchestrator_address=$(docker-machine ip $orchestrator)
registry="$orchestrator_address:5000"
consul="$orchestrator_address:8500"
network=$prefix-net

echo "orchestrator=$orchestrator"
echo "registry=$registry"
echo "consul=$consul"
echo "network=$network"
