Example of creating a custom Oracle RAC database
=============================================
Once you have built your Oracle RAC docker image you can create a Oracle RAC database with a custom configuration by passing the responsefile for Oracle Grid and Database to the container.

## Section 1 : Prerequisites for Custom RAC Database on Docker
**IMPORTANT :** You must execute all the steps specified in this section (customized for your environment) before you proceed to the next section.

* Create RAC Storage docker image and container, if you are planing to use NFS storage container for testing. Please refer [RAC Storage Container README.MD](../../../OracleRACStorageServer/README.md). You can skip this step if you are planing to use **block devices for storage**.
* Create Oracle Connection Manager on Docker image and container if the IPs are not available on user network.Please refer [RAC Oracle Connection Manager README.MD](../../../OracleConnectionManager/README.md).
* Execute the [Section 1 : Prerequsites for RAC on Docker](../../../OracleRealApplicationClusters/README.md).
* if you have not created the Oracle RAC docker image, execute the [Section 2: Building Oracle RAC Database Docker Install Images](../../../OracleRealApplicationClusters/README.md).
work.

## Section 2 : Preparing Responsefile
* Create a following directory on docker hosts:
```
mkdir -p /opt/containers/common_scripts
```
* Copy the Oracle grid and database responsefile under /opt/containers/common_scripts.
    * You can create responsefile, based on your environment. You can find the response file grid.rsp and dbca.rsp under <version> dir.
    * In this README.MD, we have used pre-populated Oracle grid and database responsefiles. Copy them under `/opt/containers/common_scripts`.
```
cp docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/samples/customracdb/<version/grid_sample.rsp /opt/containers/common_scripts
cp docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/samples/customracdb/<version>/dbca_sample.rsp /opt/containers/common_scripts
```
**Notes**: 
* Using the sample responsefiles, you will be able to create 2 node RAC on containers. 
* You need to modify responsefiles based on your environment and pass them during container creation. You need to change or add following based on your enviornment:
  * Public/private IP subnet
  * ASM disks for ASM storage
  * ASM Redundancy level
  * ASM failure disk groups
  * Passwords for different accounts

## Section 3 : Creating the RAC Container
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

### Password management

Specify the secret volume for resetting grid/oracle and database password during node creation or node addition. It can be shared volume among all the containers

```
mkdir /opt/.secrets/
openssl rand -hex 64 -out /opt/.secrets/pwd.key
```

Edit the `/opt/.secrets/common_os_pwdfile` and seed the password for grid/oracle and database. It will be a common password for grid/oracle and database user. Execute following command:

```
openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
rm -f /opt/.secrets/common_os_pwdfile
```

### Notes

* If you want to specify different password for all the accounts, create 3 different files and encrypt them under /opt/.secrets and pass the file name to the container using env variable. Env variables can be ORACLE_PWD_FILE for oracle user, GRID_PWD_FILE for grid user and DB_PWD_FILE for database password.
* if you want common password oracle, grid and db user, you can assign password file name to COMMON_OS_PWD_FILE env variable.

### Deploying RAC on Docker With Block Devices:

If you are using an NFS volume, skip to the section below "Deploying RAC on Docker with NFS Volume".

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

Now create the Docker container using the image. For the details of environment variables, please refer to section 5. You can use following example to create a container:

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
**Note:** Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.

### Deploying RAC on Docker with NFS Volume

Create RAC containers and utilize RAC storage containers for ASM devices:

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

* Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.
* You must have created the `racstorage` volume before the creation of RAC Container. For details about the env variables, please refer the section 6.

## Attach the network to containers
You need to assign the Docker networks created in s[ection 1 of README.md](../../../OracleRealApplicationClusters/README.md) to containers. Please execute following commands:

#### Attach the network to racnode1
```
# docker network disconnect bridge racnode1
# docker network connect rac_pub1_nw --ip 172.16.1.150 racnode1
# docker network connect rac_priv1_nw --ip 192.168.17.150  racnode1
```

#### Attach the network to racnode2
You need to assign the Docker networks created in section 1 to containers. Please execute following commands:

```
# docker network disconnect bridge racnode2
# docker network connect rac_pub1_nw --ip 172.16.1.151 racnode2
# docker network connect rac_priv1_nw --ip 192.168.17.151  racnode2
```

## Start the containers
You need to start the container. Please execute following command:

#### Start Racnode2
```
# docker start racnode2
```
#### Reset the password 
Execute this step only on racnode2.
```
docker exec racnode2 /bin/bash -c "sudo /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --pwd_key_file pwd.key"
```
#### Start Racnode1
```
# docker start racnode1
```

It can take at least 60 minutes or longer to create and setup 2 node RAC cluster. To check the logs, use following command from another terminal session:

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

# Copyright
Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
