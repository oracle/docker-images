#!/bin/sh
if [ "$#" -eq 0 ]; then echo "Provide a password for the domain as first argument."; exit; fi
docker build --build-arg ADMIN_PASSWORD=$1  -t 1213-domain . 

