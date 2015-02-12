#!/bin/bash

# Start Node Manager
nohup startNodeManager.sh > log.nm &

# Wait and add it to the AdminServer
sleep 5 && . addMachine.sh

# print log 
tail -f log.nm
