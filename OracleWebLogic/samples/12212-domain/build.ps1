#!/bin/powershell
if ( $args.Count -eq 0 ) { echo "Inform a password for the domain as first argument."; exit; }
docker build --build-arg ADMIN_PASSWORD=$($args[0]) -t 12212-domain . 
