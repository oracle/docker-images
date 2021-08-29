# Oracle DNS Server to resolve RAC IPs

Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to the setup DNS server for RAC. You can skip if you have already a DNS server configured and can be used for Oracle RAC. You need to make sure that the DNS server container must be up and running for RAC functioning. This image is for only testing purposes.

## How to build and run
You need to make sure that you have atleast 100MB of space available for the container to create the files for RAC DNSServer.

**IMPORTANT:** If you are behind the proxy, you need to set the http_proxy env variable based on your environment before building the image.

To assist in building the images, you can use the `buildDockerImage.sh` script. See below for instructions and usage.

The buildDockerImage.sh script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters. Go into the dockerfiles folder and run the buildDockerImage.sh script:

```
./buildDockerImage.sh -v (Software Version)
./buildDockerImage.sh -v latest
```
NOTE: To build DNS server Image, pass the version latest to `buildDockerImage.sh`. The RAC DNSServer image is not tied to any release of the RAC release, you can use `latest` version to build the image.

For detailed usage of command, please execute folowing command:

`./buildDockerImage.sh -h`

## Create Bridge
Before creating the container, create the bridge for RACDNSServer container.

```
docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
```
**Note:** You can change the subnet according to your environment.

### Running RACDNSServer Docker container
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
 --env DOMAIN_NAME="example.com" \
 --env RAC_NODE_NAME_PREFIX="racnode" \
 oracle/rac-dnsserver:latest
```

In the above example, we used **172.16.1.0/24** subnet for the DNS server. You can change the subnet values according to your environment.

To check the DNSServer container/services creation logs, please tail docker logs. It will take 5 minutes to create the racdns container service.

```
docker logs -f racdns
```

you should see the following in docker logs output:

```
#################################################
runOracle.sh: RACDNSServer is up and running!
#################################################
```
