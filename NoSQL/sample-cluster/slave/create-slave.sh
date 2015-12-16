#!/bin/sh
nohup java -jar $KVHOME/lib/kvstore.jar makebootconfig \
  -root $KVROOT \
  -port 5000 \
  -host $(hostname -f) \
  -harange 5010,5020 \
  -store-security none \
  -capacity 1
# \
#  -num_cpus 0 \
#  -memory_mb 0

nohup java -jar $KVHOME/lib/kvstore.jar start -root $KVROOT &

sleep 2

# create storage node 
cat << EOF > /tmp/nosql.script
  plan deploy-sn -dc dc1 -port 5000 -host $(hostname -f) -wait
EOF

cat /tmp/nosql.script | while read LINE ;do
  nohup java -jar $KVHOME/lib/kvstore.jar runadmin -host ${NOSQL_ADMIN_HOST:-master} -port 5000 $LINE;
done

touch /var/kvroot/snaboot_0.log

tail -f /var/kvroot/snaboot_0.log
