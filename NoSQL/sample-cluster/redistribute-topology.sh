#!/bin/sh
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
topology=docker-$random

cat << EOF > /tmp/nosql.script
  topology clone -current -name $topology
  topology redistribute -name $topology -pool AllStorageNodes
  topology preview -name $topology
  plan deploy-topology -name $topology -wait
EOF

eval $(docker-machine env nosql-admin)
adminid=$(docker ps -q -f name=admin)
cat /tmp/nosql.script | while read LINE ;do
  docker exec $adminid bash -c "java -jar lib/kvstore.jar runadmin -host admin -port 5000 $LINE";
done
