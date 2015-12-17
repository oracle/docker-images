#!/bin/sh
javakv="java -jar $KVHOME/lib/kvstore.jar"
hostname=$(hostname -f)

$javakv makebootconfig \
  -root $KVROOT \
  -port 5000 \
  -host $hostname \
  -harange 5010,5020 \
  -store-security none \
  -capacity 1

$javakv start -root $KVROOT &

sleep 2

# create storage node 
cat << EOF > /tmp/nosql.script
  plan deploy-sn -dc dc1 -port 5000 -host $hostname -wait
EOF

cat /tmp/nosql.script | while read LINE ;do
  java -jar $KVHOME/lib/kvstore.jar runadmin -host admin -port 5000 $LINE;
done

touch /var/kvroot/snaboot_0.log

tail -f /var/kvroot/snaboot_0.log
