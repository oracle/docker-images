WebLogic on Docker
===============
Docker configurations to facilitate installation, configuration, and environment setup for developers. This project includes [dockerfiles](dockerfiles/) and [samples](samples/) for WebLogic 12.1.3  with Oracle JDK  7.

## Based on Official Oracle Linux Docker images 7.
For more information please read the [Docker Images from Oracle Linux](https://registry.hub.docker.com/_/oraclelinux/) page.

## How to build and run
This project offers Dockerfiles for WebLogic 12c (12.1.3), it also provides one Dockerfile for the 'developer' distribution and a second Dockerfile for the 'generic' distribution. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

### Building WebLogic Images
First decide which distribution you want to use, then download the required packages WebLogic Server installers, JDK and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

    $ sudo sh buildDockerImage.sh -h
    Usage: buildDockerImage.sh [ -d | -g ]
    Builds a Docker Image for WebLogic.
    
    Parameters
      -d: creates image based on 'developer' distribution
      -g: creates image based on 'generic' distribuition 

    * use either -d or -g, obligatory.

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST.

## Samples for WebLogic Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the WebLogic install image, we provide samples under the folder [samples/](samples/).

### Sample Domain for WebLogic 12c
This [Dockerfile](samples/12c-domain/Dockerfile) will create an image by extending **oracle/weblogic:12.1.3-dev** (from the Developer distribution). It will configure a **base_domain** with the following settings:

 * JPA 2.1 enabled
 * JAX-RS 2.0 shared library deployed
 * Admin Username: **weblogic**
 * Admin Password: **welcome1**
 * Oracle Linux Username: **oracle**
 * Oracle Linux Password: **welcome1**
 * WebLogic Domain Name: **base_domain**
 * Admin Server on port: **8001**
 * Managed Servers on port: **7001**
 * JVM Memory Settings: **-Xms256m -Xmx512m -XX:MaxPermSize=2048m**

Make sure you build the WebLogic 12c Image with **-d** to get the Developer Image, which is referenced by this sample Dockerfile.

### Write your own WebLogic Domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](http://docs.oracle.com/cd/E57014_01/cross/wlsttasks.htm). The WLST script used to create domains in both Dockerfiles is [create-wls-domain.py](samples/12c-domain/container-scripts/create-wls-domain.py) (for 12c). This script by default adds JMS resources and a few other settings. You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override the existing domain, or create a new one with WLST.

## Building a sample Docker Image of WebLogic Domain
To try a sample of a WebLogic image with a domain configured, follow the steps below:

  1. Make sure you have **oracle/weblogic:12.1.3-dev** image built. If not go into **dockerfiles** and call 

        sudo sh buildDockerImage.sh -d

  2. Go to folder **samples/12c-domain**
  3. Run the following command: 

        sudo docker build -t samplewls:12.1.3 .

  4. Make sure you now have this image in place with 

        sudo docker images

### Running WebLogic Admin Server Container 
To start the WebLogic AdminServer, you can simply call **docker run -d samplewls:12.1.3** command. The sample Dockerfile mentioned above defines **startWebLogic.sh** as the default CMD. This is the command to start the WebLogic Admin Server.

If you want to run the container on a remote server for later access it, or if you want to run locally but bind ports to your computer, you must expose ports and addresses for the Admin Server, as you regularly do with Docker for any network process.

    $ sudo docker run -d -p 8001:8001 --name=wlsadmin samplewls:12.1.3 startWebLogic.sh
    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' wlsadmin
    xxx.xx.x.xx

Now you can access the AdminServer Web Console at [http://xxx.xx.x.xx:8001/console](http://xxx.xx.x.xx:8001/console).

For more information on how to bind ports, check the Docker Network documentation.

### Sample **12c-domain**: Running WebLogic Managed Server Container
The **12c-domain** comes with [useful Bash and WLST scripts](samples/12c-domain/container-scripts) that provide three possible modes to run WebLogic Managed Servers on a Docker container. Make sure you have an AdminServer container running before starting a ManagedServer container (see above).

The sample scripts will by default, attempt to find the AdminServer running at **t3://wlsadmin:8001**. You can change this. But most importantly, the AdminServer container has to be linked with Docker's **--link** parameter.

Below, check the three suggestions for running ManagedServer Container within the sample **12c-domain**:

 * Start NodeManager (Manually):

         $ sudo docker run -d --link wlsadmin:wlsadmin <image-name> startNodeManager.sh

 * Start NodeManager and Create a Machine Automatically:

         $ sudo docker run -d --link wlsadmin:wlsadmin <image-name>  createMachine.sh

 * Start NodeManager, Create a Machine, and Create a ManagedServer Automatically 

        $ sudo docker run -d --link wlsadmin:wlsadmin <image-name>  createServer.sh

 * Parameters you can use:

        $ sudo docker run -d --link wlsadmin:wlsadmin \
             -p <NM Port>:5556 -p <MS Port>:<MS Port> \
             --name=<Container name> \
             -e MS_HOST=<Host address where Managed server container runs> \
             -e MS_PORT=<Managed server port, use same unique port internally and externally> \
             -e NM_HOST=<Host address where NM container runs> \
             -e NM_PORT=<NM Port (should match the externally exposed port with -p)> \
             <image name based on 12c-domain sample> \
             <createMachine.sh, startNodeManager.sh, createServer.sh>

**IMPORTANT:** these scripts are part of the sample [12c-domain](samples/12c-domain) and can be used as a starting point. They give an idea on how to use WLST, customize the container environment, and start processes such as the AdminServer and the NodeManager.

If you have an AdminServer and a Managed Server running on containers on the same host, you can easily create a cluster by managing the Machines and Clusters from the Admin Web Console.  Use the scripts

 * **startNodeManager.sh** - will start a NodeManager in the container.
 * **[createMachine.sh](samples/12c-domain/container-scripts/createMachine.sh)** - will start Node Manager and add a machine to the domain.
 * **[createServer.sh](samples/12c-domain/container-scripts/createServer.sh)** - will start Node Manager, add a machine to the domain running at **wlsadmin** (or at ADMMIN_URL), and finally create and configure a Managed Server.

These scripts have a list of variables that must be properly configured, though most have default values (when running on Single Host mode):
 * **ADMIN_USERNAME** = username of the AdminServer 'weblogic' user. Default: weblogic
 * **ADMIN_PASSWORD** = password of ADMIN_USERNAME. Defaults to value passed during Dockerfile build. ('welcome1' in samples)
 * **ADMIN_HOST**     = Host address of the AdminServer. Default: wlsadmin
 * **ADMIN_PORT**     = Port of the AdminServer. Default: 8001, pre-defined in [Dockerfile](samples/12c-domain/Dockerfile).
 * **CONTAINER_NAME** = name of the Machine to be created. Default: nodemanager_ + <ContainerID>
 * **NM_HOST**        = IP address where NodeManager can be reached. Default: IP address of the container
 * **NM_PORT**        = Port of NodeManager. Default: 5556
 * **MS_HOST**        = IP address where Managed Server can be reached. Default: IP address of the container
 * **MS_PORT**        = Port of Managed Server. Default: 7001

#### Running Containers On A Remote Host
To access ManagedServers and the AdminServer running on container in a remote host, you must use the Docker Network features to either use the **host** container network mode or bind specific ports. For example:

 * Start AdminServer Container on your remote host

        $ sudo docker run -d --name wlsadmin -p 8001:8001 samplewls:12.1.3 startWebLogic.sh

 * Start an unexposed ManagedServer Container with **createMachine.sh** or **startNodeManager.sh**

        $ sudo docker run -d --link wlsadmin:wlsadmin --name="wlsnm0" -e NM_PORT="5558" -e NM_HOST=<host machine address> samplewls:12.1.3 createMachine.sh

   In this case (either with startNodeManager.sh or createMachine.sh, this domain will have a Machine running in a container with no exposed ports and thus, any Managed Server created in this domain and assigned to this Machine cannot be accessed externally. This can be useful for JMS processing, EJBs, or anything that will be running in this cluster without external direct user access.

 * Start an exposed ManagedServer Container with **createServer.sh**

        $ sudo docker run -d --link wlsadmin:wlsadmin  --name="MS1" -p 7002:7002 -e MS_PORT="7002" -e MS_HOST=<host address> samplewls:12.1.3 createServer.sh

        $ sudo docker run -d --link wlsadmin:wlsadmin  --name="MS2" -p 7003:7003 -e MS_PORT="7003" -e MS_HOST=<host address> samplewls:12.1.3 createServer.sh

   In this case with createServer.sh, the ManagedServer will be automatically created and assigned, so you must during command line define which port will be used to run the ManagedServer, and the exposed port (with Docker's -p). For simplification, always use the same port on external/internal definition. It is also important to define MS_HOST because that is the value that WebLogic will tell users where data is coming from, such as HTTP responses.

**Note:** remember to change the port when you create a new Managed Server. createServer.sh will not start the Managed Server automatically it requires you to go to the AdminServer console and start the server.

## Docker Container Communicating With Servers on a Remote Host
Another possible topology is to run a single Admin Server container communicating with WebLogic Server running on a remote host. Use --add-host so that container assumes the ip address of host where it is running instead of the local container IP address.

        $ sudo docker run -d -p 8001:8001 --net=host \ 
              --add-host=hostname:<host ip address where container is running> \ 
              --name wlsadmin samplewls:12.1.3

For this configuration to work the following configurations are necessary:

 * The listen address of the AdminServer in the Docker container has to be configured.
 * The listen address of the AdminServer in the remote host  has to be configured.
 * The client must use the hosts IP addresses to get the initial context for JNDI lookup.

## License
To download and run WebLogic 12c Distribution regardless of inside or outside a Docker container, and regardless of Generic or Developer distribution, you must agree and accept the [OTN Free Developer License Terms](http://www.oracle.com/technetwork/licenses/wls-dev-license-1703567.html).

To download and run Oracle JDK regardless of inside or outside a DOcker container, you must agree and accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project and GitHub [docker/OracleWebLogic](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.
