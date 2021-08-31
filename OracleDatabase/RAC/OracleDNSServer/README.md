# Oracle DNS Server to resolve Oracle RAC IPs

Sample container build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to setup DNS server for RAC. You can skip this step if you already have a DNS server configure and which can be used for Oracle RAC. You should ensure that the DNS server container is up before starting RAC. This image is provided for test purposes only.

## How to build and run
You need to make sure that you have at least 350MB of space available for the container to create the files for RAC DNS server.

**IMPORTANT:** If you are behind a proxy, you need to set the `http_proxy or https_proxy` env variable based on your environment before building the image.

The `buildContainerImage.sh` script can assist with building the images. See below for instructions and usage.

The `buildContainerImage.sh` script is a utility shell script that performs MD5 checks and is an easy way to get started. Users can also use the docker build command to build an image with custom configuration parameters. To run the script, go into the `dockerfiles` folder and run the `buildContainerImage.sh` script:

```
./buildContainerImage.sh-v <Software Version>
./buildContainerImage.sh -v latest
```
NOTE: To build the DNS server image, pass the version latest to `buildContainerImage.sh`. The RAC DNS server image is not tied to any release of the RAC release, you can use `latest` version to build the image.

For detailed usage instructions, please execute the following command:

```
./buildContainerImage.sh -h
```

## Create bridge
Before you create the DNS server container, ensure you have created the required network bridges so you can attach the DNS server to the correct bridge.

```
docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
```
**Note:** You can change the subnet according to your environment.

### Running RAC DNS server container
Execute following command to create the container:

```
docker run -d  --name racdns \
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

To check the DNS server container/services creation logs, please tail the Docker logs. It may take up to 2 minutes for the racdns container to start completely.

```
docker logs -f racdns
```

you should see the following in docker logs output:

```
#################################################
runOracle.sh: RACDNSServer is up and running!
#################################################
```
