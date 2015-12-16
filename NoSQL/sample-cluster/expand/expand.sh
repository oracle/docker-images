#!/bin/sh
javakv="java -jar $KVHOME/lib/kvstore.jar"

cat << EOF > /tmp/nosql.script
  topology clone -current -name docker0
  topology redistribute -name docker0 -pool AllStorageNodes
  topology preview -name docker0
  plan deploy-topology -name docker0 -wait
EOF

cat /tmp/nosql.script | while read LINE ;do
  nohup java -jar $KVHOME/lib/kvstore.jar runadmin -host ${NOSQL_ADMIN_HOST:-master} -port 5000 $LINE;
done


touch /var/kvroot/adminboot_0.log 
touch /var/kvroot/snaboot_0.log

tail -f $KVROOT/*.log
