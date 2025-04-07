# Oracle RAC on Podman using Slim Image
===============================================================

Refer below instructions for the setup of Oracle RAC on Podman using Slim Image for various scenarios.

- [Oracle RAC on Podman using Slim Image](#oracle-rac-on-podman-using-slim-image)
  - [Section 1: Prerequisites for Setting up Oracle RAC on Container Using Slim Image](#section-1-prerequisites-for-setting-up-oracle-rac-on-container-using-slim-image)
  - [Section 2: Deploying 2 Node Oracle RAC Setup on Podman Using Slim Image](#section-2-deploying-2-node-oracle-rac-setup-on-podman-using-slim-image)
    - [Section 2.1: Deploying 2 Node Oracle RAC Setup on Podman Using Slim Image Without using response files](#section-21-deploying-2-node-oracle-rac-setup-on-podman-using-slim-image-without-using-response-files)
      - [Section 2.1.1: Deploying With BlockDevices](#section-211-deploying-with-blockdevices)
      - [Section 2.1.2: Deploying with NFS Storage Devices](#section-212-deploying-with-nfs-storage-devices)
    - [Section 2.2: Deploying 2 Node Oracle RAC Setup on Podman Using Slim Image Using User Defined response files](#section-22-deploying-2-node-oracle-rac-setup-on-podman-using-slim-image-using-user-defined-response-files)
      - [Section 2.2.1: Deploying with BlockDevices](#section-221-deploying-with-blockdevices)
      - [Section 2.2.2: Deploying with NFS Storage Devices](#section-222-deploying-with-nfs-storage-devices)
  - [Section 3: Attach the Network to Containers](#section-3-attach-the-network-to-containers)
    - [Attach the Network to racnodep1](#attach-the-network-to-racnodep1)
    - [Attach the Network to racnodep2](#attach-the-network-to-racnodep2)
  - [Section 4: Start the Containers](#section-4-start-the-containers)
  - [Section 5: Validation Oracle RAC Environment](#section-5-validating-oracle-rac-environment)
  - [Section 6: Connecting to Oracle RAC Environment](#section-6-connecting-to-oracle-rac-environment)
  - [Section 7: Sample of Addition of Nodes to Oracle RAC Containers based on Slim Image](#section-7-sample-of-addition-of-nodes-to-oracle-rac-containers-based-on-slim-image)
    - [Section 7.1: Sample of Addition of Nodes to Oracle RAC Containers based on Slim Image Without Response File](#section-71-sample-of-addition-of-nodes-to-oracle-rac-containers-based-on-slim-image-without-response-file)
  - [Section 8: Sample of Addition of Nodes to Oracle RAC Containers based on Oracle RAC Slim Image with NFS Storage Devices](#section-8-sample-of-addition-of-nodes-to-oracle-rac-containers-based-on-oracle-rac-slim-image-with-nfs-storage-devices)
    - [Section 8.1: Sample of Addition of Nodes to Oracle RAC Containers based on Oracle RAC Image Without Response File](#section-81-sample-of-addition-of-nodes-to-oracle-rac-containers-based-on-oracle-rac-image-without-response-file)
  - [Section 9: Environment Variables for Oracle RAC on Containers](#section-9-environment-variables-for-oracle-rac-on-containers)
  - [Cleanup](#cleanup)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Oracle RAC Setup on Podman using Slim Image

Users can deploy multi-node Oracle RAC Database Setup using Oracle RAC Database Container Slim Image either on Block Devices or NFS storage Devices and with or without using User Defined Response Files. All of these are demonstrated in detail in this document.

## Section 1: Prerequisites for Setting up Oracle RAC on Container using Slim Image
**IMPORTANT:** Execute all the steps specified in this section (customize for your environment) before you proceed to the next section. Completing prerequisite steps is a requirement for successful configuration.

* Complete the [Preparation Steps for running Oracle RAC Database in containers](../../../README.md#preparation-steps-for-running-oracle-rac-database-in-containers)
* If you are planning to use Oracle Connection Manager, then create an Oracle Connection Manager container image. See the [Oracle Connection Manager in Linux Containers](../../../../OracleConnectionManager/README.md)
* Make sure the Oracle RAC Database Container Slim Image is present as shown below.  If you have not created the Oracle RAC Database Container image, execute the [Building Oracle RAC Database Container Slim Image](../../../README.md#building-oracle-rac-database-container-slim-image)
  ```bash
  # podman images|grep database-rac
  localhost/oracle/database-rac                         21c-slim  bf6ae21ccd5a  8 hours ago    517 MB
  ```
* Configure the [Network Management](../../../README.md#network-management).
* Configure the [Password Management](../../../README.md#password-management).

* Prepare Hosts with empty paths for 2 nodes similar to below, these are going to be mounted to Oracle RAC Containers for installing Oracle RAC Software binaries later during container creation-
  ```bash
  mkdir -p /scratch/rac/cluster01/node1
  rm -rf /scratch/rac/cluster01/node1/*

  mkdir -p /scratch/rac/cluster01/node2
  rm -rf /scratch/rac/cluster01/node2/*
  ```

* Make sure the downloaded Oracle RAC software location is staged & available for both RAC nodes. In the below example, we have staged Oracle RAC software at location ```/scratch/software/21c/goldimages```
  ```bash
  ls /scratch/software/21c/goldimages
  LINUX.X64_213000_db_home.zip  LINUX.X64_213000_grid_home.zip
  ```
* If SELinux is enabled on the host machine then execute the following as well-
  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/cluster01/node1
  restorecon -v /scratch/rac/cluster01/node1
  semanage fcontext -a -t container_file_t /scratch/rac/cluster01/node2
  restorecon -v /scratch/rac/cluster01/node2
  semanage fcontext -a -t container_file_t /scratch/software/21c/goldimages/LINUX.X64_213000_grid_home.zip
  restorecon -v /scratch/software/21c/goldimages/LINUX.X64_213000_grid_home.zip
  semanage fcontext -a -t container_file_t /scratch/software/21c/goldimages/LINUX.X64_213000_db_home.zip
  restorecon -v /scratch/software/21c/goldimages/LINUX.X64_213000_db_home.zip
  ```

## Section 2: Deploying 2 Node Oracle RAC Setup on Podman using Slim Image

Follow the below instructions to setup Oracle RAC Database on Podman using Slim Image for various scenarios like using user-defined response files or not using the it. Oracle RAC setup can also be done either on block devices or on NFS storage devices.

### Section 2.1: Deploying 2 Node Oracle RAC Setup on Podman using Slim Image Without using response files

Follow the below instructions to setup Oracle RAC on Podman using Slim Image without providing response files.

#### Section 2.1.1: Deploying With BlockDevices
##### Section 2.1.1.1: Prerequisites for setting up Oracle RAC with Block Devices

- Make sure you have created atleast 1 Block Device with 50Gb storage space which can be accessed by 2 RAC Nodes and shared between them. You can create more block devices as per your requirements and pass the same to environment variables and devices to `podman create` command as well as in grid response files (if using the same). You can skip this step if you are planning to use **NFS storage devices**.

  Make sure the ASM devices do not have any existing file system. To clear any existing file system from the devices, use the following command:
  ```bash
  dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000
  ```
  Repeat the cleanup disk for each shared block device. In the preceding example, `/dev/oracleoci/oraclevdd` is a shared KVM virtual block device.

- In this example, we are going to use environment variables passed in a file called [envfile_racnodep1](withoutresponsefiles/blockdevices/envfile_racnodep1) & [envfile_racnodep2](withoutresponsefiles/blockdevices/envfile_racnodep2) and mounted to rac node containers.
In this example, files `envfile_racnodep1` and `envfile_racnodep2` are placed under `/scratch/common_scripts/podman/rac` on container host.

- If SELinux is enabled on machine then execute the following as well-
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep1
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep1
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep2
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep2
  ```

###### Section 2.1.1.2: Create Oracle RAC Containers
Now create the Oracle RAC containers using the Oracle RAC Database Container Slim Image. For the details of environment variables, refer to [Environment Variables Explained](#section-9-environment-variables-for-oracle-rac-on-containers)

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep1` and set the variables based on your environment.

You can use the following example to create a container on host `racnodep1`:
```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--volume /scratch/rac/cluster01/node1:/u01 \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep1:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--volume /scratch:/scratch \
--secret pwdsecret \
--secret keysecret \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
 localhost/oracle/database-rac:21c-slim
 ```
 **Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep2` and set the variables based on your enviornment.

Create another Oracle RAC Container -
 ```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/rac/cluster01/node2:/u01 \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep2:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--volume /scratch:/scratch \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
 localhost/oracle/database-rac:21c-slim
 ```

#### Section 2.1.2: Deploying with NFS Storage Devices
##### Section 2.1.2.1: Prerequisites for setting up Oracle RAC with NFS Storage Devices
* Create a NFS Volume to be used for ASM Devices for Oracle RAC. See [Configuring NFS for Storage for Oracle RAC on Podman](https://review.us.oracle.com/review2/Review.html#reviewId=467473;scope=document;status=open,fixed;documentId=4229197) for more details. **Note:** You can skip this step if you are planning to use block devices for storage.

* Make sure the ASM NFS Storage devices do not have any existing file system.

* In this example we are going to use environment variables passed in a file called [envfile_racnodep1](withoutresponsefiles/nfsdevices/envfile_racnodep1) & [envfile_racnodep2](withoutresponsefiles/nfsdevices/envfile_racnodep2) and mounted to rac node containers. In this example, we are creating files under the `/scratch/common_scripts/podman/rac` path.

* If SELinux is enabled on the host machine, then execute the following as well -
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep1
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep1
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep2
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep2
  ```
###### Section 2.1.2.2: Create Oracle RAC Containers
Now create the Oracle RAC containers using the image. For the details of environment variables, refer to [Environment Variables Explained](#section-9-environment-variables-for-oracle-rac-on-containers)
**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep1` and set the variables based on your environment.

You can use the following example to create the first Oracle RAC container:
```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/rac/cluster01/node1:/u01 \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep1:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--volume /scratch:/scratch \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--volume racstorage:/oradata \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
 localhost/oracle/database-rac:21c-slim
 ```

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep2` and set the variables based on your enviornment.

Create another Oracle RAC Container -

 ```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/rac/cluster01/node2:/u01 \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep2:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--volume /scratch:/scratch \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--volume racstorage:/oradata \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
 localhost/oracle/database-rac:21c-slim
 ```

### Section 2.2: Deploying 2 Node Oracle RAC Setup on Podman using Slim Image Using User Defined response files
#### Section 2.2.1: Deploying With BlockDevices
##### Section 2.1.1.1: Prerequisites for setup Oracle RAC using User-Defined Files with Block Devices
- On the shared folder between both RAC nodes, copy file [grid_setup_new_21c.rsp](withresponsefiles/blockdevices/grid_setup_new_21c.rsp) in `/scratch/common_scripts/podman/rac/`.
- Also, prepare a database response file similar to this [dbca_21c.rsp](withresponsefiles/dbca_21c.rsp).
- In the below example, we have captured all environment variables passed to the container in a separate envfile and mounted the same to both RAC nodes. Create envfile [envfile_racnodep1](withresponsefiles/blockdevices/envfile_racnodep1) and [envfile_racnode2](withresponsefiles/blockdevices/envfile_racnodep2) for both nodes in directory `/scratch/common_scripts/podman/rac/`
- If SELinux is enabled on the host machine then execute the following as well-
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep1
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep1
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep2
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep2
  ```
  Note: Passwords defined in response files is going to be overwritten by passwords defined in `podman secret` due to security reasons of exposure of  the password as plain text.
You can skip this step if you are planning not to use **User Defined Response Files for RAC**.

Follow the below instructions to setup Oracle RAC on Podman using Slim Image for using user-defined response files.


You can use the following example to create the first Oracle RAC container:

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep1` and set the variables based on your enviornment.

```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--volume /scratch/rac/cluster01/node1:/u01 \
--volume /scratch:/scratch \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep1:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
localhost/oracle/database-rac:21c-slim
  ```

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep2` and set the variables based on your enviornment.

To create another container, use the following command:

```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--volume /scratch/rac/cluster01/node2:/u01 \
--volume /scratch:/scratch \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep2:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
 localhost/oracle/database-rac:21c-slim
  ```
#### Section 2.2.2: Deploying with NFS Storage Devices
##### Section 2.2.2.1: Prerequisites for setup Oracle RAC using User Defined Files with NFS Devices
- Create a NFS Volume to be used for ASM Devices for Oracle RAC. See [Configuring NFS for Storage for Oracle RAC on Podman](https://review.us.oracle.com/review2/Review.html#reviewId=467473;scope=document;status=open,fixed;documentId=4229197) for more details. **Note:** You can skip this step if you are planning to use block devices for storage.

- Make sure the ASM NFS Storage devices do not have any existing file system.
- On the shared folder between both RAC nodes, create file name [grid_setup_new_21c.rsp](withresponsefiles/nfsdevices/grid_setup_new_21c.rsp) similar as below inside directory named `/scratch/common_scripts/podman/rac/`.
- Also, prepare a database response file similar to this [dbca_21c.rsp](withresponsefiles/dbca_21c.rsp) inside directory named `/scratch/common_scripts/podman/rac/`.
- In the below example, we have captured all environment variables passed to the container in a separate envfile and mounted the same to both RAC nodes.

  Create envfile [envfile_racnodep1](withresponsefiles/nfsdevices/envfile_racnodep1) and [envfile_racnode2](withresponsefiles/nfsdevices/envfile_racnodep2) for both nodes in directory `/scratch/common_scripts/podman/rac/`.
- If the SELinux is enabled on machine then execute the following as well -
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep1
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep1
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/envfile_racnodep2
  restorecon -v /scratch/common_scripts/podman/rac/envfile_racnodep2
  ```
You can skip this step if you are planning not to use **User Defined Response Files for RAC**.

Follow the below instructions to setup Oracle RAC on Podman using Slim Image for using user-defined response files.

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep1` and set the variables based on your enviornment.

You can use the following example to create the first Oracle RAC container:
```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--volume /scratch/rac/cluster01/node1:/u01 \
--volume /scratch:/scratch \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep1:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--volume racstorage:/oradata \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
localhost/oracle/database-rac:21c-slim
  ```

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep1` and set the variables based on your enviornment.

To create another container, use the following command:

```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--secret pwdsecret \
--secret keysecret \
--volume /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--volume /scratch/rac/cluster01/node2:/u01 \
--volume /scratch:/scratch \
--volume /scratch/common_scripts/podman/rac/envfile_racnodep2:/etc/rac_env_vars/envfile \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--volume racstorage:/oradata \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
 localhost/oracle/database-rac:21c-slim
  ```
**Note:**
- Change environment variables based on your environment. Refer [Section 8: Environment Variables for Oracle RAC on Containers](#section-9-environment-variables-for-oracle-rac-on-containers) for more details.
- Below example uses, a podman bridge network with one public and two private networks, hence`--sysctl 'net.ipv4.conf.eth1.rp_filter=2' --sysctl 'net.ipv4.conf.eth2.rp_filter=2` is required when we use two private networks, else these can be ignored.
- If you are planning to place database files such as datafiles and archivelogs on different diskgroups, you need to pass these parameters- `DB_ASM_DEVICE_LIST`,`RECO_ASM_DEVICE_LIST`,`DB_DATA_FILE_DEST`, `DB_RECOVERY_FILE_DEST`. Refer [Section 8: Environment Variables for Oracle RAC on Containers](#section-9-environment-variables-for-oracle-rac-on-containers) for more details.

## Section 3: Attach the network to containers

You need to assign the podman networks created based on the above sections. Execute the following commands:

### Attach the network to racnodep1

```bash
podman network disconnect podman racnodep1
podman network connect rac_pub1_nw --ip 10.0.20.170 racnodep1
podman network connect rac_priv1_nw --ip 192.168.17.170  racnodep1
podman network connect rac_priv2_nw --ip 192.168.18.170  racnodep1
```
### Attach the network to racnodep2

```bash
podman network disconnect podman racnodep2
podman network connect rac_pub1_nw --ip 10.0.20.171 racnodep2
podman network connect rac_priv1_nw --ip 192.168.17.171  racnodep2
podman network connect rac_priv2_nw --ip 192.168.18.171  racnodep2
```
## Section 4: Start the containers

You need to start the container. Execute the following command:

```bash
podman start racnodep1
podman start racnodep2
```

It can take at least 20 minutes or longer to create and setup 2 node RAC primary and standby setup. To check the logs, use the following command from another terminal session:

```bash
podman exec racnodep1 /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

You should see the database creation success message at the end:
```bash
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

Note:
- If you see any error related to files mounted on a container volume not detected in the podman logs, then make sure they are labeled correctly with the `container_file_t` context. You can use `ls -lZ <file_name>` to see the security context set on files.
  For example-
    ```bash
    semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
    restorecon -vF  /scratch/common_scripts/podman/rac/dbca_21c.rsp
    ls -lZ /scratch/common_scripts/podman/rac/dbca_21c.rsp
`   ```

## Section 5: Validating Oracle RAC Environment
You can validate if the environment is healthy by running the below command-
```bash
podman ps -a

CONTAINER ID  IMAGE                                  COMMAND               CREATED         STATUS                   PORTS       NAMES
f1345fd4047b  localhost/oracle/rac-dnsserver:latest  /bin/sh -c exec $...  8 hours ago     Up 8 hours (healthy)                 rac-dnsserver
2f42e49758d1  localhost/oracle/database-rac:21c-slim                         46 minutes ago  Up 37 minutes (healthy)              racnodep1
a27fceea9fe6  localhost/oracle/database-rac:21c-slim                         46 minutes ago  Up 37 minutes (healthy)              racnodep2
```
Note:
- Look for `(healthy)` next to container names under the `STATUS` section.

## Section 6: Connecting to Oracle RAC Environment

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC cluster using the preceding sections.
Refer to [README](./docs/CONNECTING.md) for instructions on how to connect to Oracle RAC Database.

## Section 7: Sample of Addition of Nodes to Oracle RAC Containers based on Slim Image
### Section 7.1: Sample of Addition of Nodes to Oracle RAC Containers based on Slim Image Without Response File
Below is the example of adding 1 more node to the existing Oracle RAC 2 node cluster using Slim image and without user-defined files -
- Create envfile [envfile_racnodep3](withoutresponsefiles/blockdevices/envfile_racnodep3) for additional node and keep it here `/scratch/common_scripts/podman/rac/envfile_racnodep3`

**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep3` and set the variables based on your enviornment.

- Prepare Folder for additional node-
  ```bash
  mkdir -p /scratch/rac/cluster01/node3
  rm -rf /scratch/rac/cluster01/node3/*
  ```  
- Create additional Oracle RAC Container-
  ```bash
  podman create -t -i \
  --hostname racnodep3 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --secret pwdsecret \
  --secret keysecret \
  --volume /scratch/rac/cluster01/node3:/u01 \
  --volume /scratch/common_scripts/podman/rac/envfile_racnodep3:/etc/rac_env_vars/envfile \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --volume /scratch:/scratch \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
  --device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep3 \
  localhost/oracle/database-rac:21c-slim

  podman network disconnect podman racnodep3
  podman network connect rac_pub1_nw --ip 10.0.20.172 racnodep3
  podman network connect rac_priv1_nw --ip 192.168.17.172  racnodep3
  podman network connect rac_priv2_nw --ip 192.168.18.172  racnodep3
  podman start racnodep3
  podman exec racnodep3 /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
  ```
  Successful message for addition of nodes-
  ```bash
  ========================================================
  Oracle Database ORCLCDB3 is up and running on racnodep3.
  ========================================================
  ```

## Section 8: Sample of Addition of Nodes to Oracle RAC Containers based on Oracle RAC Slim Image with NFS Storage Devices

### Section 8.1: Sample of Addition of Nodes to Oracle RAC Containers based on Oracle RAC Image Without Response File
Below is an example of adding one more node to the existing Oracle RAC 2 node cluster using the Oracle RAC image and without user-defined files.
**Note**: Before creating the containers, you need to make sure you have edited the file `/scratch/common_scripts/podman/rac/envfile_racnodep3` and set the variables based on your enviornment.

- Prepare directory for additional node-
    ```bash
    mkdir -p /scratch/rac/cluster01/node3
    rm -rf /scratch/rac/cluster01/node3/*
    ```
- Create additional Oracle RAC Container -
  ```bash
  podman create -t -i \
  --hostname racnodep3 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --secret pwdsecret \
  --secret keysecret \
  --volume /scratch/rac/cluster01/node3:/u01 \
  --volume /scratch/common_scripts/podman/rac/envfile_racnodep3:/etc/rac_env_vars/envfile \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --volume /scratch:/scratch \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --volume racstorage:/oradata \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep3 \
  localhost/oracle/database-rac:21c-slim

  podman network disconnect podman racnodep3
  podman network connect rac_pub1_nw --ip 10.0.20.172 racnodep3
  podman network connect rac_priv1_nw --ip 192.168.17.172  racnodep3
  podman network connect rac_priv2_nw --ip 192.168.18.172  racnodep3
  podman start racnodep3
  podman exec racnodep3 /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"

  ========================================================
  Oracle Database ORCLCDB3 is up and running on racnodep3.
  ========================================================
  ```

## Section 9: Environment Variables for Oracle RAC on Containers
Refer to [Environment Variables Explained for Oracle RAC on Podman Compose](../../../docs/ENVIRONMENTVARIABLES.md) for the explanation of all the environment variables related to Oracle RAC on Podman Compose. Change or Set these environment variables as per your environment.

## Cleanup
Refer to [README](../../../docs/CLEANUP.md) for instructions on how to connect to a cleanup Oracle RAC Database Container Environment.

## Support

At the time of this release, Oracle RAC on Podman is supported for Oracle Linux 8.10 later. To see current Linux support certifications, refer [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under a UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.