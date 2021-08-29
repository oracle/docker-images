# Oracle DNS Server to resolve RAC IPs
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to setup DNS server to resolve all the containers hostname, RAC VIPS and SCAN. This image is for only testing purpose.

## How to build and run
**IMPORTANT:** If you are behind the proxy, you need to set http_proxy env variable based on your enviornment before building the image.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters. Go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

```
./buildDockerImage.sh -i -v (Software Version)
./buildDockerImage.sh -i -v 18.3.0
```

**NOTE**: To build OracleDNSServer Image for 18.3.0, pass the version 18.3.0 to buildDockerImage.sh

For detailed usage of command, please execute folowing command:
```
./buildDockerImage.sh -h
```

### Create Bridge
Before creating container, create the bridge for NFS storage container.

```
# docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
# docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
```

**Note:** You can change subnet according to your environment.

### Disable SELINUX
SELINUX must be disabled or in permissive mode.

### Running OracleDNSServer Docker container
Execute following command to create the container:

```
docker create --name racdns \
--hostname rac-dns  \
--dns-search="example.com" \
--cap-add=SYS_ADMIN  \
--network  rac_pub1_nw \
--ip 172.16.1.25 \
--sysctl net.ipv6.conf.all.disable_ipv6=1 \
--env SETUP_DNS_CONFIG_FILES="setup_true" \
--env WEBMIN_ENABLED=false \
--env DOMAIN_NAME="example.com" \
--env RAC_NODE_NAME_PREFIX="racnode" \
--env "container=docker"  \
oracle/dns-rac:19.3.0 
```

In the above example, we used **172.16.1.0/24** subnet for public network. You can change the subnet values according to your environment.

To check the dnserver container/services creation logs , please tail docker logs. It will take 10 minutes to create the racnode-storage container service.

```
docker logs -f racdns-server
```

you should see following in docker logs output:

```
#################################################
runOracle.sh: DNSServer is up and Running
#################################################
```
