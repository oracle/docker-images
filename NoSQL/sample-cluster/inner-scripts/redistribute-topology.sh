#!/bin/sh
random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
topology=docker-$random
javakv="java -jar $KVHOME/lib/kvstore.jar"

cat << EOF > /tmp/nosql.script
  topology clone -current -name $topology
  topology redistribute -name $topology -pool AllStorageNodes
  topology preview -name $topology
  plan deploy-topology -name $topology -wait
EOF

cat /tmp/nosql.script | while read LINE ;do
  java -jar $KVHOME/lib/kvstore.jar runadmin -host admin -port 5000 $LINE;
done
