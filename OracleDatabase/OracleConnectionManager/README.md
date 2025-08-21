# Oracle Connection Manager in Linux Containers
Oracle Connection Manager is a proxy server that forwards connection requests to databases or other proxy servers. It operates at the session level, and usually resides on a computer separate from the database server and client computers.

This guide provides information about example container build files that you can use to facilitate installation, configuration, and environment setup of Oracle Connection Manager for DevOps users. For more information about Oracle Database, please see the [Oracle Connection Manager online Documentation](http://docs.oracle.com/en/database/).

## Using this documentation
- [Oracle Connection Manager in Linux Containers](#oracle-connection-manager-in-linux-containers)
  - [Using this documentation](#using-this-documentation)
  - [How to build and run Oracle Connection Manager in Containers](#how-to-build-and-run-oracle-connection-manager-in-containers)
  - [Getting Oracle Connection Manager Image](#getting-oracle-connection-manager-image)
    - [Create Oracle Connection Manager Image](#create-oracle-connection-manager-image)
  - [Create Network Bridge](#create-network-bridge)
  - [How to deploy Oracle Connection Manager Container](#how-to-deploy-oracle-connection-manager-container)
    - [Create Oracle Connection Manager Container](#create-oracle-connection-manager-container)
    - [Create Oracle Connection Manager Container using `cman.ora`](#create-oracle-connection-manager-container-using-cmanora)
  - [Environment Variables Explained](#environment-variables-explained)
  - [License](#license)
  - [Copyright](#copyright)

## How to build and run Oracle Connection Manager in Containers
This project offers example container images for the following:
* Oracle Database 23ai Client (23.5) for Linux x86-64
* Oracle Database 21c Client (21.3) for Linux x86-64
* Oracle Database 19c Client (19.3) for Linux x86-64
* Oracle Database 18c Client (18.3) for Linux x86-64
* Oracle Database 12c Release 2 Client (12.2.0.1.0) for Linux x86-64

To assist in building the container images, you can use the [buildContainerImage.sh](containerfiles/buildContainerImage.sh) script. See section **Create Oracle Connection Manager Image** for instructions and usage.

**IMPORTANT:** Oracle Connection Manager binds to a single port on your host, and proxies incoming connections to multiple running containers. It can also proxy connections for users to Oracle Databases running on internal container networks.

For complete Oracle Connection Manager setup, please go though following steps and execute them as per your environment:

## Getting Oracle Connection Manager Image
You can also deploy Oracle Connection Manager on Podman using the pre-built images available on the Oracle Container Registry. Refer [this documentation](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/docker-UsingDockerRegistries.html#docker-registry) for details on using Oracle Container Registry.

Example of pulling an Oracle Connection Manager Image from the Oracle Container Registry:
```bash
podman pull container-registry.oracle.com/database/cman:23.7.0.0
podman tag container-registry.oracle.com/database/cman:23.7.0.0 localhost/oracle/client-cman:latest
```

If you are using pre-built Oracle Connection Manager from [the Oracle Container Registry](https://container-registry.oracle.com), then you can skip the section [Create Oracle Connection Manager Image](#create-oracle-connection-manager-image) to build the Oracle Connection Manager Image.

### Create Oracle Connection Manager Image
**IMPORTANT:** You must provide the installation binaries of the Oracle ADMIN Client Oracle Database 23ai Client for Linux x86-64 (client_cman_home.zip) and put them into the `containerfiles/<version>` folder. You  only need to provide the binaries for the edition that you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html).
You also have to ensure you have internet connectivity for yum. You must not uncompress the binaries.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks. It provides an easy way for beginners to get started. Expert users are welcome to directly call `podman build` with their prefered set of parameters.
Before you build the image, ensure that you have provided the installation binaries and put them into the right folder. Go into the **containerfiles** folder and run the **buildContainerImage.sh** script as root or with sudo privileges:

```bash
./buildContainerImage.sh -v (Software Version)
./buildContainerImage.sh -v 23.5.0
```
For detailed usage of command, please execute following command:
```bash
./buildContainerImage.sh -h
```
Note:
- Usage of `./buildContainerImage.sh`-
   ```text
   -v: version to build
   -i: ignores the MD5 checksums
   -t: user defined image name and tag (e.g., image_name:tag). Default is set to oracle/client-cman:<VERSION>.
   -o: passes on container build option (e.g., --build-arg ARGUMENT=value).
   ```
- If you are behind a proxy wall, then you must set the `https_proxy` or `http_proxy` environment variable based on your environment before building the image.

Once image is built, retag it to latest as we are going to refer latest image in podman run command-
```bash
podman tag localhost/oracle/client-cman:23.5.0 localhost/oracle/client-cman:latest
```

## Create Network Bridge
**Note:** You can change subnet according to your environment.

Before creating the container, create the podman network. If you are using the same network which the Oracle RAC containers are created [using the documentation](../OracleRealApplicationClusters/README.md), then you can use the same IPs mentioned in the [Create Oracle Connection Manager Container](#create-oracle-connection-manager-container) section.

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
If you want to use Jumbo Frames MTU Network Configuration as similar as with Oracle RAC containers networks, then refer [Jumbo Frames MTU Network Configuration](../OracleRealApplicationClusters/README.md#jumbo-frames-mtu-network-configuration) section

## How to deploy Oracle Connection Manager Container
The Oracle Connection manager container (CMAN) can be used with either an Oracle Real Application Clusters (Oracle RAC) database or with an Oracle Database Single instance database. However, you must ensure that the SCAN Name or the Single host instance database Hostname is resolvable from the connection manager container.
Oracle highly recommends that you use a DNS Server so that name resolution can happen successfully.

### Create Oracle Connection Manager Container
Before creating Oracle Connection Manager, we advise to review the **[Environment Variables Explained](#environment-variables-explained) section**. If you are planning to `cman.ora` file skip to [section](#create-oracle-connection-manager-container-using-cmanora)
To create the connection manager container, run the following command as the root user:

 ```bash
 podman run -d \
  --hostname racnodepc1-cman \
  --dns-search=example.info \
  --dns 10.0.20.25 \
  --network=rac_pub1_nw \
  --ip=10.0.20.166 \
  --cap-add=AUDIT_WRITE \
  --cap-add=NET_RAW \
  -e DOMAIN=example.info \
  -e PUBLIC_IP=10.0.20.166 \
  -e DNS_SERVER=10.0.20.25 \
  -e PUBLIC_HOSTNAME=racnodepc1-cman \
  --privileged=false \
  -p 1521:1521 \
  --name racnodepc1-cman \
  oracle/client-cman:latest
```

### Create Oracle Connection Manager Container using `cman.ora`
If you want to provide your own pre-created `cman.ora` file, you can provide with `-e USER_CMAN_FILE=<cman-file-name>` and also add attach <cman-file-name> as podman volume to podman run command. Refer sample of [cman.ora](./containerfiles/cman.ora) and execute below command to create Oracle Connection Manager Container -
```bash
  podman run -d \
    --hostname racnodepc1-cman \
    --dns-search=example.info \
    --dns 10.0.20.25 \
    --network=rac_pub1_nw \
    --ip=10.0.20.166 \
    --cap-add=AUDIT_WRITE \
    --cap-add=NET_RAW \
    -v /opt/containers/cman.ora:/var/tmp/cman.ora \
    -e USER_CMAN_FILE=/var/tmp/cman.ora \
    -e DOMAIN=example.info \
    -e PUBLIC_IP=10.0.20.166 \
    -e DNS_SERVER=10.0.20.25 \
    -e PUBLIC_HOSTNAME=racnodepc1-cman \
    --privileged=false \
    -p 1521:1521 \
    --name racnodepc1-cman \
    oracle/client-cman:23.5.0
```

To check the Cman container/services creation logs, you can run a tail command on the podman logs. It should take two minutes to create the Cman container service.

```bash
podman logs racnodepc1-cman
```

You should see the following when the cman container setup is done:

```bash
###################################
CONNECTION MANAGER IS READY TO USE!
###################################
```

### Adding rules to the Oracle Connection Manager

You can add rules to the OracleConnectionManager using the following command line syntax.
Run this command inside the OracleConnectionManager container.
  ```bash
podman exec -i -t racnodepc1-cman /bin/bash

/opt/scripts/startup/configCMAN.sh -addrule -e DB_HOSTDETAILS=<HOST-DETAILS>
For example :
/opt/scripts/startup/configCMAN.sh -addrule -e DB_HOSTDETAILS=HOST=racnodep9:IP=10.0.20.178:RULE_SRC=racnodepc2-cman
```
### Deleting rules from the Oracle Connection Manager

You can delete the rules from the OracleConnectionManager using the following command line syntax.
Run this command inside the OracleConnectionManager container.
  ```bash
   podman exec -i -t racnodepc1-cman /bin/bash
  
   /opt/scripts/startup/configCMAN.sh -delrule -e RULEDETAILS=<RULE-DETAILS>
   For example :
   /opt/scripts/startup/configCMAN.sh -delrule -e RULEDETAILS=RULE_DST=racnodep8
```
## Environment Variables Explained
| Environment Variable  | Description  |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| DOMAIN              | The domain name associated with the container environment.  |
| PUBLIC_IP          | The public IP address assigned to the Oracle Connection Manager container.  |
| PUBLIC_HOSTNAME    | The public hostname assigned to the Oracle Connection Manager container.  |
| DB_HOSTDETAILS       | This is optional field. Details regarding the database host configuration, including host names, rules, and IP addresses to be registered with Connection manager in a command separated format, indicating different hosts and their associated details such as rules and IP addresses. Example: `HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170`. |
| DNS_SERVER        | The default is set to `10.0.20.25`, which is the DNS container resolving the Connection Manager and Oracle Database containers. Replace this with your DNS server IP if needed.  |
| USER_CMAN_FILE    | (Optional) If you want to provide your own pre-created `cman.ora` file, set this environment variable and attach the file as a Podman volume in the `podman run` command.  |

## License

To download and run the Oracle ADMIN Client Oracle Database 23ai Client, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
