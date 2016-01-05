#!/bin/sh
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
javakv="java -jar $KVHOME/lib/kvstore.jar"
hostname=$(hostname -f)

$javakv makebootconfig \
  -root $KVROOT \
  -port 5000 \
  -admin 5001 \
  -host $hostname \
  -store-security none \
  -harange 5010,5020 \
  -capacity 1 

$javakv start -root $KVROOT &

sleep 2

# create initial topology
cat << EOF > /tmp/nosql.script
  configure -name mystore
  plan deploy-datacenter -name docker -rf 1 -wait
  plan deploy-sn -dc dc1 -port 5000 -host $hostname -wait
  plan deploy-admin -sn sn1 -port 5001 -wait
  topology create -name docker -pool AllStorageNodes -partitions 30
  plan deploy-topology -name docker -wait
EOF

cat /tmp/nosql.script | while read LINE ;do
  java -jar $KVHOME/lib/kvstore.jar runadmin -host $hostname -port 5000 $LINE;
done

touch /var/kvroot/adminboot_0.log 
touch /var/kvroot/snaboot_0.log

tail -f $KVROOT/*.log
