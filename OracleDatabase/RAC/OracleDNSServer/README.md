# Build the OracleDNSServer Docker image

1. Clone the repository from the [DNS GIT repository](https://github.com/tthathac/docker-images/tree/patch-1)
2. cd OracleDatabase/RAC/OracleDNSServer/dockerfiles
3. export https_proxy=http://www-proxy-hqdc.us.oracle.com:80/
4. export https_proxy=http://www-proxy-hqdc.us.oracle.com:80/
5. ./buildDockerImage.sh -v 4.1
6. docker images

   You should see that oracle/rac-dns-server:4.1 is created. You can name it anything based on your requirement.

# Create the DNS container
Use the following command ( replace appropriately if needed ) to create the DNS container.

/usr/bin/docker run -d --hostname racdns --dns-search=us.oracle.com \\

--network=rac_pub1_nw --ip=172.16.1.25 \\

-e DOMAIN_NAME="internal.us.oracle.com" \\

-e PRIVATE_DOMAIN_NAME="internal-priv.us.oracle.com" \\

-e WEBMIN_ENABLED=false \\

-e RAC_NODE_NAME_PREFIX="racnode" \\

-e SETUP_DNS_CONFIG_FILES="setup_true" \\

-e CORP_DNS_DOMAIN_1="us.oracle.com" \\

-e CORP_DNS_DOMAIN_2="dbdevtestphx.oraclevcn.com" \\

-e CORP_DNS_SERVERS="100.96.241.2,100.96.241.194" \\

--privileged=false \\

--name rac-dnsserver oracle/rac-dns-server:4.1

# Network Details
The subnet mask used is : 255.255.192.0. So the CIDR is /18.
The network and the hostname resolution is :

CIDR=18

EXTERNAL_NETWORK=172.16.1

PUBLIC_SUBNET="192.168.17" : racnode1-racnode250

PRIVATE_SUBNET="192.168.150" : racnode1-priv - racnode250-priv

PRIVATE_SUBNET2="192.168.200" : racnode-priv2 - racnode250-priv2

PUBLIC_VIP_SUBNET="192.168.18" : racnode1-vip - racnode250-vip

PUBLIC_SVIP_SUBNET="192.168.19" : racnode1-svip[1-4] - racnode63-svip[1-4]

SCAN3_SUBNET="192.168.16" : racnode-scan1  - racnode-scan250

SCAN2_SUBNET="192.168.15" : racnode-scan1  - racnode-scan250

SCAN1_SUBNET="192.168.14" : racnode-scan1  - racnode-scan250

GNS_SUBNET="192.168.13" : racnode-gns1 - racnode-gns250

GNS_VIP_SUBNET="192.168.12" : racnode-gns1-vip - racnode-gns250-vip

CMAN_SUBNET="192.168.100" : racnode-cman1 - racnode-cman250

# Create Networks
docker network create --driver=bridge --subnet=$EXTERNAL_NETWORK.0/24 --gateway=$EXTERNAL_NETWORK.1 rac_eth3ext1_nw

docker network create --driver=bridge --subnet=$PUBLIC_NETWORK.0/$CIDR rac_eth0pub1_nw

docker network create --driver=bridge --subnet=$PRIVATE_NETWORK.0/$CIDR rac_eth1priv1_nw

docker network create --driver=bridge --subnet=$PRIVATE_NETWORK2.0/$CIDR rac_eth2priv2_nw

