Example of creating a custom Oracle RAC database
=============================================
After you build your Oracle RAC Docker image, you can create an Oracle RAC database with a custom configuration by passing the responsefile for Oracle Grid Infrastructure and Oracle Database to the container.

## Section 1 : Prerequisites for Custom Oracle RAC Database on Docker
**IMPORTANT :** You must complete all of the steps specified in this section (customized for your environment) before you proceed to the next section.

* Create Oracle RAC Storage Docker image and container, if you plan to use NFS storage container for testing. See  [RAC Storage Container README.MD](../../../OracleRACStorageServer/README.md). **Note:** You can skip this step if you plan to use block devices for storage.
* Create Oracle Connection Manager on Docker image and container if the IPs you require for Oracle Grid Infrastructure and Oracle RAC are not available on your network. See [RAC Oracle Connection Manager README.MD](../../../OracleConnectionManager/README.md).
* Complete [Section 1 : Prerequsites for RAC on Docker](../../../OracleRealApplicationClusters/README.md).
* If you have not created the Oracle RAC Docker image, then you must complete [Section 2: Building Oracle RAC Database Docker Install Images](../../../OracleRealApplicationClusters/README.md).
work.

## Section 2 : Preparing Responsefile
* Create the following directory on the Docker hosts:
```
mkdir -p /opt/containers/common_scripts
```
* Copy the Oracle Grid infrastructure (`grid`) and Oracle Database (`database`) responsefile under `/opt/containers/common_scripts`.
    * You can create a responsefile   based on your environment. You can find the response file `grid.rsp` and `dbca.rsp` under the _<release-version>_ dir.
    * In this README.MD, we use prepopulated Oracle Grid Infrastructure and Oracle Database response files. Copy them under `/opt/containers/common_scripts`. For example: 
```
cp docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/samples/customracdb/_<release-version>_/grid_sample.rsp /opt/containers/common_scripts
cp docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/samples/customracdb/_<release-version>_/dbca_sample.rsp /opt/containers/common_scripts
```
**Notes**: 
* Using the sample responsefiles, you can create a two-node Oracle RAC deployment on containers. 
* Modify responsefiles based on your environment and pass them during container creation. Change or add the following based on your enviornment:
  * Public/private IP subnet
  * ASM disks for ASM storage
  * ASM Redundancy level
  * ASM failure disk groups
  * Passwords for different accounts

## Section 3 : Creating the Oracle RAC Container
All containers will share a host file for name resolution.  The shared hostfile must be available to all containers. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

```
# mkdir /opt/containers
# touch /opt/containers/rac_host_file
```

**Note:** Do not modify `/opt/containers/rac_host_file` from the Docker host. It will be managed from within the containers.

If you are using Oracle Connection Manager for accessing the Oracle RAC Database from outside the host, then you must add the following variable in the container creation command:

```
-e CMAN_HOSTNAME=(CMAN_HOSTNAME) -e CMAN_IP=(CMAN_IP)
```

**Note:** You must replace `CMAN_HOSTNAME` and `CMAN_IP` with the correct values based on your environment settings.

### Password management

Specify the secret volume for resetting the grid, oracle and database user passwords during node creation or node addition. The secret volume can be a shared volume among all the containers. For example:

```
mkdir /opt/.secrets/
openssl rand -hex 64 -out /opt/.secrets/pwd.key
```

Edit the `/opt/.secrets/common_os_pwdfile` and seed the password for the grid, oracle and database users. In this document, to simplify examples, we will use a common password for the grid, oracle and database users. Run the following command:

```
openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
rm -f /opt/.secrets/common_os_pwdfile
```

### Notes

* If you want to specify different passwords for grid, oracle, and database user accounts, then create three different files, encrypt them under `/opt/.secrets`, and pass the file name to the container using environment variables. For example, environment variables can be `ORACLE_PWD_FILE` for the oracle user, `GRID_PWD_FILE` for the grid user, and `DB_PWD_FILE` for the database user password.
* if you want to use a common password for oracle, grid and the database user, then you can assign the password file name to the environment variable `COMMON_OS_PWD_FILE`.

### Deploying Oracle RAC on Docker With Block Devices:

If you are using an NFS volume, then skip to the section that follows, "Deploying Oracle RAC on Docker with NFS Volume".

To deploy Oracle RAC on block devices, ensure that the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat this command for each shared block device. In this example, `/dev/xvde` is a shared Xen virtual block device.

Next, create the Docker container using the image. For the details of environment variables, see section 5. You can use the following example to create a container:

#### Create Racnode1
```
docker create -t -i \
--hostname racnode1 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--device=/dev/xvde:/dev/asm_disk1 \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.160 \
-e VIP_HOSTNAME=racnode1-vip \
-e PRIV_IP=192.168.17.150 \
-e PRIV_HOSTNAME=racnode1-priv \
-e PUBLIC_IP=172.16.1.150 \
-e PUBLIC_HOSTNAME=racnode1 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/dev/asm_disk1 \
-e ASM_DISCOVERY_DIR=/dev \
-e CRS_NODES="racnode1,racnode2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
-e OP_TYPE="INSTALL" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name racnode1 oracle/database-rac:19.3.0
```

#### Create Racnode2
```
docker create -t -i \
--hostname racnode2 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--device=/dev/xvde:/dev/asm_disk1 \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.161 \
-e VIP_HOSTNAME=racnode2-vip \
-e PRIV_IP=192.168.17.152 \
-e PRIV_HOSTNAME=racnode2-priv \
-e PUBLIC_IP=172.16.1.151 \
-e PUBLIC_HOSTNAME=racnode2 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/dev/asm_disk1 \
-e ASM_DISCOVERY_DIR=/dev \
-e CRS_NODES="racnode1,racnode2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name racnode2 oracle/database-rac:19.3.0
```
**Note:** Change the values for environment variables such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY to the correct values for your environment. Also, change the storage devices based on your environment.

### Deploying Oracle RAC on Docker with NFS Volume

Create Oracle RAC containers and use Oracle RAC storage containers for ASM devices:

#### Create Racnode1
```
docker create -t -i \
--hostname racnode1 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--volume racstorage:/oradata \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.160 \
-e VIP_HOSTNAME=racnode1-vip \
-e PRIV_IP=192.168.17.150 \
-e PRIV_HOSTNAME=racnode1-priv \
-e PUBLIC_IP=172.16.1.150 \
-e PUBLIC_HOSTNAME=racnode1 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
-e ASM_DISCOVERY_DIR=/oradata \
-e CRS_NODES="racnode1,racnode2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
-e OP_TYPE="INSTALL" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name racnode1 oracle/database-rac:19.3.0
```

#### Create Racnode2
```
docker create -t -i \
--hostname racnode2 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--volume racstorage:/oradata \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.161 \
-e VIP_HOSTNAME=racnode2-vip \
-e PRIV_IP=192.168.17.152 \
-e PRIV_HOSTNAME=racnode2-priv \
-e PUBLIC_IP=172.16.1.151 \
-e PUBLIC_HOSTNAME=racnode2 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
-e ASM_DISCOVERY_DIR=/oradata \
-e CRS_NODES="racnode1,racnode2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name racnode2 oracle/database-rac:19.3.0
```

**Notes:**

* Change the values for environment variables such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY to the correct values for your environment. Also, change the storage devices based on your environment.
* You must have created the `racstorage` volume before you create the Oracle RAC Container. For details about the environment variables, see section 6.

## Attach the network to containers
You must assign the Docker networks created in [section 1 of README.md](../../../OracleRealApplicationClusters/README.md) to containers. Complete each of the following tasks:

#### Attach the network to racnode1
```
# docker network disconnect bridge racnode1
# docker network connect rac_pub1_nw --ip 172.16.1.150 racnode1
# docker network connect rac_priv1_nw --ip 192.168.17.150  racnode1
```

#### Attach the network to racnode2
You must assign the Docker networks created in section 1 to containers. To do this, run the following commands:

```
# docker network disconnect bridge racnode2
# docker network connect rac_pub1_nw --ip 172.16.1.151 racnode2
# docker network connect rac_priv1_nw --ip 192.168.17.151  racnode2
```

## Start the containers
You must start the container. Run the following command:

#### Start Racnode2
```
# docker start racnode2
```
#### Reset the password 
Run this step only on `racnode2`.
```
docker exec racnode2 /bin/bash -c "sudo /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --pwd_key_file pwd.key"
```
#### Start Racnode1
```
# docker start racnode1
```

It can take approximately an hour to create and set up the two-node Oracle RAC cluster. To check the logs, use the following command from another terminal session:

```
# docker logs -f racnode1
```

At the completion of setting up the cluster, you should see a database creation success message similar to the following: 

```
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```
### Connect to the Oracle RAC container
To connect to the container, run the following command:

```
# docker exec -i -t racnode1 /bin/bash
```

If the installation fails for any reason, log in to container using the preceding command and check `/tmp/orod.log`. You can also review the Oracle Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation step, then check the database logs.

# Copyright
Copyright (c) 2014-2023 Oracle and/or its affiliates. All rights reserved.
