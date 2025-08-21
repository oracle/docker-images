# Oracle Database on Oracle Restart

After you build your Oracle RAC Database Container Image, you can create use this image to deploy an Oracle database on Oracle Restart. Oracle Restart improves the availability of your Oracle Database. When you install Oracle Restart, various Oracle components can be automatically restarted after a hardware or software failure or whenever your database host computer restarts.
You can choose to deploy Oracle Database on Oracle Restart on block devices as demonstrated in the detail in this document.

Refer [Getting Oracle RAC Database Container Images](../../../OracleRealApplicationClusters/README.md#getting-oracle-rac-database-container-images) for getting Oracle RAC Container Images.

- [Oracle Database on Oracle Restart](#oracle-database-on-oracle-restart)
  - [Section 1: Prerequisites for Setting up Oracle Restart using Oracle RAC Container Image](#section-1-prerequisites-for-setting-up-oracle-cluster-using-oracle-rac-container-image)
  - [Section 2: Deploying Oracle Restart using Oracle RAC Image](#section-2-deploying-oracle-restart-using-oracle-rac-image)  
    - [Section 2.1.1: Deploying With Block Devices](#section-211-deploying-with-block-devices)
  - [Section 3: Attach the network to the container](#section-3-attach-the-network-to-the-container)
  - [Section 4: Start the container](#section-4-start-the-container)
  - [Section 5: Validate the Oracle Restart Environment](#section-5-validate-the-oracle-restart-environment)
  - [Section 6: Connecting to Oracle Restart Environment](#section-6-connecting-to-oracle-restart-environment)
  - [Section 7: Environment Variables Explained for Oracle Database Restart](#section-7-environment-variables-explained-for-oracle-database-restart)
  - [Cleanup](#cleanup)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)


## Section 1: Prerequisites for Setting up Oracle Cluster using Oracle RAC Container Image

Refer [Preparation Steps for running Oracle RAC Database in containers](../../../OracleRealApplicationClusters/README.md#preparation-steps-for-running-oracle-rac-database-in-containers) in order to prepare Podman Host machine. Once these pre-requisites are complete, you can proceed further.

Ensure that you have created at least one block device with at least 50 Gb of storage space that can be accessed by Oracle Restart. You can create more block devices in accordance with your requirements and pass those environment variables and devices to the podman create command.

Ensure that the ASM devices do not have any existing file system. To clear any existing file system from the devices, use the following command:
```bash
dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000
```
Repeat this command on each shared block device. In this example command, `/dev/oracleoci/oraclevdd` is a shared KVM virtual block device.

For Oracle Restart you do not need SCANs and VIPs in comparison to Oracle RAC Cluster. Environment variables that are needed to setup Oracle Restart areas explained in [Section 7: Environment Variables Explained for Oracle Database Restart](#section-7-environment-variables-explained-for-oracle-database-restart)

**NOTE:** In this example, the Oracle Restart is deployed with DNS server running in a podman container. Please refer [here](../../../OracleDNSServer/README.md) for the documentation.

### Export Environment Variables for Oracle Database Restart

```bash
#######COMMON VARIABLE######
export CRS_ASM_DEVICE_LIST=/dev/asm-disk1
export DB_ASM_DEVICE_LIST=/dev/asm-disk2
export RECO_ASM_DEVICE_LIST=/dev/asm-disk3
export DEVICE="--device=/dev/oracleoci/oraclevdd:/dev/asm-disk1"
export DOMAIN=example.info
export DNS_SERVER_IP=10.0.20.25
export IMAGE_NAME=container-registry.oracle.com/database/rac_ru:latest
export PUB_BRIDGE=rac_pub1_nw

######ORACLE RESTART Variable######
export GPCNODE=dbmc1
export GPCNODE_PUB_IP=10.0.20.195
```

## Section 2: Deploying Oracle Restart using Oracle RAC Image
### Section 2.1.1: Deploying With Block Devices

```bash
podman create -t -i \
--hostname ${GPCNODE} \
--dns-search ${DOMAIN} \
--dns ${DNS_SERVER_IP} \
--shm-size 4G \
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
--secret pwdsecret \
--secret keysecret \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
-e DNS_SERVERS=${DNS_SERVER_IP} \
-e DB_SERVICE="service:soepdb" \
-e PUBLIC_HOSTS_DOMAIN=${DOMAIN} \
-e DB_NAME=ORCLCDB \
-e ORACLE_PDB_NAME=ORCLPDB \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=${GPCNODE} \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
${DEVICE} \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e OP_TYPE=setuprac \
-e CRS_GPC="true" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name ${GPCNODE} \
${IMAGE_NAME}
```

## Section 3: Attach the network to the container

```bash
podman network disconnect podman ${GPCNODE}
podman network connect ${PUB_BRIDGE} --ip ${GPCNODE_PUB_IP} ${GPCNODE}
```

## Section 4: Start the container

Run the following commands to start the container:

```bash
podman start ${GPCNODE}
```

It can take approximately 20 minutes or longer to create and start the Oracle Restart setup . To check the logs, use the following command from another terminal session:

```bash
podman exec ${GPCNODE} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

When the database configuration is complete, you should see a message similar to the following:

```bash
###################################
ORACLE RAC DATABASE IS READY TO USE
###################################
```

## Section 5: Validate the Oracle Restart Environment
To validate if the environment is healthy, run the following command:
```bash
podman ps -a

CONTAINER ID  IMAGE                                                  COMMAND                CREATED      STATUS                PORTS       NAMES
131b86004040  localhost/oracle/rac-dnsserver:latest                 /bin/sh -c exec $...   3 days ago   Up 3 days (healthy)               rac-dnsserver
e010e1122e99  container-registry.oracle.com/database/rac_ru:latest   podman network di...  3 hours ago  Up 3 hours (healthy)              dbmc1
```
**Note:**
- Look for `(healthy)` next to container names under the `STATUS` section.

## Section 6: Connecting to Oracle Restart Environment

**IMPORTANT:** Before you connnect to the environment, you must first successfully create an Oracle Restart Environment as described in the preceding sections.

To connect to the container execute following command:
```bash
podman exec -i -t  ${GPCNODE} /bin/bash
```
### Validating Oracle Grid Infrastructure
Validate if Oracle Grid Infrastructure Stack is up and running from within container:
```bash
# Verify the status of Oracle Restart stack:
su - grid
#Verify the status of Oracle Clusterware stack:
[grid@dbmc1 ~]$ crsctl check has
CRS-4638: Oracle High Availability Services is online
[grid@dbmc1 ~]$ crsctl check css
CRS-4529: Cluster Synchronization Services is online
[grid@dbmc1 ~]$ crsctl check evm
CRS-4533: Event Manager is online
[grid@dbmc1 ~]$ crsctl stat res -t
--------------------------------------------------------------------------------
Name           Target  State        Server                   State details       
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.DATA.dg
               ONLINE  ONLINE       dbmc1                    STABLE
ora.LISTENER.lsnr
               ONLINE  ONLINE       dbmc1                    STABLE
ora.asm
               ONLINE  ONLINE       dbmc1                    Started,STABLE
ora.ons
               OFFLINE OFFLINE      dbmc1                    STABLE
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.cssd
      1        ONLINE  ONLINE       dbmc1                    STABLE
ora.diskmon
      1        OFFLINE OFFLINE                               STABLE
ora.evmd
      1        ONLINE  ONLINE       dbmc1                    STABLE
ora.orclcdb.db
      1        ONLINE  ONLINE       dbmc1                    Open,HOME=/u01/app/o
                                                             racle/product/21c/db
                                                             home_1,STABLE
ora.orclcdb.orclpdb.pdb
      1        ONLINE  ONLINE       dbmc1                    STABLE
--------------------------------------------------------------------------------

```
### Validating Oracle Restart Database
Validate Oracle Restart Database from within Container-
```bash
su - oracle

#Confirm the status of Oracle Database instances:
[oracle@dbmc1 ~]$ srvctl status database -d ORCLCDB
Database is running.
```


## Section 7: Environment Variables Explained for Oracle Database Restart
| Variable               | Default Value               | Description                                              |
|------------------------|-----------------------------|----------------------------------------------------------|
| CRS_ASM_DEVICE_LIST    | /dev/asm-disk1              | Path to the ASM device for CRS                           |
| DB_ASM_DEVICE_LIST     | /dev/asm-disk2              | Path to the ASM device for the database                  |
| RECO_ASM_DEVICE_LIST   | /dev/asm-disk3              | Path to the ASM device for recovery                      |
| DEVICE                 | --device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 | Device mapping for Docker container |
| DOMAIN                 | example.info                | Domain name for the environment                          |
| DNS_SERVER_IP          | 10.0.20.25                  | IP address of the DNS server                             |
| IMAGE_NAME             | container-registry.oracle.com/database/rac_ru:latest | Name of the Docker image for Oracle RAC                  |
| PUB_BRIDGE             | rac_pub1_nw                 | Name of the public bridge network interface              |
| GPCNODE                | dbmc1                       | Hostname of GPC Host                                  |
| GPCNODE_PUB_IP         | 10.0.20.195                 | Public IP address of RAC node 1                          |

## Cleanup
Execute below commands to cleanup Oracle Restart Container Environment-
```bash
podman rm -f ${GPCNODE}
podman network inspect rac_pub1_nw &> /dev/null && podman network rm rac_pub1_nw 
```

Cleanup ASM Disks:
```bash
dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000 
```

## Support

At the time of this release, Oracle Restart is supported on Podman for Oracle Linux 8.5 later. To review the current Linux support certifications, see [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under a UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.