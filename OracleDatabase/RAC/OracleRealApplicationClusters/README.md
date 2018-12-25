Oracle Real Application Clusters (RAC) is an option to the award-winning Oracle Database Enterprise Edition. Oracle RAC is a cluster database with a shared cache architecture that overcomes the limitations of traditional shared-nothing and shared-disk approaches to provide highly scalable and available database solutions for all business applications. Oracle RAC uses Oracle Clusterware as a portable cluster software that allows clustering of independent servers so that they cooperate as a single system and Oracle Automatic Storage Management (ASM) to provide simplified storage management that is consistent across all server and storage platforms. Oracle Clusterware and Oracle ASM are part of the Oracle Grid Infrastructure, which bundles both solutions in an easy to deploy software package.

For more information on Oracle RAC Database 18c refer to the [Oracle Database documentation](http://docs.oracle.com/en/database/).

## How to build and run

This project offers sample Docker files for Oracle Grid Infrastructure and Real Application Cluster Database:

    
	Oracle Database 18c Grid Infrastructure (18.3) for Linux x86-64
    Oracle Database 18c (18.3) for Linux x86-64
	Oracle Database 12c Release 2 Grid Infrastructure (12.2.0.1.0) for Linux x86-64
    Oracle Database 12c Release 2 (12.2.0.1.0) Enterprise Edition for Linux x86-64


IMPORTANT: You can build and run RAC containers on a single host or multiple hosts. To access the RAC DB on your network either use the Docker MACVLAN driver or use Oracle Connection Manager. To Run RAC containers on Multi-Host, you must use the Docker MACVLAN driver and your network must be reachable on all the nodes for RAC containers.


## Using this Image
To create a RAC cluster, please execute the steps in the following sections below:

1.  Prerequisites for running RAC in Docker containers
2.  Building the Oracle RAC Database Docker Install Images
3.  Creating the first Grid Infrastructure and RAC container
4.  Adding an additional node containers
5.  Connecting to the RAC database
6.  Environment variables for the first node
7.  Environment variables for the second and subsequent nodes
8.  Support
9.  License
10. Copyright


## Section 1 : Prerequsites for RAC on Docker

**IMPORTANT :** You must make the changes specified in this section (customized for your environment) before you proceed to the next section.

You must install and configure [Oracle Container Runtime for Docker](https://docs.oracle.com/cd/E52668_01/E87205/html/index.html) on Oracle Linux 7 to run RAC on Docker. Each container that you will deploy as part of your cluster must satisfy the minimum hardware requirements of the RAC and GI software. An Oracle RAC database is a shared everything database. 

All data files, control files, redo log files, and the server parameter file (`SPFILE`) used by the Oracle RAC database must reside on shared storage that is accessible by all the Oracle RAC database instances. 

You must provide block devices shared across the hosts.  If you don't have shared block storage, you can use an NFS volume.

Please refer Oracle Database 18c Release documentation [Oracle Grid Infrastructure Installation and Upgrade Guide](https://docs.oracle.com/en/database/oracle/oracle-database/18/cwlin/index.html) and allocate following resource as per the Oracle documentation.

1. You must configure the following addresses manually in your DNS.
   * Public IP address for each container
   * Private IP address for each container
   * Virtual IP address for each container
   * Three single client access name (SCAN) addresses for the cluster.
2. If you are planing to use block devices for shared storage, please allocate block devices for OCR/voting and database files.
3. If you are planing to use NFS storage for OCR/Voting and database files, please configure NFS storage and export at least one NFS mount. For testing purpose only, use the Oracle rac-storage-server image to deploy a docker container providing NFS-based sharable storage.
4. Verify you have enough memory and CPU resources available for all containers. Each container for RAC requires 8GB memory and 16GB swap.
5. For Oracle RAC, you must set following parameters at host level in `/etc/sysctl.conf`:

```
fs.file-max = 6815744
net.core.rmem_max = 4194304
net.core.rmem_default = 262144
net.core.wmem_max = 1048576
net.core.wmem_default = 262144
net.core.rmem_default = 262144
```

6. Execute following once the file is modified.

```
# sysctl -a
# sysctl -p
```

You need to plan your private and public network for containers before you start installation. You can create a network bridge on every host so containers running within that host can communicate with each other.  For example, create `rac_pub1_nw` for the public network (`172.16.1.0/24`) and `rac_priv1_nw` (`192.168.17.0/24`) for a private network. You can use any network subnet for testing however in this document we reference the public network on `172.16.1.0/24` and the private network on `192.168.17.0/24`.

```
# docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
# docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
```

You must run Oracle RAC on Docker on multi-host using the [Docker MACVLAN Driver](https://docs.docker.com/network/macvlan/). To create a network bridge using MACVLAN docker driver using following commands:

```
# docker network create -d macvlan --subnet=172.16.1.0/24 --gateway=172.16.1.1 -o parent=eth0 rac_pub1_nw
# docker network create -d macvlan --subnet=192.168.17.0/24 --gateway=192.168.17.1 -o parent=eth1 rac_priv1_nw
```

Oracle RAC needs to run certain processes in real-time mode. To run processes inside a container in real time mode, you need to make changes to the Docker configuration files. For details, please refer to the [`dockerd` documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#examples). and  update the `OPTIONS` value in `/etc/sysconfig/docker` to following:

```
OPTIONS='--selinux-enabled --cpu-rt-runtime=950000'
```

Once you have edited the `/etc/sysconfig/docker`, execute following commands:

```
# systemctl daemon-reload
# systemctl stop docker
# systemctl start docker
```

Verify you have enough memory and cpu resources available for container. For details, Please refer to [Oracle 18c Grid Infrastructure Installation and Upgrade Guide](https://docs.oracle.com/en/database/oracle/oracle-database/18/cwlin/index.html)

The Oracle RAC dockerfiles, does not contain any Oracle Software Binaries. Download the following software from the [Oracle Technology Network](https://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) and stage them under dockerfiles/<version> folder.

    Oracle Database 18c Grid Infrastructure (18.3) for Linux x86-64
    Oracle Database 18c (18.3) for Linux x86-64

FOLLOWING FREELY AVAILABLE PATCH IS REQUIRED FOR THIS IMAGE TO WORK. Download following patch from OTN and stage it on your machine.

    Patch# p28322130_183000OCWRU_Linux-x86-64.zip You can download this patch from [Oracle Technology Network](https://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html). Stage it under dockerfiles/<version> folder.

### Notes

* SELINUX must be in permissive mode.
* If the docker bridge network is not available outside your host, you can use the Oracle Connection Manager (CMAN) image to access the RAC Database from outside the host.
* If you are planing to build and deploy Oracle RAC 12.2.0.1, you need to download Oracle 12.2.0.1 Grid Infrastructure and Oracle Database 12.2.0.1 Database. You also need to download Patch# p27383741_122010_Linux-x86-64.zip from [Oracle Technology Network](https://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html). Stage it under dockerfiles/<version> folder.

## Section 2: Building Oracle RAC Database Docker Install Images

**IMPORTANT :** This section assumes that you have gone through the all the pre-requisites in Section 1 and executed all the steps based on your environment. Do not uncompress the binaries and patches.

To assist in building the images, you can use the [buildDockerImage.sh](https://github.com/oracle/docker-images/blob/master/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

```
./buildDockerImage.sh -v (Software Version)
#  e.g., ./buildDockerImage.sh -v 12.2.0.1
```

For detailed usage of command, please execute following command:

```
#  ./buildDockerImage.sh -h
```

### Notes

* The resulting images will contain the Oracle Grid Infrastructure Binaries and Oracle RAC Database binaries.
* If you are behind a proxy, you need to set the http_proxy or https_proxy environment variable based on your environment before building the image.

## Section 3: Creating the Docker GI and RAC Container

All containers will share a host file for name resolution.  The shared hostfile must be available to all container. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

```
# mkdir /opt/containers
# touch /opt/containers/rac_host_file
```

**Note:** Do not modify `/opt/containers/rac_host_file` from docker host. It will be managed from within the containers.

If you are using the Oracle Connection Manager for accessing the Oracle RAC Database from outside the host, you need to add following variable in the container creation command.

```
-e CMAN_HOSTNAME=(CMAN_HOSTNAME) -e CMAN_IP=(CMAN_IP)
```

**Note:** You need to replace `CMAN_HOSTNAME` and `CMAN_IP` with the correct values based on your environment settings.

Specify the secret volume for resetting grid/oracle and database password during node creation or node addition. It can be shared volume among all the containers

```
mkdir /opt/.secrets/
openssl rand -hex 64 -out /opt/.secrets/pwd.key
```

Edit the /opt/.secrets/common_os_pwdfile and seed the password for grid/oracle and database. It will be a common password for grid/oracle and database user. Execute following command:

```
openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
rm -f /opt/.secrets/common_os_pwdfile
```

**Note:** If you want to specify different password for all the accounts, create 3 different files and encrypt them under /opt/.secrets and pass the file name to the container using env variable. File name can be based on your enviornment policies.

### Deploying RAC on Docker With Block Devices:

If you are using an NFS volume, skip to the section below "Deploying RAC on Docker with NFS Volume".

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

Now create the Docker container using the image. For the details of environment variables, please refer to section 5. You can use following example to create a container:

```
# docker create -t -i \
  --hostname racnode1 \
  --volume /boot:/boot:ro \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets:/run/secrets \
  --dns-search=example.com \
  --device=/dev/xvde:/dev/asm_disk1  \
  --device=/dev/xvdf:/dev/asm_disk2 \
  --privileged=false  \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e NODE_VIP=172.16.1.160 \
  -e VIP_HOSTNAME=racnode1-vip  \
  -e PRIV_IP=192.168.17.150 \
  -e PRIV_HOSTNAME=racnode1-priv \
  -e PUBLIC_IP=172.16.1.150 \
  -e PUBLIC_HOSTNAME=racnode1  \
  -e SCAN_NAME=racnode-scan \
  -e SCAN_IP=172.16.1.70  \
  -e OP_TYPE=INSTALL \
  -e DOMAIN=example.com \
  -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
  -e ASM_DISCOVERY_DIR=/dev \
  -e CMAN_HOSTNAME=racnode-cman1 \
  -e CMAN_IP=172.16.1.15 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 --ulimit rtprio=99  \
  --name racnode1 
  oracle/database-rac:18.3.0
```

**Note:** Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.

### Deploying RAC on Docker With RAC Storage Container

Now create the Docker container using the image. For the details of environment variables, please refer to section 6. You can use following example to create a container:

```
# docker create -t -i \
  --hostname racnode1 \
  --volume /boot:/boot:ro \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets:/run/secrets \
  --dns-search=example.com \
  --privileged=false \
  --volume racstorage:/oradata \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE 
  --cap-add=NET_ADMIN \
  -e NODE_VIP=172.16.1.160  \
  -e VIP_HOSTNAME=racnode1-vip  \
  -e PRIV_IP=192.168.17.150  \
  -e PRIV_HOSTNAME=racnode1-priv \
  -e PUBLIC_IP=172.16.1.150 \
  -e PUBLIC_HOSTNAME=racnode1  \
  -e SCAN_NAME=racnode-scan \
  -e SCAN_IP=172.16.1.70  \
  -e OP_TYPE=INSTALL \
  -e DOMAIN=example.com \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
  -e CMAN_HOSTNAME=racnode-cman1 \
  -e CMAN_IP=172.16.1.15 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  --restart=always \
  --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --name racnode1 \
  oracle/database-rac:18.3.0
```

**Notes:**

* Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.
* You must have created the `racstorage` volume before the creation of RAC Container. For details about the env variables, please refer the section 6.

### Assign networks to RAC containers

You need to assign the Docker networks created in section 1 to containers. Please execute following commands:

```
# docker network disconnect bridge racnode1
# docker network connect rac_pub1_nw --ip 172.16.1.150 racnode1
# docker network connect rac_priv1_nw --ip 192.168.17.150  racnode1
```

### Start the first container
You need to start the container. Please execute following command:

```
# docker start racnode1
```

It can take at least 40 minutes or longer to create the first node of the cluster. To check the logs, use following command from another terminal session:

```
# docker logs -f racnode1
```

You should see database creation success message at the end:

```
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```
### Connect to the RAC container
To connect to the container execute following command:

```
# docker exec -i -t racnode1 /bin/bash
```

If the install fails for any reason, log in to container using the above command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.

## Section 4: Adding a RAC Node using a Docker container

Before proceeding to the next step, please ensure Oracle Grid Infrastructure is running and the Oracle RAC Database is open as per instructions in section 3. Otherwise, the node addition process will fail.

Specify the secret volume for resetting grid/oracle and database password during node creation or node addition. It can be shared volume among all the containers

```
mkdir /opt/.secrets/
openssl rand -hex 64 -out /opt/.secrets/pwd.key
```

Edit the /opt/.secrets/common_os_pwdfile and seed the password for grid/oracle and database. It will be a common password for grid/oracle and database user. Execute following command:

```
openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
rm -f /opt/.secrets/common_os_pwdfile
```

**Note:** If you want to specify different password for all the accounts, create 3 different files and encrypt them under /opt/.secrets and pass the file name to the container using env variable. File name can be based on your enviornment policies.

Reset the password on existing RAC node for SSH setup between existing node in the cluster and new node. Password must be same on all the nodes for grid and oracle user. Execute following command on an exiting node of the cluster.

```
docker exec racnode1 /opt/scripts/startup/resetOSPassword.sh 
```
**Note:** If you do not have common secret volume among RAC containers, populate the password file with the same password what you have used on new node, ecrypt the file and execute resetOSPassword.sh on the exiting node of the cluster.

### Deploying with Block Devices:

If you are using an NFS volume, skip to the section below "Deploying with the RAC Storage Container".

To create additional nodes, use following command:

```
# docker create -t -i 
  --hostname racnode2 \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G  \
  --volume /boot:/boot:ro \
  --dns-search=example.com  \
  --volume /opt/containers/rac_host_file:/etc/hosts \
  --volume /opt/.secrets:/run/secrets \
  --device=/dev/xvde:/dev/asm_disk1 \
  --device=/dev/zvdf:/dev/asm_disk2 \
  --privileged=false \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e EXISTING_CLS_NODES=racnode1 \
  -e NODE_VIP=172.16.1.161  \
  -e VIP_HOSTNAME=racnode2-vip  \
  -e PRIV_IP=192.168.17.151  \
  -e PRIV_HOSTNAME=racnode2-priv \
  -e PUBLIC_IP=172.16.1.151  \
  -e PUBLIC_HOSTNAME=racnode2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnode-scan \
  -e SCAN_IP=172.16.1.70 \
  -e ASM_DISCOVERY_DIR=/dev \
  -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --restart=always \
  --name racnode2 \
  oracle/database-rac:18.3.0
```

For details of all environment variables and parameters, please refer to section 6.  

### Deploying RAC on Docker with RAC Storage Container

If you are using physical block devices for shared storage, skip to "Assigning Network to additional RAC container"

Use the existing `racstorage:/oradata` volume when creating the additional Docker container using the image.  

For example:

```
# docker create -t -i \
  --hostname racnode2 \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G  \
  --volume /boot:/boot:ro \
  --dns-search=example.com  \
  --volume /opt/containers/rac_host_file:/etc/hosts \
  --volume /opt/.secrets:/run/secrets \
  --privileged=false \
  --volume racstorage:/oradata \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e EXISTING_CLS_NODES=racnode1 \
  -e NODE_VIP=172.16.1.161  \
  -e VIP_HOSTNAME=racnode2-vip  \
  -e PRIV_IP=192.168.17.151  \
  -e PRIV_HOSTNAME=racnode2-priv \
  -e PUBLIC_IP=172.16.1.151  \
  -e PUBLIC_HOSTNAME=racnode2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnode-scan \
  -e SCAN_IP=172.16.1.70 \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img  ,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --restart=always \
  --name racnode2 \
  container-registry.oracle.com/database/rac:12.2.0.1
```

**Notes:**
* You must have created **racstorage** volume before the creation of RAC container.
* You can change env variable such as IPs and ORACLE_PWD based on your env. For details about the env variables, please refer the section 6.

### Assign Network to additional RAC container

Assign Network to container

```
# docker network disconnect bridge racnode2
# docker network connect rac_pub1_nw --ip 172.16.1.151 racnode2
# docker network connect rac_priv1_nw --ip 192.168.17.151 racnode2
```

### Start RAC container

Start the container

```
# docker start racnode2
```

To check the DB logs, please tail the logs using the following command:

```
# docker logs -f racnode2
```

You should see database creation success message at the end.

```
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

### Connect to the RAC container

To connect to the container execute following command:

```
# docker exec -i -t racnode2 /bin/bash
```

If the node addition fails, log in to the container using the above command and review `/tmp/orod.log`. You can also review the Grid Infrastructure logs i.e. `$GRID_BASE/diag/crs` and check for failure logs. If the node creation has failed during the database creation process, then check DB logs.

## Section 5: Connecting to RAC Database

**IMPORTANT:** This section assumes that you have successfully created a RAC cluster using the steps above.

If you are using connection manager and exposed the port 1521 on the host, connect from an external client using following connection string:

```
system/<password>@//<docker_host>:1521/<ORACLE_SID>
```

If you are using the Docker MACVLAN driver and you have configured DNS appropriately, you can connect using the public scan listener directly from any external client using the following connection string:

```
system/<password>@//<scan_name>:1521/<ORACLE_SID>
```

## Section 6: Environment Variables for the first node

**IMPORTANT:** This section provides details about the environment variables which can be used when creating the first node of a cluster.

Parameters:

```
OP_TYPE=###Specify the Operation TYPE. It can accept 2 values INSTALL OR ADDNODE####

NODE_VIP=####Specify the Node VIP###

VIP_HOSTNAME=###Specify the VIP hostname###

PRIV_IP=###Specify the Private IP###

PRIV_HOSTNAME=###Specify the Private Hostname###

PUBLIC_IP=###Specify the public IP###

PUBLIC_HOSTNAME=###Specify the public hostname###

SCAN_NAME=###Specify the scan name###

ASM_DEVICE_LIST=###Specify the ASM Disk lists.

SCAN_IP=###Specify this if you do not have DNS server###

DOMAIN=###Default value set to example.com###

PASSWORD=###OS password will be generated by openssl###

CLUSTER_NAME=###Default value set to racnode-c####

ORACLE_SID=###Default value set to ORCLCDB###

ORACLE_PDB=###Default value set to ORCLPDB###

ORACLE_PWD=###Default value set to generated by openssl random password###

ORACLE_CHARACTERSET=###Default value set AL32UTF8###

DEFAULT_GATEWAY=###Default gateway. You need this env variable if containers
will be running on multiple hosts.####

CMAN_HOSTNAME=###Connection Manager Host Name###

CMAN_IP=###Connection manager Host IP###

ASM_DISCOVERY_DIR=####ASM disk location insdie the container. By default it is /dev######

COMMON_OS_PWD_FILE=###You need to pass this for ssh setup between grid and oracle user.###
```

## Section 6: Environment Variables for the second and subsequent nodes

**IMPORTANT:** This section provides the details about the environment variables which can be used for all additional nodes added to an existing cluster.

```
OP_TYPE=###Specify the Operation TYPE. It can accept 2 values INSTALL OR ADDNODE###

EXISTING_CLS_NODES=###Specify the Existing Node of the cluster which you want to join.If you have 2 node in the cluster and you are trying to add third node then spcify existing 2 nodes of the clusters and separate them by comma.####

NODE_VIP=###Specify the Node VIP###

VIP_HOSTNAME=###Specify the VIP hostname###

PRIV_IP=###Specify the Private IP###

PRIV_HOSTNAME=###Specify the Private Hostname###

PUBLIC_IP=###Specify the public IP###

PUBLIC_HOSTNAME=###Specify the public hostname###

SCAN_NAME=###Specify the scan name###

SCAN_IP=###Specify this if you do not have DNS server###

ASM_DEVICE_LIST=###Specify the ASM Disk lists.

DOMAIN=###Default value set to example.com###

ORACLE_SID=###Default value set to ORCLCDB###

DEFAULT_GATEWAY=###Default gateway. You need this env variable if containers will be running on multiple hosts.####

CMAN_HOSTNAME=###Connection Manager Host Name###

CMAN_IP=###Connection manager Host IP###

ASM_DISCOVERY_DIR=####ASM disk location insdie the container. By default it is /dev######

COMMON_OS_PWD_FILE=###You need to pass this for ssh setup between grid and oracle user.###
```

Section 8 : Support

Oracle RAC Database is supported for Oracle Linux 7.

IMPORTANT: Note that the current version of Oracle RAC on Docker is only supported for test and development environments, but not for production environments.

Section 9 : License

To download and run Oracle Grid and Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker images are, unless otherwise noted, released under UPL 1.0 license.

Section 10 : Copyright

Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
