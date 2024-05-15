# Oracle DNS Server to resolve Oracle RAC IPs

Sample container build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to setup DNS server for RAC. You can skip this step if you already have a DNS server configure and which can be used for Oracle RAC. You should ensure that the DNS server container is up before starting RAC. This image is provided for test purposes only.

## How to build and run
You need to make sure that you have at least 350MB of space available for the container to create the files for RAC DNS server.

**IMPORTANT:** If you are behind a proxy, you need to set the `http_proxy or https_proxy` env variable based on your environment before building the image. Please ensure that you have the `podman-docker` package installed on your OL8 Podman host to run the command using the docker utility.
```bash
dnf install podman-docker -y
```

The `buildContainerImage.sh` script can assist with building the images. See below for instructions and usage.

The `buildContainerImage.sh` script is a utility shell script that performs MD5 checks and is an easy way to get started. Users can also use the docker build command to build an image with custom configuration parameters. To run the script, go into the `dockerfiles` folder and run the `buildContainerImage.sh` script:

```bash
cd <git-cloned-path>/docker-images/OracleDatabase/RAC/OracleDNSServer/dockerfiles 
./buildContainerImage.sh-v <Software Version>
./buildContainerImage.sh -v latest
```
NOTE: To build the DNS server image, pass the version latest to `buildContainerImage.sh`. The RAC DNS server image is not tied to any release of the RAC release, you can use `latest` version to build the image.

For detailed usage instructions, please execute the following command:

```bash
./buildContainerImage.sh -h
```

## Create bridge
Before you create the DNS server container, ensure you have created the required network bridges so you can attach the DNS server to the correct bridge.

```bash
docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
```
**Note:** You can change the subnet according to your environment.

## Running RAC DNS server container
### Execute following command to create the container on Docker Host

```bash
docker create --hostname racdns \
  --dns-search=example.com \
  --cap-add=AUDIT_WRITE \
  -e DOMAIN_NAME="example.com" \
  -e WEBMIN_ENABLED=false \
  -e RAC_NODE_NAME_PREFIXD="racnoded" \
  -e SETUP_DNS_CONFIG_FILES="setup_true"  \
  --privileged=false \
  --name rac-dnsserver \
 oracle/rac-dnsserver:latest
```
Connect networks to DNS container in DockerHost-
```bash
docker network disconnect bridge rac-dnsserver
docker network connect rac_pub1_nw --ip 172.16.1.25 rac-dnsserver
docker network connect rac_priv1_nw --ip 192.168.17.25 rac-dnsserver
docker start rac-dnsserver
```

### Execute following command to create the container on Podman Host

```bash
podman create --hostname racdns \
  --dns-search=example.com \
  --cap-add=AUDIT_WRITE \
  -e DOMAIN_NAME="example.com" \
  -e WEBMIN_ENABLED=false \
  -e RAC_NODE_NAME_PREFIXP="racnodep" \
  -e SETUP_DNS_CONFIG_FILES="setup_true"  \
  --privileged=false \
  --name rac-dnsserver \
 oracle/rac-dnsserver:latest
```

Connect networks to DNS container in PodmanHost-
```bash
podman network disconnect podman rac-dnsserver
podman network connect rac_pub1_nw --ip 172.16.1.25 rac-dnsserver
podman network connect rac_priv1_nw --ip 192.168.17.25 rac-dnsserver
podman start rac-dnsserver
```
In the above example, we used **172.16.1.0/24** subnet for the DNS server. You can change the subnet values according to your environment.

Also, `RAC_NODE_NAME_PREFIXD`, `RAC_NODE_NAME_PREFIXP`, and `PRIVATE_DOMAIN_NAME` are optional environment variables. You can utilize one depending on whether you are planning to use DNS Server on Docker or Podman Host and want to utilize the Private Network Domain respectively.

To check the DNS server container/services creation logs, please tail the Docker logs. It may take up to 2 minutes for the racdns container to start completely.

```bash
docker logs -f rac-dnsserver
```

you should see the following in docker logs output:

```bash
#################################################
DNS Server IS READY TO USE!
#################################################
```