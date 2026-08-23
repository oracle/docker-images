# Oracle ASM on NFS Server for RAC testing
learn how to use example Podman build files to facilitate installation, configuration, and environment setup NFS Server for Oracle Real Application Clusters (Oracle RAC) testing for DevOps users.

**IMPORTANT:** This image can be used to set up ASM on NFS for Oracle RAC. You can skip this procedure if you have physical block devices or an NAS server for Oracle RAC and Oracle Grid Infrastructure. You must ensure that the NFS server container is up and running for Oracle RAC functioning.

Refer to the following instructions for setup of NFS Container for Oracle RAC:

- [Oracle ASM on NFS Server for Oracle RAC testing](#oracle-asm-on-nfs-server-for-rac-testing)
- [How to build NFS Storage Container Image on Container host](#how-to-build-nfs-storage-container-image-on-container-host)
- [Create Bridge Network](#create-bridge-network)
- [NFS Server installation on Podman Host](#nfs-server-installation-on-podman-host)
- [SELinux Configuration on Podman Host](#selinux-configuration-on-podman-host)
- [Oracle RAC Storage Container for Podman Host](#oracle-rac-storage-container-for-podman-host)
- [Create NFS Volume](#create-nfs-volume)
- [Sample Container Files for Older Releases](#sample-container-files-for-older-releases)
- [Copyright](#copyright)

## How to build NFS Storage Container Image on Container host
To create the files for Oracle RAC storage, ensure that you have at least 60 GB space available for the container.

**IMPORTANT:** If you are behind a proxy, then you must set the `http_proxy` and `https_proxy` environment variables (env variables) to values based on your environment before building the image.

To assist in building the images, you can use the [`buildContainerImage.sh`](containerfiles/buildContainerImage.sh) script. See below for instructions and usage.

In this guide, we refer to Oracle Linux 8 onwards as the Podman Host.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks. It provides an easy way for beginners to get started. Expert users are welcome to directly call `podman build` with their preferred set of parameters. Go into the **containerfiles** folder and run the **buildContainerImage.sh** script on your Podman host:

```bash
./buildContainerImage.sh -v (Software Version)
./buildContainerImage.sh -v latest
```

In a successful build, you should see build messages similar to the following:
```bash
 Oracle RAC Storage Server Container Image version latest is ready to be extended:
    
    --> oracle/rac-storage-server:latest
```

For detailed usage notes for this script, run the following command:
```bash
./buildContainerImage.sh -h
Usage: buildContainerImage.sh -v [version] [-o] [Podman build option]
Builds a Podman Image for Oracle Database.
  
Parameters:
   -v: version to build e.g latest
   -o: passes on Podman build option
```

### Create Bridge Network
Before creating the container, create the bridge public network for the NFS storage container.

The following are examples of creating `bridge`, `macvlan` or `ipvlan` [networks](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html).

Example of creating bridge networks:
```bash
podman network create --driver=bridge --subnet=10.0.20.0/24 rac_pub1_nw
```
Example of creating macvlan networks:
```bash
podman network create -d macvlan --subnet=10.0.20.0/24 -o parent=ens5 rac_pub1_nw
```

Example of creating ipvlan networks:  
```bash
podman network create -d ipvlan --subnet=10.0.20.0/24 -o parent=ens5 rac_pub1_nw
```

**Note:** You can change the subnet and parent network interfaces according to your environment.

### NFS Server installation on Podman Host
To use NFS volumes in containers, you must install NFS server RPMs on the Podman host. For example:
```bash
dnf install -y nfs-utils
```

### SELinux Configuration on Podman Host
If SELinux is enabled on the Podman host, then you must install another SELINUX module, and specifically enable permissions to write to the Podman host. To check if your SELinux is enabled or not, run the `getenforce` command.

Copy [`rac-storage.te`](./rac-storage.te) to the `/var/opt` folder in your host and run the following commands:

```bash
cd /var/opt
make -f /usr/share/selinux/devel/Makefile rac-storage.pp
semodule -i rac-storage.pp
semodule -l | grep rac-storage
```
### Oracle RAC Storage Container for Podman Host
To create the container, run the following set of commands in the order presented below:

#### Prerequisites for RAC Storage Container for Podman Host

Create a placeholder for NFS storage and ensure that it is empty:
```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /scratch/stage/rac-storage/$ORACLE_DBNAME
rm -rf /scratch/stage/rac-storage/$ORACLE_DBNAME/asm_disk0*
```
If SELinux host is enabled on the machine, then run the following command:
```bash
semanage fcontext -a -t container_file_t /scratch/stage/rac-storage/$ORACLE_DBNAME
restorecon -v /scratch/stage/rac-storage/$ORACLE_DBNAME
```
#### Deploying Oracle RAC Storage Container for Podman Host
If you are building an Oracle RAC storage container for the Podman Host, then you can run the following commands:

```bash
export ORACLE_DBNAME=ORCLCDB
podman run -d -t \
 --hostname racnode-storage \
 --dns-search=example.info  \
 --dns 10.0.20.25 \
 --cap-add SYS_ADMIN \
 --cap-add AUDIT_WRITE \
 --cap-add NET_ADMIN \
 -e DNS_SERVER=10.0.20.25 \
 -e DOMAIN=example.info \
 --volume /scratch/stage/rac-storage/$ORACLE_DBNAME:/oradata \
 --network=rac_pub1_nw --ip=10.0.20.80 \
 --systemd=always \
 --restart=always \
 --name racnode-storage \
 localhost/oracle/rac-storage-server:latest
```

To check the Oracle RAC storage container and services creation logs, you can run a `tail` command on the Podman logs. It should take approximately 10 minutes to create the racnode-storage container service.

```bash
podman exec racnode-storage tail -f /tmp/storage_setup.log
```
In a successful deployment, you should see messages similar to the following:
```bash
Export list for racnode-storage:
/oradata *
#################################################
 Setup Completed                                 
#################################################
```

**IMPORTANT:** During the container startup, five files with the name  `asm_disk0[1-5].img` will be created under `/oradata`. If the files are already present, then they will not be recreated. These files can be used for ASM storage in Oracle RAC containers.

**NOTE**: Place the directory in a container that has at least 60 GB. In the preceding example, we are using `/scratch/stage/rac-storage/$ORACLE_DBNAME`. Change these values according to your environment. Inside the container, the directory will be `/oradata`. Do not change this value.

In the following example, we use **192.168.17.0/24** as the subnet for the NFS server. You can change the subnet values according to your environment.

**IMPORTANT:** The NFS volume must be `/oradata`, which you will export to Oracle RAC containers for ASM storage. It will take approximately 10 minutes to set up the NFS server.

### Create NFS Volume

```bash
podman volume create --driver local \
--opt type=nfs \
--opt   o=addr=10.0.20.80,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=10.0.20.80:/oradata \
racstorage
```


**IMPORTANT:** If you are not using the `192.168.17.0/24` subnet then you must change **addr=192.168.17.80** based on your environment.

## Environment variables explained

| Environment Variable | Description           |
|----------------------|-----------------|
| DNS_SERVER           | Default set to `10.0.20.25`. Specify the comma-separated list of DNS server IP addresses where both Oracle RAC nodes are resolved.      |
| DOMAIN               | Default set to `example.info`. Specify the domain details for the Oracle RAC Container Environment.    |

## Sample Container Files for Older Releases
To setup an Oracle RAC storage Container for the Docker host on Oracle Linux 7, refer older [README](./README1.md#how-to-build-nfs-storage-container-image-on-docker-host)
instructions.

## License
Unless otherwise noted, all scripts and files hosted in this repository that are required to build the container images are under UPL 1.0 license.

## Copyright
Copyright (c) 2014-2025 Oracle and/or its affiliates.