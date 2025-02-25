# Oracle DNS Server to resolve Oracle RAC IPs

Example container build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to set up a DNS server for Oracle RAC. You can skip this step if you already have a DNS server configured that you can use for Oracle RAC. You should ensure that the DNS server container is up before you start the Oracle RAC database.

## How to build and run
You need to ensure that you have at least 350 MB of space available for the container to create the files for the Oracle RAC DNS server.

**IMPORTANT:** If you are behind a proxy, then you must set the `http_proxy or https_proxy` env variable based on your environment before building the image.

The `buildContainerImage.sh` script can assist with building the images. See examples below for instructions and usage.

The `buildContainerImage.sh` script is a utility shell script that performs MD5 checks. It provides an easy way to get started. Users can also use the podman build command to build an image with custom configuration parameters.
To run the script, go into the `containerfiles` folder and run the `buildContainerImage.sh` script as given below. Set the https_proxy and http_proxy as appropriate for your environment.

```bash
export https_proxy=<https://PROXY_HOST:PROXY_PORT>
export http_proxy=<http://PROXY_HOST:PROXY_PORT>

./buildContainerImage.sh-v <Software Version>
./buildContainerImage.sh -v latest
```
NOTE: To build the DNS server image, pass the latest version to `buildContainerImage.sh`. The Oracle RAC DNS server image is not tied to any Oracle RAC release, so you can use `latest` version to build the image.

For detailed usage instructions, please run the following command:

```bash
./buildContainerImage.sh -h
```

## Create container networks
Before you create the DNS server container, ensure that you have created the required networks, so you can attach the DNS server to the correct network addresses. The following are examples of creating `bridge`, `macvlan` or `ipvlan` [networks](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html).

Example of creating bridge networks-
```bash
podman network create --driver=bridge --subnet=10.0.20.0/24 rac_pub1_nw
```
Example of creating macvlan networks-
```bash
podman network create -d macvlan --subnet=10.0.20.0/24 -o parent=ens5 rac_pub1_nw
```

Example of creating ipvlan networks-
```bash
podman network create -d ipvlan --subnet=10.0.20.0/24 -o parent=ens5 rac_pub1_nw
```

**Note:** You can change the subnet and parent network interfaces according to your environment. In this case, we have chosen `10.0.20` as prefix to subnet.

### Running RAC DNS server container
Run the following commands in sequence to create the container:

```bash
podman run -d -t \
  --hostname racdns \
  --dns-search=example.info \
   --cap-add=AUDIT_WRITE \
  -e DOMAIN_NAME="example.info" \
  -e WEBMIN_ENABLED=false \
  -e RAC_NODE_NAME_PREFIXP="racnodep" \
  -e SETUP_DNS_CONFIG_FILES="setup_true"  \
  --network=rac_pub1_nw --ip=10.0.20.25 \
  --privileged=false \
  --name rac-dnsserver \
  localhost/oracle/rac-dnsserver:latest
```

To check the DNS server container and services creation logs, you can run a tail command on the podman logs. It can take up to two minutes for the racdns container to start completely.

```bash
podman logs rac-dnsserver
```

you should see the following in podman logs output:

```bash
#################################################
 DNS Server IS READY TO USE!
#################################################
```
**Note:** You also have the option to add a private domain name (if required) using an environment variable. For example, you can add `-e PRIVATE_DOMAIN_NAME="example-priv.info"` and also add `RAC_NODE_NAME_PREFIXD="racnoded"` for the Docker domain prefix.

## Environment Variables Explained
| Environment Variable    | Description                                                                                                         |
|-------------------------|---------------------------------------------------------------------------------------------------------------------|
| DOMAIN_NAME              | The domain name associated with the container environment.                                                                    |
| WEBMIN_ENABLED           | Indicates whether Webmin is enabled or not.                                                                         |
| RAC_NODE_NAME_PREFIXP    | Prefix used for the RAC container node names.                                                                                 |
| SETUP_DNS_CONFIG_FILES   | Indicates whether DNS configuration files are set up (e.g `setup_true`).                                                |

## DNS Entries Explained

| Entity                      | Description                                                                  |
|-----------------------------|------------------------------------------------------------------------------|
| App Servers (appmc1-5)     | These are application servers mapped to IP addresses ranging from 10.0.20.125 to 10.0.20.129. |
| Database Servers (dbmc1-5) | These are database servers mapped to IP addresses ranging from 10.0.20.195 to 10.0.20.199. |
| RAC Nodes (racnodep1-25)   | These are clustered database nodes mapped to IP addresses ranging from 10.0.20.170 to 10.0.20.194. |
| RAC Node VIPs (racnodep1-25-vip) | These are virtual IP addresses for RAC nodes, each mapped to respective IPs. |
| Clients (client1-5)         | These are client machines mapped to IP addresses ranging from 10.0.20.225 to 10.0.20.229. |
| RAC Node SCAN IPs (racnodepc1-5-scan) | These are SCAN IPs for RAC nodes. |
| RAC Node Cluster Manager IPs (racnodepc1-2-cman) | These are cluster manager IPs for RAC nodes. |

For example, appmc1 resolves to 10.0.20.125, dbmc1 resolves to 10.0.20.195, and so on.

**Note:** You can change the subnet and parent network interfaces according to your environment. In this case, we have chosen `10.0.20` as prefix to subnet.

## License

Unless otherwise noted, all scripts and files hosted in this repository that are required to build the container images are released under the UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.