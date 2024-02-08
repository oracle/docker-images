# Oracle ASM on NFS Server for RAC testing
Sample Docker and Podman build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to setup ASM on NFS for RAC. You can skip if you have physical block devices or NAS server for Oracle RAC and Grid. You need to make sure that NFS server container must be up and running for RAC functioning. This image is for only testing purpose.

Refer below instructions for setup of NFS Container for RAC -

- [Oracle ASM on NFS Server for RAC testing](#oracle-asm-on-nfs-server-for-rac-testing)
- [How to build NFS Storage Container Image](#how-to-build-nfs-storage-container-image)
  - [How to build NFS Storage Container Image on Docker Host](#how-to-build-nfs-storage-container-image-on-docker-host)
  - [How to build NFS Storage Container Image on Podman Host](#how-to-build-nfs-storage-container-image-on-podman-host)
- [Create Bridge Network](#create-bridge-network)
- [NFS Server installation on Host](#nfs-server-installation-on-host)
- [Running RACStorageServer container](#running-racstorageserver-container)
  - [RAC Storage container for Docker Host Machine](#rac-storage-container-for-docker-host-machine)
  - [RAC Storage Container for Podman Host Machine](#rac-storage-container-for-podman-host-machine)
- [Create NFS Volume](#create-nfs-volume)
- [Copyright](#copyright)

## How to build NFS Storage Container Image

### How to build NFS Storage Container Image on Docker Host
You need to make sure that you have atleast 60GB space available for container to create the files for RAC storage.

**IMPORTANT:** If you are behind the proxy, you need to set http_proxy env variable based on your enviornment before building the image. Please ensure that you have the `podman-docker` package installed on your OL8 Podman host to run the command using the docker utility.
```bash
dnf install podman-docker -y
```

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters. Go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

```bash
cd <git-cloned-path>/docker-images/OracleDatabase/RAC/OracleRACStorageServer/dockerfiles
./buildDockerImage.sh -v 19.3.0
```

For detailed usage of command, please execute folowing command:
```bash
cd <git-cloned-path>/docker-images/OracleDatabase/RAC/OracleRACStorageServer/dockerfiles
./buildDockerImage.sh -h
```
### How to build NFS Storage Container Image on Podman Host

You need to make sure that you have atleast 60GB space available for container to create the files for RAC storage.

**IMPORTANT:** If you are behind the proxy, you need to set `http_proxy` and `https_proxy` env variable based on your enviornment before building the image.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters. Go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

```bash
cd <git-cloned-path>/docker-images/OracleDatabase/RAC/OracleRACStorageServer/dockerfiles
./buildDockerImage.sh -v latest
```
You would see successful build message similar like below-
```bash
 Oracle RAC Storage Server Podman Image version latest is ready to be extended: 
    
    --> oracle/rac-storage-server:latest
```

## Create Bridge Network
Before creating container, create the bridge private network for NFS storage container.

On the host-
```bash
docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
```

**Note:** You can change subnet according to your environment.


## NFS Server installation on Host
Ensure to install NFS server rpms on  host to utilize NFS volumes in containers-

```bash
yum -y install nfs-utils
```
## Running RACStorageServer container

### RAC Storage container for Docker Host Machine

#### Prerequisites for RAC Storage Container for Docker Host

Create placeholder for NFS storage and make sure it is empty -
```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /docker_volumes/asm_vol/$ORACLE_DBNAME
rm -rf /docker_volumes/asm_vol/$ORACLE_DBNAME/asm_disk0*
```

Execute following command to create the container:

```bash
export ORACLE_DBNAME=ORCLCDB
docker run -d -t --hostname racnode-storage \
--dns-search=example.com  --cap-add SYS_ADMIN --cap-add AUDIT_WRITE \
--volume /docker_volumes/asm_vol/$ORACLE_DBNAME:/oradata --init \
--network=rac_priv1_nw --ip=192.168.17.80 --tmpfs=/run  \
--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
--name racnode-storage oracle/rac-storage-server:19.3.0
```

**IMPORTANT:** During the container startup 5 files named as `asm_disk0[1-5].img` will be created under /oradata.If the files are already present, they will not be recreated.These files can be used for ASM storage in RAC containers.

**NOTE**: Expose directory to container which has atleast 60GB. In the above  example, we are using `/docker_volumes/asm_vol/$ORACLE_DBNAME` and you need to change values according to your env. Inside container, it will be /oradata and do not change this.

In the above example, we used **192.168.17.0/24** subnet for NFS server. You can change the subnet values according to your environment. Also, SELINUX must be disabled or in permissive mode in Docker Host Machine.

To check the racstorage container/services creation logs , please tail docker logs. It will take 10 minutes to create the racnode-storage container service.

```bash
docker logs -f racnode-storage
```

you should see following in docker logs output:

```bash
#################################################
runOracle.sh: NFS Server is up and running
Create NFS volume for /oradata
#################################################
```

### RAC Storage Container for Podman Host Machine

#### Prerequisites for RAC Storage Container for Podman Host

Create placeholder for NFS storage and make sure it is empty -
```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /scratch/stage/rac-storage/$ORACLE_DBNAME
rm -rf /scratch/stage/rac-storage/$ORACLE_DBNAME/asm_disk0*
```

If SELinux is enabled on Podman Host (you can check by running `sestatus` command), then execute below to make SELinux policy as `permissive` and reboot the host machine. This will allow permissions to write to `asm-disks*` in the `/oradata` folder inside the podman containers-
```bash
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
reboot
```

Execute following command to create the container:

```bash
export ORACLE_DBNAME=ORCLCDB
podman run -d -t \
 --hostname racnode-storage \
 --dns-search=example.com  \
 --cap-add SYS_ADMIN \
 --cap-add AUDIT_WRITE \
 --cap-add NET_ADMIN \
 --volume /scratch/stage/rac-storage/$ORACLE_DBNAME:/oradata \
 --network=rac_priv1_nw \
 --ip=192.168.17.80 \
 --systemd=always \
 --restart=always \
 --name racnode-storage \
 localhost/oracle/rac-storage-server:latest
```

To check the racstorage container/services creation logs , please tail docker logs. It will take 10 minutes to create the racnode-storage container service.

```bash
podman exec racnode-storage tail -f /tmp/storage_setup.log
```
You would see successful message like below -
```bash
#################################################
 Setup Completed                                 
#################################################
```

**NOTE**: Expose directory to container which has atleast 60GB. In the above  example, we are using `/scratch/stage/rac-storage/$ORACLE_DBNAME` and you need to change values according to your env. Inside container, it will be /oradata and do not change this.

In the above example, we used **192.168.17.0/24** subnet for NFS server. You can change the subnet values according to your environment.

**Note** : If SELINUX is enabled on the Podman host, then you must create an SELinux policy for Oracle RAC on Podman. For details about this procedure, see "How to Configure Podman for SELinux Mode" in the publication [Oracle Real Application Clusters Installation Guide for Podman Oracle Linux x86-64](https://docs.oracle.com/en/database/oracle/oracle-database/21/racpd/target-configuration-oracle-rac-podman.html#GUID-59138DF8-3781-4033-A38F-E0466884D008).


**IMPORTANT:** During the container startup 5 files named as `asm_disk0[1-5].img` will be created under /oradata.If the files are already present, they will not be recreated.These files can be used for ASM storage in RAC containers.

### Create NFS Volume
Create NFS volume using following command on Podman Host:

```bash
docker volume create --driver local \
--opt type=nfs \
--opt   o=addr=192.168.17.80,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=192.168.17.80:/oradata \
racstorage
```

**IMPORTANT:** If you are not using 192.168.17.0/24 subnet then you need to change **addr=192.168.17.25** based on your environment.

**IMPORTANT:** The NFS volume must be `/oradata` which you will export to RAC containers for ASM storage. It will take 10 minutes for setting up NFS server.

## Copyright

Copyright (c) 2014-2024 Oracle and/or its affiliates. All rights reserved.