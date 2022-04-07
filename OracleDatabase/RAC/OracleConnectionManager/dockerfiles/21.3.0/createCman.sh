/usr/bin/docker run -d --hostname racnode-cman1 --dns-search=internal.us.oracle.com \
--network=rac_pub1_nw --ip=172.16.1.15 \
-e DOMAIN=example.com -e PUBLIC_IP=172.16.1.15 \
-e PUBLIC_HOSTNAME=racnode-cman1 -e SCAN_NAME=racnode-scan \
-e SCAN_IP=172.16.1.170 --privileged=false \
-p 1521:1521 --name racnode-cman oracle/client-cman:21.3.0
