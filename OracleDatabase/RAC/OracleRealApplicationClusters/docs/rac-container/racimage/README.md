# Oracle RAC on Podman using Oracle RAC Image
===============================================================

Refer to the following instructions to set up Oracle RAC on Podman using an Oracle RAC Image for various scenarios.

- [Oracle RAC on Podman using Oracle RAC Image](#oracle-rac-on-podman-using-oracle-rac-image)
  - [Section 1: Prerequisites for Setting up Oracle RAC on Container using Oracle RAC Image](#section-1-prerequisites-for-setting-up-oracle-rac-database-on-containers-using-oracle-rac-image)
  - [Section 2: Deploying Two-node Oracle RAC on Podman using Oracle RAC Image](#section-2-deploying-two-node-oracle-rac-on-podman-using-oracle-rac-image)
    - [Section 2.1: Deploying Two-Node Oracle RAC on Podman Using Oracle RAC image Without Using Response Files](#section-21-deploying-two-node-oracle-rac-on-podman-using-an-oracle-rac-image-without-using-response-files)
      - [Section 2.1.1: Deploying With Block Devices](#section-211-deploying-with-block-devices)
      - [Section 2.1.2: Deploying with NFS Storage Devices](#section-212-deploying-with-nfs-storage-devices)
    - [Section 2.2: Deploying Two-node Oracle RAC on Podman Using Oracle RAC Image with User-defined response files](#section-22-deploying-two-node-oracle-rac-setup-on-podman-using-oracle-rac-image-using-user-defined-response-files)
      - [Section 2.2.1: Deploying With block devices](#section-221-deploying-with-blockdevices)
      - [Section 2.2.2: Deploying with NFS storage devices](#section-222-deploying-with-nfs-storage-devices)
  - [Section 3: Attach the Network to Containers](#section-3-attach-the-network-to-containers)
    - [Attach the network to racnodep1](#attach-the-network-to-racnodep1)
    - [Attach the network to racnodep2](#attach-the-network-to-racnodep2)
  - [Section 4: Start the Containers](#section-4-start-the-containers)
  - [Section 5: Validate the Oracle RAC Environment](#section-5-validate-the-oracle-rac-environment)
  - [Section 6: Connecting to Oracle RAC environment](#section-6-connecting-to-oracle-rac-environment)
  - [Section 7: Example of Node Addition to Oracle RAC Database Based on Oracle RAC Image with block devices](#section-7-example-of-node-addition-to-oracle-rac-database-based-on-oracle-rac-image-with-block-devices)
    - [Section 7.1: Example of node addition to Oracle RAC Database based on Oracle RAC image without Response File](#section-71-example-of-node-addition-to-oracle-rac-database-based-on-oracle-rac-image-without-response-file)
  - [Section 8: Example of Node Addition to Oracle RAC Database Based on Oracle RAC Image with NFS Storage Devices](#section-8-example-of-node-addition-to-oracle-rac-database-based-on-oracle-rac-image-with-nfs-storage-devices)
    - [Section 8.1: Example of node addition to Oracle RAC Database based on Oracle RAC Image without Response File](#section-81-example-of-node-addition-to-oracle-rac-database-based-on-oracle-rac-image-without-response-file)
  - [Environment Variables for Oracle RAC on Containers](#environment-variables-for-oracle-rac-on-containers)
  - [Cleanup](#cleanup)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Oracle RAC Setup on Podman using Oracle RAC Image

You can deploy multi-node Oracle RAC Database using Oracle RAC Database Container Images either on block devices or on NFS storage devices. You can also choose to deploy the images either by using Response Files that you define, or without using response files. All of these are demonstrated in detail in this document.

## Section 1: Prerequisites for Setting up Oracle RAC Database on containers using Oracle RAC image
**IMPORTANT:** Complete all of the steps specified in this section (customize for your environment) before you proceed to the next section. Completing prerequisite steps is a requirement for successful configuration.


* Complete the [Preparation Steps for running Oracle RAC Database in containers](../../../README.md#preparation-steps-for-running-oracle-rac-database-in-containers)
* If you are planning to use Oracle Connection Manager, then create an Oracle Connection Manager container image. See the [Oracle Connection Manager in Linux Containers](../../../../OracleConnectionManager/README.md)
* Ensure the Oracle RAC Database Container Image is present. You can either pull ru image from the Oracle Container Registry by following [Getting Oracle RAC Database Container Images](../../../README.md#getting-oracle-rac-database-container-images), or you can create the Oracle RAC Container Patched image by following [Building a Patched Oracle RAC Container Image](../../../README.md#building-a-patched-oracle-rac-container-image)
```bash
# podman images|grep database-rac
localhost/oracle/database-rac        21c          41239091d2ac  16 minutes ago  20.2 GB
```
* Configure the [Network Management](../../../README.md#network-management).
* Configure the [Password Management](../../../README.md#password-management).

## Section 2: Deploying Two-node Oracle RAC on Podman Using Oracle RAC Image

Use the following instructions to set up Oracle RAC Database on Podman using an Oracle RAC Database Container image for various scenarios, such as deploying with user-defined response files or deploying without user-defined response files. Oracle RAC Database setup can also be done either on block devices or on NFS storage devices.

### Section 2.1: Deploying Two-node Oracle RAC on Podman using an Oracle RAC image without using response files

To set up Oracle RAC Database on Podman using an Oracle RAC Database Container Image without providing response files, complete these steps.

#### Section 2.1.1: Deploying With Block Devices
##### Section 2.1.1.1: Prerequisites for setting up Oracle RAC with block devices

Ensure that you have created at least one Block Device with at least 50 Gb of storage space that can be accessed by two Oracle RAC Nodes, and can be shared between them. You can create more block devices in accordance with your requirements and pass those environment variables and devices to the `podman create` command as well as in the Oracle Grid Infrastructure (grid) response files.

**Note:** You can skip this step if you are planning to use NFS storage devices.

Ensure that the ASM devices do not have any existing file system. To clear any existing file system from the devices, use the following command:

```bash
dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000
```

Repeat this command on each shared block device. In this example command, `/dev/oracleoci/oraclevdd` is a shared KVM virtual block device.

##### Section 2.1.1.2: Create Oracle RAC Containers

Create the Oracle RAC containers using the Oracle RAC Database Container Image. For details about environment variables, see [Environment Variables Explained](#environment-variables-for-oracle-rac-on-containers)

You can use the following example to create a container on host `racnodep1`:

```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
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
--secret pwdsecret \
--secret keysecret \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e CRS_PRIVATE_IP1=192.168.17.170 \
-e CRS_PRIVATE_IP2=192.168.18.170 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e OP_TYPE=setuprac \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
localhost/oracle/database-rac:21c
```

To create another container with hostname `racnodep2`, use the following command:
```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e CRS_PRIVATE_IP1=192.168.17.171 \
-e CRS_PRIVATE_IP2=192.168.18.171 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e OP_TYPE=setuprac \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
localhost/oracle/database-rac:21c
```
#### Section 2.1.2: Deploying with NFS Storage Devices

##### Section 2.1.2.1: Prerequisites for setting up Oracle RAC with NFS storage devices

* Create an NFS Volume to be used for ASM Devices for Oracle RAC. See the section `Configuring NFS for Storage for Oracle RAC on Podman` in [Oracle Real Application Clusters Installation Guide for Podman](https://docs.oracle.com/cd/F39414_01/racpd/oracle-real-application-clusters-installation-guide-podman-oracle-linux-x86-64.pdf) for more details.

**Note:** You can skip this step if you are planning to use block devices for storage.
* Make sure the ASM NFS Storage devices do not have any existing file system.

##### Section 2.1.2.2: Create Oracle RAC Containers
Create the Oracle RAC Database containers using the Oracle RAC Database Container Image. For details about environment variables, see [Environment Variables Explained](#environment-variables-for-oracle-rac-on-containers). You can use the following example to create a container on host `racnodep1`:

```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e CRS_PRIVATE_IP1=192.168.17.170 \
-e CRS_PRIVATE_IP2=192.168.18.170 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--volume racstorage:/oradata \
-e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
-e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
-e OP_TYPE=setuprac \
-e ASM_ON_NAS=True \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
localhost/oracle/database-rac:21c
```

To create another container on host `racnodep2`, use the following command:
```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e CRS_PRIVATE_IP1=192.168.17.171 \
-e CRS_PRIVATE_IP2=192.168.18.171 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--volume racstorage:/oradata \
-e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
-e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
-e OP_TYPE=setuprac \
-e ASM_ON_NAS=True \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
localhost/oracle/database-rac:21c
```

### Section 2.2: Deploying Two-Node Oracle RAC Setup on Podman using Oracle RAC Image Using User Defined Response files

Follow the below instructions to setup Oracle RAC on Podman using Oracle RAC Image for using user-defined response files.

#### Section 2.2.1: Deploying With BlockDevices

##### Prerequisites for setting up Oracle RAC with User-Defined files
- On the shared folder between both RAC nodes, create a file named [grid_setup_21c.rsp](withresponsefiles/blockdevices/grid_setup_21c.rsp). In this example, we copy the file to `/scratch/common_scripts/podman/rac/grid_setup_21c.rsp`
- On the shared folder between both RAC nodes, create a file named [dbca_21c.rsp](withresponsefiles/dbca_21c.rsp). In this example, we copy the file to `/scratch/common_scripts/podman/rac/dbca_21c.rsp`
- If SELinux is enabled on the host machine then execute the following as well -
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/grid_setup_21c.rsp
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
  ```
  **Note:** Passwords defined in response files is going to be overwritten by passwords defined in `podman secret` due to security reasons of exposure of the password as plain text.
You can skip this step if you are not planning to use **User Defined Response Files for RAC**.

Create first Oracle RAC Container `racnodep1`:
```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--volume /scratch/common_scripts/podman/rac/grid_setup_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e GRID_RESPONSE_FILE=/tmp/grid_21c.rsp \
-e DBCA_RESPONSE_FILE=/tmp/dbca_21c.rsp \
-e CRS_PRIVATE_IP1=192.168.17.170 \
-e CRS_PRIVATE_IP2=192.168.18.170 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e OP_TYPE=setuprac \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
localhost/oracle/database-rac:21c
```

Create another Oracle RAC container `racnodep2`:
```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--volume /scratch/common_scripts/podman/rac/grid_setup_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
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
--secret pwdsecret \
--secret keysecret \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e GRID_RESPONSE_FILE=/tmp/grid_21c.rsp \
-e DBCA_RESPONSE_FILE=/tmp/dbca_21c.rsp \
-e CRS_PRIVATE_IP1=192.168.17.171 \
-e CRS_PRIVATE_IP2=192.168.18.171 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e OP_TYPE=setuprac \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
localhost/oracle/database-rac:21c
```
#### Section 2.2.2: Deploying with NFS storage devices

##### Prerequisites for setting up Oracle RAC with User-Defined Files
- Create a NFS Volume to be used for ASM Devices for Oracle RAC. See the section `Configuring NFS for Storage for Oracle RAC on Podman` in [Oracle Real Application Clusters Installation Guide for Podman](https://docs.oracle.com/cd/F39414_01/racpd/oracle-real-application-clusters-installation-guide-podman-oracle-linux-x86-64.pdf) for more details.

  **Note:** You can skip this step if you are planning to use block devices for storage.

- Make sure the ASM NFS Storage devices do not have any existing file system.
- On the shared folder between both Oracle RAC nodes, create the file name [grid_setup_21c.rsp](withresponsefiles/nfsdevices/grid_setup_21c.rsp). In this example, we copy the file to `/scratch/common_scripts/podman/rac/grid_setup_21c.rsp`
- On the shared folder between both RAC nodes, create a file named [dbca_21c.rsp](withresponsefiles/dbca_21c.rsp). In this example, we copy the file to `/scratch/common_scripts/podman/rac/dbca_21c.rsp`
- If the SELinux is enabled on the machine then also run the following the following as well-
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/grid_setup_21c.rsp
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
  restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
  ```
**Note:** You can skip this step if you are not planning to deploy with user-defined Response Files for Oracle RAC.

Create the first Oracle RAC Container. In this example, the hostname is `racnodep1`

```bash
podman create -t -i \
--hostname racnodep1 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--volume /scratch/common_scripts/podman/rac/grid_setup_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e GRID_RESPONSE_FILE=/tmp/grid_21c.rsp \
-e DBCA_RESPONSE_FILE=/tmp/dbca_21c.rsp \
-e CRS_PRIVATE_IP1=192.168.17.170 \
-e CRS_PRIVATE_IP2=192.168.18.170 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--volume racstorage:/oradata \
-e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
-e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
-e OP_TYPE=setuprac \
-e ASM_ON_NAS=True \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep1 \
localhost/oracle/database-rac:21c
```

Create another Oracle RAC container. In this example, the hostname is `racnodep2`
```bash
podman create -t -i \
--hostname racnodep2 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--volume /scratch/common_scripts/podman/rac/grid_setup_21c.rsp:/tmp/grid_21c.rsp \
--volume /scratch/common_scripts/podman/rac/dbca_21c.rsp:/tmp/dbca_21c.rsp \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e GRID_RESPONSE_FILE=/tmp/grid_21c.rsp \
-e DBCA_RESPONSE_FILE=/tmp/dbca_21c.rsp \
-e CRS_PRIVATE_IP1=192.168.17.171 \
-e CRS_PRIVATE_IP2=192.168.18.171 \
-e CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep1 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--volume racstorage:/oradata \
-e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
-e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
-e OP_TYPE=setuprac \
-e ASM_ON_NAS=True \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep2 \
localhost/oracle/database-rac:21c
```
**Note:**
- To use this example, change the environment variables based on your environment. See [Environment Variables for Oracle RAC on Containers](#environment-variables-for-oracle-rac-on-containers) for more details.
- In the example that follows, we use a podman bridge network with one public and two private networks. For this reason,`--sysctl 'net.ipv4.conf.eth1.rp_filter=2' --sysctl 'net.ipv4.conf.eth2.rp_filter=2` is required when we use two private networks. If your use case is different, then this sysctl configuration for the Podman Bridge can be ignored.
- If you are planning to place database files such as datafiles and archivelogs on different diskgroups, then you must pass these parameters: `DB_ASM_DEVICE_LIST`, `RECO_ASM_DEVICE_LIST`,`DB_DATA_FILE_DEST`, `DB_RECOVERY_FILE_DEST`. For more information, see [Environment Variables for Oracle RAC on Containers](#environment-variables-for-oracle-rac-on-containers).

## Section 3: Attach the Network to Containers

You must assign the podman networks created based on the preceding examples. Complete the following tasks:

### Attach the network to racnodep1

```bash
podman network disconnect podman racnodep1
podman network connect rac_pub1_nw --ip 10.0.20.170 racnodep1
podman network connect rac_priv1_nw --ip 192.168.17.170 racnodep1
podman network connect rac_priv2_nw --ip 192.168.18.170 racnodep1
```

### Attach the network to racnodep2

```bash
podman network disconnect podman racnodep2
podman network connect rac_pub1_nw --ip 10.0.20.171 racnodep2
podman network connect rac_priv1_nw --ip 192.168.17.171 racnodep2
podman network connect rac_priv2_nw --ip 192.168.18.171 racnodep2
```

## Section 4: Start the containers

You need to start the containers. Run the following commands:

```bash
podman start racnodep1
podman start racnodep2
```

It can take approximately 20 minutes or longer to create and set up a two-node Oracle RAC Database on Containers. To check the logs, use the following command from another terminal session:

```bash
podman exec racnodep1 /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

When the database configuration is complete, you should see a message, similar to the following, on the installing node i.e. `racnodep1` in this case:

```bash
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

Note:
- If you see any error related to files mounted on a container volume not detected in the podman logs, then make sure they are labeled correctly with the `container_file_t` context. You can use `ls -lZ <file_name>` to see the security context set on files.

  For example:
  ```bash
  semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
  restorecon -vF  /scratch/common_scripts/podman/rac/dbca_21c.rsp
  ls -lZ /scratch/common_scripts/podman/rac/dbca_21c.rsp
  ```

## Section 5: Validate the Oracle RAC Environment
To validate if the environment is healthy, run the following command:
```bash
podman ps -a

CONTAINER ID  IMAGE                                  COMMAND               CREATED         STATUS                   PORTS       NAMES
f1345fd4047b  localhost/oracle/rac-dnsserver:latest  /bin/sh -c exec $...  8 hours ago     Up 8 hours (healthy)                 rac-dnsserver
2f42e49758d1  localhost/oracle/database-rac:21c                         46 minutes ago  Up 37 minutes (healthy)                 racnodep1
a27fceea9fe6  localhost/oracle/database-rac:21c                         46 minutes ago  Up 37 minutes (healthy)                 racnodep2
```
**Note:**
- Look for `(healthy)` next to container names under the `STATUS` section.

## Section 6: Connecting to Oracle RAC Environment

**IMPORTANT:** Before you connnect to the environment, you must first successfully create an Oracle RAC Database as described in the preceding sections.  
See [Connecting to an Oracle RAC Database](../../CONNECTING.md) for instructions on how to connect to the Oracle RAC Database.

## Section 7: Example of Node Addition to Oracle RAC Database Based on Oracle RAC Image with Block Devices

### Section 7.1: Example of node addition to Oracle RAC Database based on Oracle RAC Image without Response File
The following is an example of how to add an additional node to the existing Oracle RAC two-node cluster using the Oracle RAC Database Container Image and without user-defined response files.

Create additional container for the new Oracle RAC Database Node. In this example, we create the container with hostname `racnodep3`:
```bash
podman create -t -i \
--hostname racnodep3 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e CRS_PRIVATE_IP1=192.168.17.172 \
-e CRS_PRIVATE_IP2=192.168.18.172 \
-e CRS_NODES="\"pubhost:racnodep3,viphost:racnodep3-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
--device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e OP_TYPE=racaddnode \
-e EXISTING_CLS_NODE="racnodep1,racnodep2" \
-e INSTALL_NODE=racnodep3 \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep3 \
localhost/oracle/database-rac:21c
```

Attach the networks to the new container and start the container:
```bash
podman network disconnect podman racnodep3
podman network connect rac_pub1_nw --ip 10.0.20.172 racnodep3
podman network connect rac_priv1_nw --ip 192.168.17.172  racnodep3
podman network connect rac_priv2_nw --ip 192.168.18.172  racnodep3
podman start racnodep3
```

Monitor the new container logs using below command:
```bash
podman exec racnodep3 /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```
When the Oracle RAC container has completed being set up, you should see a message similar to the following:
```bash
========================================================
Oracle Database ORCLCDB3 is up and running on racnodep3.
========================================================
```

## Section 8: Example of Node Addition to Oracle RAC Database Based on Oracle RAC Image with NFS Storage Devices

### Section 8.1: Example of node addition to Oracle RAC Database based on Oracle RAC Image without Response File
In the following example, we add an additional node to the existing Oracle RAC two-node cluster using the Oracle RAC Database Container Image without user-defined response files.

Create additional container for the new Oracle RAC Database Node. In this example, the hostname is `racnodep3`

```bash
podman create -t -i \
--hostname racnodep3 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
-e DNS_SERVERS="10.0.20.25" \
-e DB_SERVICE=service:soepdb \
-e CRS_PRIVATE_IP1=192.168.17.172 \
-e CRS_PRIVATE_IP2=192.168.18.172 \
-e CRS_NODES="\"pubhost:racnodep3,viphost:racnodep3-vip\"" \
-e SCAN_NAME=racnodepc1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
--volume racstorage:/oradata \
-e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
-e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
-e OP_TYPE=racaddnode \
-e EXISTING_CLS_NODE="racnodep1,racnodep2" \
-e INSTALL_NODE=racnodep3 \
-e ASM_ON_NAS=True \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep3 \
localhost/oracle/database-rac:21c
```

Attach the networks to the new container and start the container:
```bash
podman network disconnect podman racnodep3
podman network connect rac_pub1_nw --ip 10.0.20.172 racnodep3
podman network connect rac_priv1_nw --ip 192.168.17.172  racnodep3
podman network connect rac_priv2_nw --ip 192.168.18.172  racnodep3
podman start racnodep3
```
Monitor the new container logs using below command:
```bash
podman exec racnodep3 /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

When the Oracle RAC container has completed being set up, you should see a message similar to the following:
```bash
========================================================
Oracle Database ORCLCDB3 is up and running on racnodep3.
========================================================
```

## Environment Variables for Oracle RAC on Containers
For an explanation of all of the environment variables used with Oracle RAC on Podman, see [Environment Variables Explained for Oracle RAC on Podman](../../../docs/ENVIRONMENTVARIABLES.md). Change or set these environment variables as required for configurations info your environment.

## Cleanup
For instructions to connect to a cleanup Oracle RAC Database Container Environment, see [README](../../../docs/CLEANUP.md).

## Support

At the time of this release, Oracle RAC on Podman is supported for Oracle Linux 8.10 later. To review the current Linux support certifications, see [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under a UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.