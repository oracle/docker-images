# Oracle WebCenter Sites 12c R2 (12.2.1.3.0) on Docker

## Contents

### 1. [Introduction](#1-introduction-1)
### 2. [Hardware and Software Requirements](#2-hardware-and-software-requirements-1) 
### 3. [Prerequisites](#3-prerequisites-1)
### 4. [Downloading Docker Images and Oracle WebCenter Sites Binary](#4-downloading-docker-images-and-oracle-webcenter-sites-binary-1)
### 5. [Building Oracle WebCenter Sites Docker Images](#5-building-oracle-webcenter-sites-docker-images-1)
### 6. [Preparing to run Oracle WebCenter Sites Docker Container](#6-preparing-to-run-oracle-webcenter-sites-docker-container-1)
### 7. [Running Oracle WebCenter Sites Docker Container](#7-running-oracle-webcenter-sites-docker-container-1)
### 8. [FAQs](#8-faqs-1)
### 9. [Copyright](#9-copyright-1)

## 1. Introduction
To create web content management solutions, developers need a lightweight environment. Docker images need minimum resources, thereby allowing developers to quickly create development environments.

This project offers scripts to build an Oracle WebCenter Sites image based on 12c R2 (12.2.1.3). Use this Docker configuration to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle WebCenter Sites, see the [Oracle WebCenter Sites Online Documentation](https://docs.oracle.com/middleware/12213/wcs/index.html).

This project creates Oracle WebCenter Sites Docker image with a single node targeted for development and excludes components such as SatelliteServer, SiteCapture, and VisitorServices. This image is not supported or recommended to use on a production system.

## 2. Hardware and Software Requirements
Oracle WebCenter Sites has been tested and is known to run on the following hardware and software:

### A. Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

### B. Software Requirements

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 17.03 or higher | docker –version           |

## 3. Prerequisites
Before you begin, ensure to do the following steps:

1. Use Oracle Linux Server. Download from this location: [http://www.oracle.com/technetwork/server-storage/linux/downloads/index.html](http://www.oracle.com/technetwork/server-storage/linux/downloads/index.html).

2. Set the [Proxy](#10-how-to-fix-yumoraclecom-connectivity-error) if required.

3. Assign Docker permission to user.

```
	$ sudo /sbin/usermod -a -G docker <new_userid>
```
   **Note**: To verify if the user has the Docker permission, see [FAQ](#12-permission-denied-while-connecting-to-the-docker-daemon-socket) section.

## 4. Downloading Docker Images and Oracle WebCenter Sites Binary
Before you begin creating an Oracle WebCenter Sites image on Docker, download the following images of Oracle Fusion Middleware Infrastructure, Oracle Database, and Oracle WebCenter Sites binaries. WebCenter Sites is installed on Oracle Fusion Middleware infrastructure, and it needs Oracle Database for storage.
 
To download images from Oracle Container Registry (OCR) and Oracle Technology Network (OTN):

Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link that's on the top-right of the Web page.

### A. To download and set up Oracle Fusion Middleware Infrastructure image.
1. Click **Home > Middleware** and then click **Continue** for the _fmw-infrastructure_ repository.
2. Click **Accept** to accept the license agreement.
3. To download Oracle Fusion Middleware infrastructure base image:    
    ```
        $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.3
    ```
	
    Retag the Oracle Fusion Middleware Infrastructure Docker image by running the following command:
    ```
        $ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.3 oracle/fmw-infrastructure:12.2.1.3
    ```
    **Note**: 
    - If you want to download image from the Docker Store, see [FAQ](#7-alternate-download-location-for-oracle-fusion-middleware-infrastructure-and-oracle-database-images) section.
    - If you want to build the image from GitHub, see [FAQ](#9-how-do-i-build-an-oracle-fusion-middleware-infrastructure-1221x-base-image) section.

### B. To download and set up Oracle Database Enterprise Edition image.
1. Click **Home > Database** and then click **Continue** for _enterprise_ repository.
2. Click **Accept** to accept the license agreement.
3. From the terminal, execute the following commands:
       
    Download Oracle Database 12.2.0.1 base image:    
    ``` 
        $ docker pull container-registry.oracle.com/database/enterprise:12.2.0.1    
    ```
    Retag the Oracle Database Docker image by running the following command:
    ```
       $ docker tag container-registry.oracle.com/database/enterprise:12.2.0.1 database/enterprise:12.2.0.1
    ```
    **Note**: 
    - If you want to download image from the Docker Store, see [FAQ](#7-alternate-download-location-for-oracle-fusion-middleware-infrastructure-and-oracle-database-images) section.
    - If you want to build the image from GitHub, see [FAQ](#8-how-do-i-build-an-oracle-database-1221x-base-image) section.
	
	
### C. To download Oracle WebCenter Sites binary file.

1. Download Oracle WebCenter Sites 12c R2 12.2.1.3 binary from [Oracle Technology Network](http://www.oracle.com/technetwork/middleware/webcenter/sites/downloads/index.html).
2. Save the Oracle WebCenter Sites 12.2.1.3 binary at this location: `../docker-images/OracleWebCenterSites/dockerfiles/12.2.1.3/`.

## 5. Building Oracle WebCenter Sites Docker Images

To build Oracle WebCenter Sites Docker image, go to `dockerfiles` folder located at `../docker-images/OracleWebCenterSites/` and run the following command:

```
   $ sh buildDockerImage.sh -v 12.2.1.3
```

   For more information on usage of _buildDockerImage.sh_ command, see [FAQ](#1-what-is-the-usage-of-builddockerimagesh-file),

**IMPORTANT**: The resulting image has automated scripts to:
-  Run RCU
-  Create and configure a WebLogic domain
-  Run WebCenter Sites Configuration process while creating an admin container

## 6. Preparing to Run Oracle WebCenter Sites Docker Container
Configure an environment before running the Oracle WebCenter Sites Docker container. You need to set up a communication network between containers on the same host, data volume to store data, and Database container.

##### A. Creating a user-defined network
##### B. Mounting host directory as a data volume 
##### C. Setting up an Oracle Database Docker container

### A. Creating a user-defined network
Create a user-defined network to enable containers to communicate by running the following command:
```
   $ docker network create -d bridge <network_name>
```
Sample command:
```
   $ docker network create -d bridge WCSitesNet
```
### B. Mounting host directory as a data volume
You need to mount volumes, which are directories stored outside a container's file system, to store database data files and WebLogic domain files. The default location of the volume in the container is `/var/lib/docker/volumes`. 

This option lets you mount a directory from your host to a container as volume. This volume is used to store database data files and WebLogic server domain files. The volume is created at this location `/scratch/DockerVolume/WCSitesVolume/`.

To mount a host directory as a data volume, execute the below command.
```
	$ sudo /usr/sbin/useradd -u 1000 -g 1000 <new_userid>
	$ mkdir -p /scratch/DockerVolume/WCSitesVolume/WCSites /scratch/DockerVolume/WCSitesVolume/WCSitesShared
	$ sudo chown <new_userid> /scratch/DockerVolume/WCSitesVolume/WCSites /scratch/DockerVolume/WCSitesVolume/WCSitesShared
```
All container operations are performed as 'oracle' user.

### C. Setting up an Oracle Database Docker container
To set up an Oracle Database Docker container, you must first update the environment file which is passed as a parameter in the command that starts the database container.  

##### 1. Update the Environment File
Update the environment `db.env.list` file, to define the parameters, which is located at `../docker-images/OracleWebCenterSites/dockerfiles/`.

`db.env.list` file details:
```
   DB_SID=ORCLCDB
   DB_PDB=ORCLPDB1
   DB_DOMAIN=localdomain 
```
##### 2. Start the Database Container

To run Database container, go to `dockerfiles` folder located at `../docker-images/OracleWebCenterSites/` and run the following command: 

```
   $ docker run -d --name <container_name> --network=<network_name> -p <database_listener_port>:1521 -p <enterprise_manager_port>:5500 --env-file <environment_file> <repo_name:tag_name>
```
Sample command:
```
   $ docker run -d --name WCSites12212Database --network=WCSitesNet -p 1521:1521 -p 5500:5500 --env-file ./db.env.list database/enterprise:12.2.0.1
```
Database start up command explained:

| 			Parameter            |     Parameter Name     | 							Description			                                |
| :----------------------------: | :--------------------: | :-----------------------------------------------------------------------------: |
| --name                         | container_name         | Database name; set to ‘WCSites12212Database’                                    |
| --network                      | network_name           | User-defined network to connect to; use the one created earlier ‘WCSitesNet’    |
| -p                             | database_listener_port | Database listener port; set to ‘1521’. Maps the container port to host's port.  |
| -p                             | enterprise_manager_port| Enterprise Manager port; set to ‘5500’. Maps the container port to host's port. |
| database/enterprise:12.2.0.1-ee| repo_name:tag_name     | Repository name, Tag name of the image.                                         |

Running the above command creates a Container Database (CDB) with one Pluggable Database (PDB).

This is the Database connection string:
```
   DB_CONNECTSTRING=<hostname/containername>:1521/ORCLPDB1.localdomain
```   
   **Note**: Container name can be given only if the container is located on the same host machine. Ensure SERVICE_NAME is a valid PDB service name in your database as given in the $ORACLE_HOME/admin/ORCLCDB/tnsnames.ora file.
   
For Additional information on [running Oracle Database image](https://container-registry.oracle.com), Click **Home > Database > enterprise**.

For monitoring Docker container Logs:
```
    $ docker logs -f --tail 900 WCSites12212Database
```

## 7. Running Oracle WebCenter Sites Docker Container
To run the Oracle WebCenter Sites Docker container, you need to create:
* Admin container to manage the admin server. The admin container performs RCU, ConfigWizard, and WebCenter Sites Configuration processes. 
* Managed container to manage the managed server.

### A. Creating Admin container for WebCenter Sites Admin Server
This container is used to manage Admin Server.

#### 1. Update the environment file
`wcsitesadminserver.env.list` is located at `../docker-images/OracleWebCenterSites/dockerfiles/` that contains parameters that are passed to WebLogic admin server. Update this file with the information pertinent to your environment:

`wcsitesadminserver.env.list` file details:
```
    DOCKER_HOST=<Hostname>
    DB_CONNECTSTRING=<Hostname/ContainerName>:<Database Port>/<DB_PDB>.<DB_DOMAIN>
    DB_USER=<By default: sys>
    DB_PASSWORD=<Database Password>
    RCU_PREFIX=<RCU_PREFIX>
    DB_SCHEMA_PASSWORD=<database_schema_password: if not provided, it gets auto generated>
    SAMPLES=<To install sample Sites, set samples as true, else set as false>
    DOMAIN_NAME=<Domain Name optional>
    SITES_SERVER_NAME=<Sites Server Name optional>
    ADMIN_USERNAME=<Admin UserName, default: weblogic>
    ADMIN_PASSWORD=<Admin_Password: if not provided, it gets auto generated>
```
#### 2. Start the Admin Container

a. To run WebLogic Admin server container, go to `dockerfiles` folder located at `../docker-images/OracleWebCenterSites/`. 

b. Run the following command and pass the environment file name as a parameter: 

```
   $ docker run -d --name <container_name> --network=<network_name> -p <weblogic_port>:7001 -p <weblogic_ssl_port>:9001 -v <user_projects_volume_dir>:/u01/oracle/user_projects -v <sites_shared_volume_dir>:/u01/oracle/sites-shared --env-file <environment_file> <repo_name:tag_name>
```
Sample command:
```
   $ docker run -d -t --name WCSitesAdminContainer --network=WCSitesNet -p 7001:7001 -p 9001:9001 -v /scratch/DockerVolume/WCSitesVolume/WCSites:/u01/oracle/user_projects -v /scratch/DockerVolume/WCSitesVolume/WCSitesShared:/u01/oracle/sites-shared --env-file ./wcsitesadminserver.env.list oracle/wcsites:12.2.1.3
```
Admin Container start up command explained:

| 		Parameter    	 |     Parameter Name      | 							     		Description			                               |
| :--------------------: | :---------------------: | :---------------------------------------------------------------------------------------: |
| --name                 | container_name          | Database name; set to ‘WCSitesAdminContainer’                                             |
| --network              | network_name            | User-defined network to connect to; use the one created earlier ‘WCSitesNet’.             |
| -p                     | weblogic_port           | WebLogic port; set to ‘7001’. Maps the container port to host's port.              	   |
| -p                     | weblogic_ssl_port       | WebLogic SSL port; set to ‘9001’. Maps the container port to host's port.           	   |
| --v                    | user_projects_volume_dir| ‘/scratch/DockerVolume/WCSitesVolume/WCSites’ mounts the host directory as a Volume.      |
| --v                    | sites_shared_volume_dir | ‘/scratch/DockerVolume/WCSitesVolume/WCSitesShared’ mounts the host directory as a Volume.|
| --env-file             | environment_file        | ‘ wcsitesadminserver.env.list’ sets the environment variables.                            |
| oracle/wcsites:12.2.1.3| repo_name:tag_name      | Repository name, Tag name of the image.                                                   |

**IMPORTANT**: Monitor the container logs to check if the WebLogic server starts up before logging in to the Console.

For monitoring Docker container Logs:
```
    $ docker logs -f --tail 900 WCSitesAdminContainer
```
**Note**: Copy the **WebLogic Admin** and **Database Schema** passwords from the log. It's used while starting the Managed container.

To connect to the container for monitoring WebCenter Sites/WebLogic Logs:
```
   $ docker exec -it WCSitesAdminContainer /bin/bash
```
Now you can access below WebLogic Console.
```
   http://DOCKER_HOST:7001/console 
```
### B. Creating a managed container for WebCenter Sites Managed Server 
This container is used to manage the Managed Server. 

#### 1. Create the environment file to passed the parameters 
Update the environment `wcsitesserver.env.list` file which is located at `../docker-images/OracleWebCenterSites/dockerfiles/`.

`wcsitesserver.env.list` file details:
```
   WCSITES_ADMIN_HOSTNAME=<WCSites Admin Container Name>
   DOMAIN_NAME=<Domain Name>
   SITES_SERVER_NAME=<Sites Server Name>
```
#### 2. Start the Managed Container

a. To run WebLogic Managed Server container, go to `dockerfiles` folder located at `../docker-images/OracleWebCenterSites/`.  
 
b. Run the following command and pass the environment file name as a parameter: 
```
   $ docker run -d -t --name <container_name> --network=<network_name> --volumes-from <admin_container_name> -p <sites_port>:7002 -p <sites_ssl_port>:9002 --env-file <environment_file> <repo_name:tag_name> /bin/bash -c "/u01/oracle/sites-container-scripts/startSitesServer.sh; /bin/bash"
```
Sample command:
```
   $ docker run -d -t --name WCSitesManagedContainer --network=WCSitesNet --volumes-from WCSitesAdminContainer -p 7002:7002 -p 9002:9002 --env-file ./wcsitesserver.env.list oracle/wcsites:12.2.1.3 /bin/bash -c "/u01/oracle/sites-container-scripts/startSitesServer.sh; /bin/bash"
```
Managed Container start up command explained:

| 		Parameter    	 |     Parameter Name  | 							     		Description			                  |
| :--------------------: | :-----------------: | :--------------------------------------------------------------------------: |
| --name                 | container_name      | Database name; set to ‘WCSitesManagedContainer’                              |
| --network              | network_name        | User-defined network to connect to; use the one created earlier ‘WCSitesNet’.|
| -p                     | sites_port          | Sites port; set to ‘7002’. Maps the container port to host’s port.    		  |
| -p                     | sites_ssl_port      | Sites SSL port; set to ‘9002’. Maps the container port to host’s port.		  |
| --volumes-from         | admin_container_name| ‘WCSitesAdminContainer’ mounts the directory from Admin container.           |
| --env-file             | environment_file    | ‘wcsitesadminserver.env.list’ sets the environment variables.                |
| oracle/wcsites:12.2.1.3| repo_name:tag_name  | Repository name, Tag name of the image.                                      |
   
**IMPORTANT**: Monitor the container logs to check if WebCenter Sites starts up before logging in to the Console.

To monitor Docker Container logs:
```
   $ docker logs -f --tail 900 WCSitesManagedContainer
```
To connect to the container for monitoring WebCenter Sites/WebLogic logs:
```
   $ docker exec -it WCSitesManagedContainer /bin/bash
```
Now you can access WebCenter Sites Server at
```
   http://DOCKER_HOST:7002/sites
```
## 8. FAQs

##### 1. What is the usage of buildDockerImage.sh file?
```   
   $ sh buildDockerImage.sh
   Usage: buildDockerImage.sh -v [version]
   Builds a Docker Image for Oracle WebCenter Sites.
   Parameters:
      -v: version to build. Required.
   Choose: 12.2.1.x
      -c: enables Docker image layer cache during build
      -s: skips the MD5 check of packages
      
   LICENSE UPL 1.0
   Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
```
##### 2. Where do I find the auto-generated WebLogic Admin and Database schema password?
If you do not specify WebLogic/Database username and password, a password is auto-generated. You can find the password in the console log of the command used to run WebLogic admin server.
```
   `Oracle WebLogic Server auto generated Admin password:`
```
Oracle Database Schema password is auto-generated. You can find this password in the console log line:
```   
   `Database Schema password Auto Generated:`
```
If you need to find the passwords later, look for **password** in the Docker logs generated during the startup of the container.

To view the Docker Container logs run:
```
   $ docker logs --details <Container-id>
```
##### 3. How to modify start/stop admin/managed server scripts?
You can find these scripts here: dockerfiles/12.2.1.3/sites-container-scripts) sites-container-scripts are located at `../docker-images/OracleWebCenterSites/dockerfiles/12.2.1.3/sites-container-scripts/*` 

##### 4. Why do I get an error message as "... RCU exists already"?
Most likely, you're not running this command for the first time. The RCU_prefix may be present already. Drop the corresponding schemas or use a different prefix.

##### 5. Where can I find RCU configuration Wizard and WebCenter Sites configuration scripts?
See [Readme.md](dockerfiles/12.2.1.3/wcs-wls-docker-install/README.md) located at `../docker-images/OracleWebCenterSites/dockerfiles/12.2.1.3/wcs-wls-docker-install/README.md`

##### 6. How do I configure WebCenter Sites with an On-Prem Oracle Database instance? 
Set DB_CONNECTSTRING connection string parameter as mentioned in section [Update the environment file](#1-update-the-environment-file-1).

##### 7. Alternate download location for Oracle Fusion Middleware Infrastructure and Oracle Database Images? 
Before you build an Oracle WebCenter Sites image, download the Oracle Fusion Middleware infrastructure and Oracle Database images from the [Docker Store.](https://store.docker.com/)

If you download Oracle Fusion Middleware infrastructure from Docker Store, then retag using below command:
```
   $ docker tag store/oracle/fmw-infrastructure:12.2.1.3 oracle/fmw-infrastructure:12.2.1.3
```
If you download Oracle Database from Docker Store, then retag using below command:
```
   $ docker tag store/oracle/database-enterprise:12.2.0.1 database/enterprise:12.2.0.1
```
##### 8. How do I build an Oracle Database 12.2.1.x base image?
If you want to build your own Oracle Database image, use the Docker files and scripts in the [Oracle Database](../OracleDatabase) GitHub repository.

##### 9. How do I build an Oracle Fusion Middleware Infrastructure 12.2.1.x base image?
If you want to build your own Oracle Fusion Middleware Infrastructure image, use the Docker files and scripts in the [Oracle FMW Infrastructure](../OracleFMWInfrastructure) GitHub repository.

##### 10. How to fix yum.oracle.com connectivity error?
The errors mean that the host is not able to connect to external registries for update. To access external registries and build a Docker image, set up environment variables for proxy server as below:
```
   export http_proxy=http://www-yourcompany.com:80 
   export https_proxy=http://www-yourcompany.com:80 
   export HTTP_PROXY=http://www-yourcompany.com:80 
   export HTTPS_PROXY=http://www-yourcompany.com:80 
   export NO_PROXY=localhost,.yourcompany.com 
```
##### 11. How to fix error "Please specify script.work.dir to use an alternate location” while running Admin Container?
Make sure you have granted the right permission to 'oracle' user as described in section [Mounting a Host Directory as a Data Volume](#b-mounting-host-directory-as-a-data-volume-1).

##### 12. Permission denied while connecting to the Docker daemon socket?
Run the below command after substituting your id:
```
   $ sudo /sbin/usermod -a -G docker <userid>
```
To confirm that userid is part of docker group run below command and make sure it lists group docker:
```
   $ id -Gn <userid>
```
* Run docker ps -a command to confirm user is able to connect to Docker engine.

##### 13. How do I see all containers? 
To see all the containers, including the exited ones: 
```
   $ docker ps –a 
```
##### 14. How do I remove containers?
To remove containers:
```
   $ docker rm –f <container_id>
```    
##### 15. How do I see all the images? 
To see all the images on host:
```
   $ docker images 
```
##### 16. How do I remove an image?
To remove images:  
```
   $ docker rmi <image_id>
```
##### 17. How do I inspect the container?
To inspect the container: 
```
   $ docker inspect <container name>
```
##### 18. How do I inspect the network?
To inspect the network: 
```
   $ docker inspect <network name>
```
##### 19. How do I stop/start containers? 
To stop/start containers: 
```
   $ docker stop <container name>
   $ docker start <container name>
```
## 9. Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
