UPDATE: Move to [jeqo/oracle-soa-docker](https://github.com/jeqo/oracle-soa-docker)

SOA on Docker
===============
Docker configurations to facilitate installation, configuration, and environment setup for developers. This project includes [dockerfiles](dockerfiles/) and [samples](samples/) for SOA Suite 12.1.3 Quickstart with Oracle JDK  7.

## Based on Official Oracle Linux Docker images 7.
For more information please read the [Docker Images from Oracle Linux](https://registry.hub.docker.com/_/oraclelinux/) page.

## How to build and run
This project offers Dockerfiles for Oracle SOA Suite 12c (12.1.3) Quickstart. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

### Building SOA Suite Images
First download the required packages SOA Suite installers, JDK and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

    $ sudo sh buildDockerImage.sh -h
    Usage: buildDockerImage.sh
    Builds a Docker Image for SOA Suite.

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST.

## Samples for SOA Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the SOA installer image, we provide samples under the folder [samples/](samples/).

### Sample Domain for SOA Suite 12c
This [Dockerfile](samples/12c-domain/Dockerfile) will create an image by extending **oracle/soa-suite:12.1.3-dev** (from the Developer distribution). It will configure a **base_domain** with the following settings:

 * SOA Suite 12.1.3 enabled
 * OSB 12.1.3 enabled
 * Admin Username: **weblogic**
 * Admin Password: **welcome1**
 * Oracle Linux Username: **oracle**
 * Oracle Linux Password: **welcome1**
 * WebLogic Domain Name: **soa_domain**
 * Admin Server on port: **7001**
 * JVM Memory Settings: **-Xms1024m -Xmx2048m -XX:MaxPermSize=1024m**

### Write your own Domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](http://docs.oracle.com/cd/E57014_01/cross/wlsttasks.htm). The WLST script used to create domains in both Dockerfiles is [create-soa-domain.py](samples/12c-domain/container-scripts/create-soa-domain.py) (for 12c). This script by default adds JMS resources and a few other settings. You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override the existing domain, or create a new one with WLST.

## Building a sample Docker Image of SOA Domain
To try a sample of a SOA Suite image with a domain configured, follow the steps below:

  1. Make sure you have **oracle/soa:12.1.3-dev** image built. If not go into **dockerfiles** and call 

        sudo sh buildDockerImage.sh -d

  2. Go to folder **samples/12c-domain**
  3. Run the following command: 

        sudo docker build -t samplesoa:12.1.3 .

  4. Make sure you now have this image in place with 

        sudo docker images

### Running WebLogic Server Container 
To start the WebLogic Server, you can simply call **docker run -d samplesoa:12.1.3** command. The sample Dockerfile mentioned above defines **startWebLogic.sh** as the default CMD. This is the command to start the WebLogic Admin Server.

If you want to run the container on a remote server for later access it, or if you want to run locally but bind ports to your computer, you must expose ports and addresses for the Admin Server, as you regularly do with Docker for any network process.

    $ sudo docker run -d -p 7001:7001 --name=soahost samplesoa:12.1.3 startWebLogic.sh
    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' soahost
    xxx.xx.x.xx

Alternatively, if you are running on boot2docker, the ip address is obtained by executing `boot2docker ip`.
 
Now you can access the AdminServer Web Console at [http://xxx.xx.x.xx:7001/console](http://xxx.xx.x.xx:7001/console).

For more information on how to bind ports, check the Docker Network documentation.

## License
To download and run Oracle SOA Suite 12c Quick Start Distribution regardless of inside or outside a Docker container, you must agree and accept the [OTN Free Developer License Terms](http://www.oracle.com/technetwork/licenses/wls-dev-license-1703567.html).

To download and run Oracle JDK regardless of inside or outside a DOcker container, you must agree and accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project and GitHub repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.
