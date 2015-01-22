WebLogic 12c on Docker
===============
Docker configurations to facilitate installation, configuration, and environment setup for developers.

## Based on Oracle Linux Docker image
For more information please read the [Docker Images from Oracle Linux](http://public-yum.oracle.com/docker-images) page.

## How to build and run
This project comes with two configurations for a WebLogic Docker Image. One is based on the Developer distribution, the other one on the Generic. See below for more details.

In this project you will find a [bin](https://github.com/weblogic-community/weblogic-docker/tree/master/bin) folder with scripts to help you build and run WebLogic on Docker, either with the Developer or the Generic distribution. See below for instructions and usage.

### Building an image
First decide which distribution you want to use, then download the required packages and drop them in the folder of your distribution of choice. Then go into the **bin** folder and run the **buildDockerImage.sh** script as root.

	$ ./buildDockerImage.sh -h
	Usage: buildDockerImage.sh [-d]
	
	    -d: creates image based on 'weblogic12c-developer' distribution, if present. 
                'weblogic12c-generic' otherwhise.
	
The Dockerfiles for both distributions will create same WebLogic Domain with the following patches and configurations:

#### For Developers (weblogic12c-developer)
This [Dockerfile](https://github.com/weblogic-community/weblogic-docker/blob/master/weblogic12c-developer/Dockerfile) will create an image using the Developer ZIP Installer for WebLogic 12c 12.1.3. It will configure a base_domain with the following settings:

 * JPA 2.1 enabled
 * JAX-RS 2.0 shared library deployed
 * Admin Username: **weblogic**
 * Admin Password: **welcome1**
 * Oracle Linux Username: **oracle**
 * Oracle Linux Password: **welcome1**
 * WebLogic Domain Name: **base_domain**

#### Generic Installer (weblogic12c-generic)
This second [Dockerfile](https://github.com/weblogic-community/weblogic-docker/blob/master/weblogic12c-generic/Dockerfile) creates an image with only WebLogic 12c (Generic Installer) installed, and no domain configured. 

For an example of how to extend this image and create your own domain, you can look into the third [Dockerfile](https://github.com/weblogic-community/weblogic-docker/blob/master/weblogic12c-generic/container-domain/Dockerfile) located in **weblogic12c-generic/container-domain** folder.

### Write your own WebLogic domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](http://docs.oracle.com/cd/E57014_01/cross/wlsttasks.htm). The WLST script used to create domains in both Dockerfiles (for [developers](https://github.com/weblogic-community/weblogic-docker/blob/master/weblogic12c-developer/container-scripts/create-wls-domain.py), and the extended example for [generic installer](https://github.com/weblogic-community/weblogic-docker/blob/master/weblogic12c-generic/container-domain/container-scripts/create-wls-domain.py)) is **create-wls-domain.py** (same for both distributions). This script by default adds JMS resources and a few other settings. You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on.

You can also extend images and override the existing domain, or create a new one with WLST.

### Running WebLogic AdminServer
To start the WebLogic AdminServer, you can simply call **docker run** command, but we recommend you use the [dockWebLogic.sh](https://github.com/weblogic-community/weblogic-docker/blob/master/bin/dockWebLogic.sh) script. It has the following usage:

	$ ./dockWebLogic.sh -h
	Usage: dockWebLogic.sh [-a [-p port]] [-n mywlsadmin]
	
	   -a     : attach AdminServer port to host. If -a is present, will attach. Change default (7001) with -p port
	   -p port: which port on host to attach AdminServer. Default: 7001
	   -n name: give a different name for the container. Default: wlsadmin
	
### Create a Cluster
WebLogic has a [Machine](https://docs.oracle.com/middleware/1213/wls/WLACH/taskhelp/machines/ConfigureMachines.html) concept, which is an operational system with an agent, the Node Manager. This resource allows WebLogic to add [Managed Servers](https://docs.oracle.com/middleware/1213/wls/WLACH/taskhelp/domainconfig/CreateManagedServers.html) to an underlying domain in order to create a flexible environment of servers for different applications and resources, and also to define a [Cluster](). By using **Machines** from containers, you can easily create a [Dynamic Cluster]() by simply firing new NodeManagers containers that will be automatically added to the domain running on the AdminServer, started previously. 

To easily plug newly created **Machines** to a domain running on another container, use the [dockNodeManager.sh]() script.

	$ ./dockNodeManager.sh -h
	Usage: dockNodeManager.sh [-n wls_admin_container_name] 
	
	    -n: name of the container with a WebLogic AdminServer orchestrating a WebLogic Domain.
	        Defaults to 'wlsadmin'
	

## Choose your WebLogic Distribution
This project hosts two configurations for building Docker images with WebLogic 12c.

 * Developer Distribution
   For more information on the WebLogic 12c ZIP Developer Distribution, visit [WLS Zip Distribution for Oracle WebLogic Server 12.1.3.0](download.oracle.com/otn/nt/middleware/12c/wls/1213/README.txt).
 * Generic Full Distribution
   For more information on the WebLogic 12c Generic Full Distribution, visit [WebLogic 12.1.3 Documentation](http://docs.oracle.com/middleware/1213/wls/index.html).

## License
To download and run WebLogic 12c Distribution regardless of inside or outside a Docker container, and regardless of Generic or Developer distribution, you must agree and accept the [OTN Free Developer License Terms](http://www.oracle.com/technetwork/licenses/wls-dev-license-1703567.html).

To download and run Oracle JDK regardless of inside or outside a DOcker container, you must agree and accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project and GitHub [weblogic-docker](https://github.com/weblogic-community/weblogic-docker/) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.
