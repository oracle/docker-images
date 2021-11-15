Oracle WebCenter Content container images
=========================================

## Contents

### 1. [Introduction](#1-introduction-1)
### 2. [Hardware and Software Requirements](#2-hardware-and-software-requirements-1)
### 3. [Pre-requisites](#3-pre-requisites-1)
### 4. [Building Oracle WebCenter Content image](#4-building-oracle-webcenter-content-image-1)
### 5. [Running Oracle WebCenter Content containers](#5-running-oracle-webcenter-content-containers-1)
### 6. [License](#6-license-1)
### 7. [Copyright](#7-copyright-1)
# 1. Introduction
This project offers scripts to build an Oracle WebCenter Content container image based on 12.2.1.4.0 release. Use this documentation to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle WebCenter Content, see the [Oracle WebCenter Content 12.2.1.4.0 Online Documentation](https://docs.oracle.com/en/middleware/webcenter/content/12.2.1.4/index.html).

This repository includes quick start `Dockerfile` for WebCenter Content 12.2.1.4.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle WebLogic Infrastructure 12.2.1.4.0.

The containers will be connected using a Docker User Defined network.
More information on Docker and its installation in Oracle Linux can be found here: [Oracle Container Runtime for Docker User Guide](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/)

# 2. Hardware and Software Requirements
Oracle WebCenter Portal has been tested and is known to run on the following hardware and software:

## 2.1. Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

## 2.2. Software Requirements

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 17.03 or higher | docker version           |

# 3. Pre-requisites

## 3.1. To confirm that userid is part of the Docker group, run the below command:
```
   $ sudo id -Gn <userid>
```
* Run `docker ps -a` command to confirm user is able to connect to Docker engine.
To add/modify user to be part of docker group
```
   $ sudo /sbin/usermod -a -G docker <userid>
```

## 3.2. Set the Proxy if required:

Set up the proxy for docker to connect to the outside world - to access external registries and build a Docker image, set up environment variables for proxy server something like this:
```
   export http_proxy=http://proxy.example.com:80 
   export https_proxy=http://proxy.example.com:80 
   export HTTP_PROXY=http://proxy.example.com:80 
   export HTTPS_PROXY=http://proxy.example.com:80 
   export NO_PROXY=localhost,.example.com 
```

## 3.3. Create a User Defined network

In this configuration creation of a user defined network will enable communication between the containers just using container names. User defined network option was preferred over the container linking option as the latter is now deprecated. For this setup we will use a user defined network using bridge driver.Create a user defined network using the bridge driver by executing the following command:

        $ docker network create -d bridge <network_name>

Sample command ...

        $ docker network create -d bridge WCContentNET

## 3.4. Mount a host directory as a data volume
Data volumes are designed to persist data, independent of the container’s lifecycle. The default location of the volume in container is under `/var/lib/docker/volumes`. There is an option to mount a host directory into a container as the volume. We will use that option for the data volume, to store WebLogic domain files and any other configuration files. 

To mount a host directory `<YOUR_HOST_DIRECTORY_PATH>/wccontent` as `$DATA_VOLUME`, execute the below command.

> The userid can be anything but it must belong to uid 1000, which is same as 'oracle' user running in the container.

> This ensures 'oracle' user has access to shared volume.

```
sudo /usr/sbin/useradd -u 1000 <userid>
mkdir -p /<YOUR_HOST_DIRECTORY_PATH>/wccontent
sudo chown 1000:0 /<YOUR_HOST_DIRECTORY_PATH>/wccontent
export DATA_VOLUME=/<YOUR_HOST_DIRECTORY_PATH>/wccontent
```

All container operations are performed as **'oracle'** user.

> If a user already exists with **'-u 1000'** then use the same user. Or modify any existing user to have uid as **'-u 1000'**

> Set the path of the `DATA_VOLUME` on all terminals where containers are to be started.

## 3.5. Database
You need to have a running database container or a database running on any machine. 
The database connection details are required for creating WebCenter Content specific RCU schemas while configuring WebCenter Content domain. 

The Oracle Database image can be pulled from [Oracle Container Registry](https://container-registry.oracle.com) or build your own using the [Oracle Database Dockerfiles and scripts](https://github.com/oracle/docker-images/tree/main/OracleDatabase) in this repo.

## 3.6. Docker Security Configuration

For detailed instructions on security best practices, please refer to the [security recommendations chapter](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/docker-security.html#docker-security-components) of the Oracle Container Runtime for Docker User Guide.

# 4. Building Oracle WebCenter Content image

To build a WebCenter Content image you should have Oracle Fusion Middleware Infrastructure image.

## 4.1. Pulling Oracle Fusion Middleware Infrastructure install image

Get Oracle Oracle Fusion Middleware Infrastructure image -

> 1. Sign in to Oracle Container Registry. Click the Sign in link which is on the top-right of the Web page.
> 2. Click Middleware and then click Continue for the fmw-infrastructure repository.
> 3. Click Accept to accept the license agreement.
> 4. Use following commands to pull Oracle Fusion Middleware Infrastructure base image from repository :
```
docker login container-registry.oracle.com
docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407
docker tag  container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407 oracle/fmw-infrastructure:12.2.1.4.0
docker rmi container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407

```

## 4.2. Building container image for Oracle WebCenter Content

1. Clone or download the [GitHub repository](https://github.com/oracle/docker-images).
The repository contains Docker files and scripts to build Docker images for Oracle products.
2. You have to download the binary for WebCenter Content shiphome and put it in place. The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/). Search for "Oracle WebCenter Content" and download the version which is required.
Extract the downloaded zip files and copy `fmw_12.2.1.4.0_wccontent.jar` file under `../docker-images/OracleWebCenterContent/dockerfiles/12.2.1.4` .
Set the proxies in the environment before building the image as required, go to directory located at `../docker-images/OracleWebCenterContent/dockerfiles/` and run these commands -

```
#To build image
sh buildDockerImage.sh -v 12.2.1.4

#Verify you now have the image
docker images
```

# 5. Running Oracle WebCenter Content containers
 
To run the Oracle WebCenter Content in containers, you need to create:
* a container for the Admin Server.
* at least one Managed Server container.

## 5.1. Creating containers for WebCenter Content Server

### 5.1.1. Update the environment file 

Create an environment file `webcenter.env.list` file, to define the parameters.

Update the parameters inside `webcenter.env.list` as per your local setup.

Please note: All parameters mentioned below are manadatory and must not be omitted or left blank. The parameter `component` is meant for integration of associated products. 

```
#Database Configuration
DB_DROP_AND_CREATE=<true or false>
DB_CONNECTION_STRING=<Hostname>:<Database Port>/<Database Service>
DB_RCUPREFIX=<RCU Prefix>
DB_PASSWORD=<Database Password>
DB_SCHEMA_PASSWORD=<Schema Password>

#configure container
ADMIN_SERVER_CONTAINER_NAME=<Admin Server Container Name>
ADMIN_PORT=<Admin Server Port>
ADMIN_PASSWORD=<Admin Server Password>
ADMIN_USERNAME=<Admin Server User Name>

DOMAIN_NAME=<domain directory-name>
UCM_PORT=<port to be used for UCM managed server on container>
IBR_PORT=<port to be used for IBR managed server on container>
UCM_HOST_PORT=<host port to access UCM managed server - this is the port value to be used for -p option (left of the colon) sec. ### 5.1.3>
IBR_HOST_PORT=<host port to access IBR managed server - this is the port value to be used for -p option (left of the colon) sec. ### 5.1.3>
UCM_INTRADOC_PORT=<UCM intradoc port on container>
IBR_INTRADOC_PORT=<IBR intradoc port on container>
IPM_PORT=<port to be used for IPM managed server on container>
IPM_HOST_PORT=<host port to access IPM managed server - this is the port value to be used for -p option (left of the colon) sec. ### 5.1.3>
CAPTURE_PORT=<port to be used for Capture managed server on container>
CAPTURE_HOST_PORT=<host port to access Capture managed server - this is the port value to be used for -p option (left of the colon) sec. ### 5.1.3>
WCCADF_PORT=<port to be used for WCC ADFUI managed server on container>
WCCADF_HOST_PORT=<host port to access WCC ADFUI managed server - this is the port value to be used for -p option (left of the colon) sec. ### 5.1.3>

#component
component=IPM,Capture,ADFUI

#HOSTNAME
HOSTNAME=<provide your host name>

#Keep Container alive
KEEP_CONTAINER_ALIVE=true
```

### 5.1.2. Admin Server container
#### A. Creating and running the Admin Server container

Run the following command to create the Admin Server container:

```
docker run -it --name WCCAdminContainer --network=WCContentNET -p <Any Free Port>:<ADMIN_PORT> -v $DATA_VOLUME:/u01/oracle/user_projects --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4

# A sample command will look ike this -

docker run -it --name WCCAdminContainer --network=WCContentNET -p 7001:7001 -v $DATA_VOLUME:/u01/oracle/user_projects --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4
```
**Note:** 

       1. The above command deletes any previous RCU with the same prefix if **DB_DROP_AND_CREATE=true**
       2. Using `docker run` command with options `-i` and `-t` makes the container run in the foreground and any changes to the shell or terminal impacts the container. If required, one can use a terminal-multiplexer (like tmux or screen) to be able to place the shell instance in the background. Please be extremely careful - closing the terminal used to start the Admin Server container as mentioned in sec A and C, will lead to stopping the container.

The `docker run` command creates the container as well as starts the Admin Server in sequence given below:

1. Node Manager
2. Admin Server

When the command is run for the first time, we need to create the domain and configure the content managed servers, so following are done in sequence:

* Loading WebCenter Content schemas into the database
* Creating WebCenter Content domain
* Extending WebCenter Content domain for associated products (e.g. Oracle WebCenter Imaging, Oracle WebCenter Capture, Oracle WebCenter ADFUI) - based on **component** env variable. 
* Configuring Node Manager
* Starting Node Manager
* Starting Admin Server

#### B. Stopping Admin Container
```
docker stop WCCAdminContainer
```

#### C. Starting Admin Container
```
docker start -i WCCAdminContainer
```

### 5.1.3. Managed Server container

#### A. Creating and running the Managed Server container
Run the following command to create the WCContent Managed Server container:

```
docker run -it --name WCContentContainer --network=WCContentNET -p <UCM_HOST_PORT>:<UCM_PORT> -p <IBR_HOST_PORT>:<IBR_PORT> -p <UCM_INTRADOC_PORT>:<UCM_INTRADOC_PORT> -p <IBR_INTRADOC_PORT>:<IBR_INTRADOC_PORT> --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartWebCenterContent.sh

# A sample command will look like this -

docker run -it --name WCContentContainer --network=WCContentNET -p 16200:16200 -p 16250:16250 -p 4444:4444 -p 5555:5555 --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartWebCenterContent.sh
```
The `docker run` command creates the container as well as starts the WebCenter Content managed servers. 

Run the following command to create the WebCenter Imaging Managed Server container:

```
docker run -it --name IPMContainer --network=WCContentNET -p <IPM_HOST_PORT>:<IPM_PORT> --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartIPM.sh

# A sample command will look like this -

docker run -it --name IPMContainer --network=WCContentNET -p 16000:16000 --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartIPM.sh
```
The `docker run` command creates the container as well as starts the WebCenter Imaging managed server container. 

Run the following command to create the WebCenter Capture Managed Server container:

```
docker run -it --name CaptureContainer --network=WCContentNET -p <CAPTURE_HOST_PORT>:<CAPTURE_PORT> --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartCapture.sh

# A sample command will look like this -

docker run -it --name CaptureContainer --network=WCContentNET -p 16400:16400 --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartCapture.sh
```
The `docker run` command creates the container as well as starts the WebCenter Capture managed server container. 

Run the following command to create the WebCenter ADFUI Managed Server container:

```
docker run -it --name WCCADFContainer --network=WCContentNET -p <WCCADF_HOST_PORT>:<WCCADF_PORT> --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartWCCADF.sh

# A sample command will look like this -

docker run -it --name WCCADFContainer --network=WCContentNET -p 16225:16225 --volumes-from WCCAdminContainer --env-file <PATH_TO_ENV_FILE>/webcenter.env.list oracle/wccontent:12.2.1.4 configureOrStartWCCADF.sh
```
The `docker run` command creates the container as well as starts the WebCenter ADFUI managed server container. 

Note:

      1. If Managed Servers need to be accessed through host ports different from container ports, then intended host port values needs to be supplied as part of -p option of the `docker run` command mentoned above (for ex. -p 16201:16200 and -p 16251:16250). The same port value needs to be updated in the `webcenter.env.list` as `UCM_HOST_PORT` and `IBR_HOST_PORT`. If managed servers are going to be accessed via same host port number as the container port, then `UCM_PORT` and `UCM_HOST_PORT` values (and `IBR_PORT` and `IBR_HOST_PORT`) should be same in the `webcenter.env.list`.  
      2. Intradoc ports are for internal server communications and not meant for browser access. While, intradoc ports on container are configurable (like other parametres like admin credentials, admin port, domain-name, manged server container ports) through `webcenter.env.list`, publishing these to different host ports is not supported. This essentially means one can provide `-p 7777:7777` instead of `-p 4444:4444`, but `-p 6666:7777` is not supported.
      3. Using `docker run` command with options `-i` and `-t` makes the container run in the foreground and any changes to the shell or terminal impacts the container. If required, one can use a terminal-multiplexer (like tmux or screen) to be able to place the shell instance in the background. Please be extremely careful - closing the terminal used to start the Managed Server container as mentioned in sec A and C, will lead to stopping the container.
      4. Start only those containers that you would like to use. There are 4 possible containers : WCContent, WebCenter Imaging, WebCenter Capture and WebCenter ADFUI.
      5. If using WebCenter Imaging (IPM), then "localhost" cannot be used to connect to WebCenter Content Server. Use the machine name or the IP address while creating the connection to WebCenter Content Server.

#### B. Stopping Container
```
docker stop WCContentContainer
docker stop IPMContainer
docker stop CaptureContainer
docker stop WCCADFContainer
```

#### C. Starting Container
```
docker start -i WCContentContainer
docker start -i IPMContainer
docker start -i CaptureContainer
docker start -i WCCADFContainer
```

#### D. Getting Shell in Container
```
docker exec -it WCContentContainer /bin/bash
docker exec -it IPMContainer /bin/bash
docker exec -it CaptureContainer /bin/bash
docker exec -it WCCADFContainer /bin/bash
```
Both the Admin and the Managed Server containers must be running before you will be able to start the Admin and Managed Servers using the WebLogic admin credentials.

WebLogic Admin Server
http://hostname:7001/console/

UCM Server
http://hostname:16200/cs/

IBR Server
http://hostname:16250/ibr/

IPM Server
http://hostname:16000/imaging/

Capture Server
http://hostname:16400/dc-console/

WCC ADFUI Server
http://hostname:16225/wcc

# 6. License

To download and run Oracle Fusion Middleware, regardless whether inside or outside a container, you must download the binaries from the Oracle Software Delivery Cloud and accept the license indicated at that page.
All scripts and files hosted in this project are, unless otherwise noted, released under UPL 1.0 license.

# 7. Copyright
Copyright (c) 2021, Oracle and/or its affiliates.
