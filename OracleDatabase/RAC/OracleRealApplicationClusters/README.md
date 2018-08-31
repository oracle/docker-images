# Oracle RAC Database on Docker
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Grid/RAC Database Online Documentation](http://docs.oracle.com/en/database/).

## How to build and run
This project offers sample Docker files for Oracle Grid Infrastructure and Real Application Cluster Database:

 * Oracle Database 12c Release 2 Grid Infrastructure (12.2.0.1.0) for Linux x86-64
 * Oracle Database 12c Release 2 (12.2.0.1.0) Enterprise Edition for Linux x86-64

**IMPORTANT:** You can build and run RAC containers on a single host or multiple hosts. To access the RAC DB on your network either use the Docker MACVLAN driver or use Oracle Connection Manager. To Run RAC containers on Multi-Host, you must use the Docker MACVLAN driver and your network must be reachable on all the nodes for RAC containers.

## For complete RAC setup, please execute the steps in the sections below as per your environment:

Section 1   : Pre-requisites for RAC on Docker

Section 2   : Building the Oracle RAC Database Docker Install Images

Section 3   : Creating the Docker GI and RAC container

Section 4   : Adding RAC Node using Docker container

Section 5   : Connecting to RAC Database

Section 6   : Env Variables for RAC 1st Node container

Section 7   : Env Variables for RAC 2nd Node container

Section 8   : Support

Section 9   : License

Section 10  : Copyright


### Section 1 : Pre-requsites for RAC on Docker
**IMPORTANT:** You must make the changes specified in this section (customized for your environment) before you proceed to the next section.

* Each container that you will deploy as part of your cluster must satisfy the minimum hardware requirements of the RAC and GI software. An Oracle RAC database is a shared everything database. All data files, control files, redo log files, and the server parameter file (SPFILE) used by the Oracle RAC database must reside on shared storage that is accessible by all the Oracle RAC database instances. For details, please refer to [Installing Oracle Grid Infrastructure Guide](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/cwlin/toc.htm) and [Installing Oracle RAC Guide](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/rilin/toc.htm).You must provide block devices shared across the hosts.  If you don't have shared block storage, you can, for testing purpose only, use the Oracle rac-storage-server image to deploy a docker container providing NFS-based sharable storage.

**Note:** If you are planning to use the RAC storage Container for shared storage, you must create the RAC Storage Container before proceeding to the next step.

* Allocate block devices of at least 50GB for OCR/Voting and databases files. You can refer Oracle 12.2 GRID and database install guides for details on recommended number of devices and total storage size.

* You need to plan your private and public network for containers before you start installation. You can create a network bridge on every host so containers running within that host can communicate with each other.  For example, create rac_pub1_nw for the public network (172.15.1.0/24) and rac_priv1_nw (192.168.17.0/24) for a private network. You can use any network subnet for testing. However, in this document we reference the public network on 172.15.1.0/24 and the private network on 192.168.17.0/24.

         docker network create --driver=bridge --subnet=172.15.1.0/24 rac_pub1_nw

         docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw

**Note:** You must run RAC on Docker on multi-host using MACVLAN Docker driver.

* If you are running RAC on Docker on multi-host, you can create network bridge using MACVLAN docker driver using following commands:

                docker network create -d macvlan --subnet=172.15.1.0/24 --gateway=172.15.1.1 -o parent=eth0 rac_pub1_nw

                docker network create -d macvlan --subnet=192.168.17.0/24 --gateway=192.168.17.1 -o parent=eth1 rac_priv1_nw

**Note:** To create a Macvlan network which bridges with a given physical network interface, use --driver macvlan with the docker network create command. You also need to specify the parent, which is the interface the traffic will physically go through on the Docker host. You can change --subnet and --gateway based on your environment.

* If the docker bridge network is not available outside your host, you can use the Oracle Connection Manager (CMAN) image to access the RAC Database from outside the host.

* RAC needs to run certain processes in real time mode. To run processes inside a container in real time mode, you need to make changes in your docker configuration files. Please update OPTIONS value in `/etc/sysconfig/docker` to following:

        OPTIONS='--selinux-enabled --cpu-rt-runtime=950000'

* Once you have editied the /etc/sysconfig/docker, execute following commands:

         systemctl daemon-reload

         systemctl stop docker

         systemctl start docker

* SELINUX must be in disabled or permissive mode.

* For Oracle RAC, certain kernel parameter need to be set. Please refer to [Installing Oracle Grid Infrastructure Guide](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/cwlin/toc.htm) and [Installing Oracle RAC Guide](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/rilin/toc.htm). Docker containers share certain kernel parameters with host. You need to set following parameters at host level in /etc/sysctl.conf:

          fs.file-max = 6815744

          net.core.rmem_max = 4194304

          net.core.rmem_default = 262144

          net.core.wmem_max = 1048576

          net.core.wmem_default = 262144

          net.core.rmem_default = 262144

	      fs.aio-max-nr=1048576

* Execute following once the file is modified.

          sysctl -a

          sysctl -p

* Verify you have enough memory and cpu resources available for container. Each container for RAC requires 8GB memory and 16GB swap.  For details, Please refer to   [Installing Oracle Grid Infrastructure Guide](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/cwlin/toc.htm) and [Installing Oracle RAC Guide](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/rilin/toc.htm).

* The Oracle RAC dockerfiles, does not contain any Oracle Software Binaries.  Download the following software from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) and stage them under `dockerfiles/<version>` folder.

   * Oracle Database 12c Release 2 Grid Infrastructure (12.2.0.1.0) for Linux x86-64
   * Oracle Database 12c Release 2 (12.2.0.1.0) Enterprise Edition for Linux x86-64

* FOLLOWING FREELY AVAILABLE PATCH IS REQUIRED FOR THIS IMAGE TO WORK.
Download following patch from OTN and stage it on your machine.
   * Patch# p27383741_122010_Linux-x86-64.zip
You can download this patch from [Oracle Technology Network](http://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html). Stage it under `dockerfiles/<version>` folder.

### Building Oracle RAC Database Docker Install Images
**IMPORTANT:** This section assumes that you have gone through the all the pre-requisites in Section 1 and executed all the steps based on your environment. Do not uncompress the binaries and patches.

**Note:** If you are behind a proxy, you need to set the http_proxy or https_proxy environment variable based on your environment before building the image.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

* The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.Go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

        ./buildDockerImage.sh -v (Software Version)

        e.g., ./buildDockerImage.sh -v 12.2.0.1

        For detailed usage of command, please execute following command:
        ./buildDockerImage.sh -h

**IMPORTANT:** The resulting images will contain the Oracle Grid Infrastructure Binaries and Oracle RAC Database binaries.

### Section 3: Creating the Docker GI and RAC Container
* All containers will share a host file for name resolution.  The shared hostfile must be available to all container. Create the shared host file (if it doesn't exist) at /opt/containers/rac_host_file
        Example:

          mkdir /opt/containers

          touch /opt/containers/rac_host_file

**Note:** Do not modify rac_host_file from docker host. It will be setup inside the container.

* If you are using the Oracle Connection Manager image for accessing the ORACLE RAC DB from outside the host, you need to add following variable in the container creation command.

           -e CMAN_HOSTNAME=(CMAN_HOSTNAME) -e CMAN_IP=(CMAN_IP)

**Note:** You need to replace the CMAN_HOSTNAME and CMAN_IP based on your environment settings.

#### 3.1 Deploying RAC on Docker With Block Devices:
If you are using the RAC Storage Container, skip to the section below "3.2 Deploying with the RAC Storage Container".

* Make sure the ASM devices do not have any file system. Clear any other file system from the devices. For example, if the container creation command is using --device=/dev/xvde and /dev/xvdf, clear these devices as follows:

                dd if=/dev/zero of=/dev/xvde  bs=8k count=100000

                dd if=/dev/zero of=/dev/xvdf  bs=8k count=100000


* Now create the Docker container using the image.  For example:

                docker create -t -i --hostname racnode1 \
                --volume /boot:/boot:ro \
                --volume /dev/shm --tmpfs /dev/shm:rw,exec,size=4G \
                --volume /opt/containers/rac_host_file:/etc/hosts  \
                --dns-search=example.com \
                --device=/dev/xvde:/dev/asm_disk1  --device=/dev/xvdf:/dev/asm_disk2 \
                --privileged=false --cap-add=SYS_NICE \
                --cap-add=SYS_RESOURCE --cap-add=NET_ADMIN \
                -e NODE_VIP=172.15.1.160  -e VIP_HOSTNAME=racnode1-vip  \
                -e PRIV_IP=192.168.17.150  -e PRIV_HOSTNAME=racnode1-priv \
                -e PUBLIC_IP=172.15.1.150 -e PUBLIC_HOSTNAME=racnode1  \
                -e SCAN_NAME=racnode-scan -e SCAN_IP=172.15.1.70  \
                -e OP_TYPE=INSTALL -e DOMAIN=example.com \
                -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
                -e ORACLE_PWD="Oracle_12c" -e ASM_DISCOVERY_DIR=/dev \
                -e CMAN_HOSTNAME=racnode-cman1 -e OS_PASSWORD=Oracle_12c \
                -e CMAN_IP=172.15.1.15 \
                --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                --cpu-rt-runtime=95000 --ulimit rtprio=99  \
                --name racnode1 oracle/database-rac:12.2.0.1

For the details of Parameters, please refer to Section 6.

**Note:** Change environment variable such as IPs and ORACLE_PWD based on your env.

* Continue at the section "3.3 Assigning Network to RAC Containers"

#### 3.2 Deploying with the RAC Storage Container

If you are using physical block devices for shared storage, skip to "3.3 Assigning Network to RAC containers"

* Now create the Docker container using the image.  For example:

                docker create -t -i --hostname racnode1 \
                --volume /boot:/boot:ro \
                --volume /dev/shm --tmpfs /dev/shm:rw,exec,size=4G \
                --volume /opt/containers/rac_host_file:/etc/hosts  \
                --dns-search=example.com \
                --privileged=false --volume racstorage:/oradata \
                --cap-add=SYS_NICE \
                --cap-add=SYS_RESOURCE --cap-add=NET_ADMIN \
                -e NODE_VIP=172.15.1.160  -e VIP_HOSTNAME=racnode1-vip  \
                -e PRIV_IP=192.168.17.150  -e PRIV_HOSTNAME=racnode1-priv \
                -e PUBLIC_IP=172.15.1.150 -e PUBLIC_HOSTNAME=racnode1  \
                -e SCAN_NAME=racnode-scan -e SCAN_IP=172.15.1.70  \
                -e OP_TYPE=INSTALL -e DOMAIN=example.com \
                -e ASM_DISCOVERY_DIR=/oradata -e ORACLE_PWD="Oracle_12c" \
                -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
                -e CMAN_HOSTNAME=racnode-cman1 -e CMAN_IP=172.15.1.15 \
                -e OS_PASSWORD=Oracle_12c \
                --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                --cpu-rt-runtime=95000 --ulimit rtprio=99  \
                --name racnode1 oracle/database-rac:12.2.0.1


For the details of Parameters, please refer to Section 6.

**Note:** You must have created **racstorage** volume during the creation of RAC Storage Container. You can change env variable such as IPs and ORACLE_PWD based on your env. For details about the env variables, please refer the section 6.

#### 3.3 Assign Network to RAC containers
* Execute following commands to asign the network to RAC containers:

         docker network disconnect  bridge racnode1

         docker network connect rac_pub1_nw --ip 172.15.1.150 racnode1

         docker network connect rac_priv1_nw --ip 192.168.17.150  racnode1

#### 3.4 Start the RAC container
* Execute following command to start the container:

          docker start racnode1

* It will take approximately 40 minutes to create the 1st node of the cluster. Check the logs using following command:

          docker logs -f racnode1

* You should see database creation success message at the end.

          ####################################
          ORACLE RAC DATABASE IS READY TO USE!
          ####################################

#### 3.5 Connect to the RAC container
* To connect to the container execute following command:

          docker exec -i -t racnode1 /bin/bash

* If RAC install fails because of any reason, login to container using following command:

           docker exec -i -t racnode1 /bin/bash

check /tmp/orod.log. Go to grid logs i.e. $GRID_BASE/diag/crs and check the failure logs. If it has failed during creation then check DB logs.


### Section 4: Adding a RAC Node using a Docker container
Check DB and cluster is up and running on existing node of the cluster. Otherwise, Node addition will fail or error out.

#### 4.1 Deploying with Block Devices:
If you are using the RAC Storage Container, skip to the section below "4.2 Deploying with the RAC Storage Container".

* Now create the additional Docker container using the image.  For example:

                docker create -t -i --hostname racnode2 \
                --volume /dev/shm --tmpfs /dev/shm:rw,exec,size=4G  \
                --volume /boot:/boot:ro \
                --dns-search=example.com  \
                --volume /opt/containers/rac_host_file:/etc/hosts \
                --device=/dev/xvde:/dev/asm_disk1 --device=/dev/zvdf:/dev/asm_disk2 \
                --privileged=false --cap-add=SYS_NICE \
                --cap-add=SYS_RESOURCE --cap-add=NET_ADMIN \
                -e EXISTING_CLS_NODES=racnode1 -e OS_PASSWORD=Oracle_12c \
                -e NODE_VIP=172.15.1.161  -e VIP_HOSTNAME=racnode2-vip  \
                -e PRIV_IP=192.168.17.151  -e PRIV_HOSTNAME=racnode2-priv \
                -e PUBLIC_IP=172.15.1.151  -e PUBLIC_HOSTNAME=racnode2  \
                -e DOMAIN=example.com -e SCAN_NAME=racnode-scan \
                -e SCAN_IP=172.15.1.70 -e ASM_DISCOVERY_DIR=/dev \
                -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
                -e ORACLE_SID=ORCLCDB -e OP_TYPE=ADDNODE \
                --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                --cpu-rt-runtime=95000 --ulimit rtprio=99  --restart=always \
                --name racnode2 oracle/database-rac:12.2.0.1

For the details of Parameters, please refer to Section 7.

**Note:** You can change env variable such as IPs based on your env. If you have more than one node in the cluster, you must set EXISTING_CLS_NODES environment variable with comma separated nodes of the cluster.Also, OS_PASSWORD must be same on all the nodes for grid and oracle user in cluster during node addition. For details about the env variables, please refer the section 7.

* Continue at the section "4.3 Assigning Network to RAC Containers"

#### 4.2 Deploying with the RAC Storage Container

If you are using physical block devices for shared storage, skip to "4.3 Assigning Network to additional RAC container"

* Now create the additional Docker container using the image. For example:

                docker create -t -i --hostname racnode2 \
                --volume /dev/shm --tmpfs /dev/shm:rw,exec,size=4G  \
                --volume /boot:/boot:ro \
                --dns-search=example.com  \
                --volume /opt/containers/rac_host_file:/etc/hosts \
                --privileged=false --volume racstorage:/oradata \
                --cap-add=SYS_NICE \
                --cap-add=SYS_RESOURCE --cap-add=NET_ADMIN \
                -e EXISTING_CLS_NODES=racnode1 -e OS_PASSWORD=Oracle_12c \
                -e NODE_VIP=172.15.1.161  -e VIP_HOSTNAME=racnode2-vip  \
                -e PRIV_IP=192.168.17.151  -e PRIV_HOSTNAME=racnode2-priv \
                -e PUBLIC_IP=172.15.1.151  -e PUBLIC_HOSTNAME=racnode2  \
                -e DOMAIN=example.com -e SCAN_NAME=racnode-scan \
                -e SCAN_IP=172.15.1.70 -e ASM_DISCOVERY_DIR=/oradata \
                -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
                -e ORACLE_SID=ORCLCDB -e OP_TYPE=ADDNODE \
                --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                --cpu-rt-runtime=95000 --ulimit rtprio=99  --restart=always \
                --name racnode2 oracle/database-rac:12.2.0.1

**Note:** You must have created **racstorage** volume during the creation of RAC Storage Container. You can change env variable such as IPs based on your env. If you have more than one node in the cluster, you must set EXISTING_CLS_NODES environment variable with comma separated nodes of the cluster.Also, OS_PASSWORD must be same on all the nodes for grid and oracle user in cluster during node addition. For details about the env variables, please refer the section 7.

#### 4.3 Assign Network to additional RAC container
* Execute following command to assign the network to new RAC container:

                docker network disconnect  bridge racnode2

                docker network connect rac_pub1_nw --ip 172.15.1.151 racnode2

                docker network connect rac_priv1_nw --ip 192.168.17.151  racnode2

#### 4.4 Start RAC container
* Execute following command to start the container:

                docker start racnode2

* To check the DB logs, please tail orod.log

                docker logs -f racnode2

* You should see database creation success message at the end.

               ####################################
               ORACLE RAC DATABASE IS READY TO USE!
               ####################################

#### 4.5 Connect to the RAC container
* To connect to the container execute following command:

                docker exec -i -t racnode2 /bin/bash

* If Rac node addition fails because of any reason, login to container using following command:

                docker exec -i -t racnode2 /bin/bash

                check /tmp/orod.log

        Go to grid logs i.e. $GRID_BASE/diag/crs and check the failure logs. If it has failed during creation then check DB logs.

### Section 5: Connecting to RAC Database
**IMPORTANT:** This section assume that you have gone through the all the above sections and RAC DB is up and running inside the containers.

* If you are using connection manager and exposed the port 1521 on docker host. You can connect from a client outside the host using following command:

                sqlplus  system/<password>@//<docker_host>:1521/<ORACLE_SID>

* If using Docker MACVLAN driver, you should be able to connect using the public scan listener directly from any client outside your host.

                sqlplus  system/<password>@//<scan_name>:1521/<ORACLE_SID>

### Section 6: ENV Variables for RAC 1st Node container
* This section provides the details about env variables which can be used for the 1st node of the cluster.

        Parameters:
        OP_TYPE=###Specify the Operation TYPE. It can accept 2 values INSTALL OR ADDNODE####
        NODE_VIP=####Specify the Node VIP###
        VIP_HOSTNAME=###Specify the VIP hostname###
        PRIV_IP=###Specify the Private IP###
        PRIV_HOSTNAME=###Specify the Private Hostname###
        PUBLIC_IP=###Specify the public IP###
        PUBLIC_HOSTNAME=###Specify the public hostname###
        SCAN_NAME=###Specify the scan name###
        ASM_DEVICE_LIST=###Specify the ASM Disk lists. You can ignore this if you are using storage container.###
        SCAN_IP=###Specify this if you do not have DNS server###
        DOMAIN=###Default value set to example.com###
        PASSWORD=###OS password will be generated by openssl###
        CLUSTER_NAME=###Default value set to racnode-c####
        ORACLE_SID=###Default value set to ORCLCDB###
        ORACLE_PDB=###Default value set to ORCLPDB###
        ORACLE_PWD=###Default value set to generated by openssl random password###
        ORACLE_CHARACTERSET=###Default value set AL32UTF8###
        DEFAULT_GATEWAY=###Default gateway. You need this env variable if containers will be running on multiple hosts.####
        CMAN_HOSTNAME=###Connection Manager Host Name###
        CMAN_IP=###Connection manager Host IP###
        ASM_DISCOVERY_DIR=####ASM disk location insdie the container. By default it is /dev######
        OS_PASSWORD=You need to pass this for ssh setup between grid and oracle user. OS_PASSWORD will rest the password of grid and Oracle user based on your env. You need common password on all the containers during Node Addition. Once the Node Addition is done you can change the passwords based on your environment policies. 

### Section 7: ENV Variables for RAC 2nd Node Container (ADDNode)
* This section provides the details about env variables which can be used for an additional node added to the cluster.

        Parameters:
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
        ASM_DEVICE_LIST=###Specify the ASM Disk lists. You can ignore this if you are using storage container.###
        DOMAIN=###Default value set to example.com###
        ORACLE_SID=###Default value set to ORCLCDB###
        DEFAULT_GATEWAY=###Default gateway. You need this env variable if containers will be running on multiple hosts.####
        CMAN_HOSTNAME=###Connection Manager Host Name###
        CMAN_IP=###Connection manager Host IP###
        ASM_DISCOVERY_DIR=####ASM disk location insdie the container. By default it is /dev######
       OS_PASSWORD=You need to pass this for ssh setup between grid and oracle user. OS_PASSWORD will rest the password of grid and Oracle user based on your enviornment. You need common password on all the containers during Node Addition. You need to manually set grid and oracle user password on existing cluster nodes before node addition. Once the Node Addition is done you can change the passwords based on your environment policies.

### Section 8 : Support
Oracle RAC Database is supported for Oracle Linux 7.

**IMPORTANT:** Note that the current version of Oracle RAC on Docker is only supported for test and development environments, but not for production environments.

### Section 9 : License

To download and run Oracle Grid and Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

### Section 10 : Copyright

Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
