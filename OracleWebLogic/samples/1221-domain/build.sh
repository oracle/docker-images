#!/bin/sh
if [ "$#" -eq 0 ]; then echo "Inform a password for the domain as first argument and admin server name as second argument ."; exit; fi
docker build --build-arg ADMIN_PASSWORD=$1 --build-arg ADMIN_NAME=$2 -t 1221-domain . 
