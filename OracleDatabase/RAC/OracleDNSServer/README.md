## How to build and run
You need to make sure that you have atleast 1GB of space available for the container to create the files for RAC DNSServer.

**IMPORTANT:** If you are behind the proxy, you need to set the http_proxy env variable based on your environment before building the image.

To assist in building the images, you can use the `buildDockerImage.sh` script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters. Go into the dockerfiles folder and run the `buildDockerImage.sh` script:

```
./buildDockerImage.sh -v (Software Version)
./buildDockerImage.sh -v latest
```
**NOTE:** To build DNS server Image, pass the version latest to `buildDockerImage.sh`. The RAC DNSServer image is not tied to any release of the RAC release, you can use `latest` version to build the image.

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
/usr/bin/docker run -d --hostname racdns --dns-search=example.com \
 --network=rac_pub1_nw --ip=172.16.1.25 \
 -e DOMAIN_NAME="internal.example.com" \
 -e PRIVATE_DOMAIN_NAME="internal-priv.example.com" \
 -e WEBMIN_ENABLED=false \
 -e RAC_NODE_NAME_PREFIX="racnode" \
 -e SETUP_DNS_CONFIG_FILES="setup_true" \
 --privileged=false \
 --name rac-dnsserver oracle/rac-dns-server:latest
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
