# Workshop Guide: Docker
## Background Knowledge Required / Suggested
* WebLogic Architecture
* WebLogic Scripting Tool (WLST)
* Linux

## Feature Overview

Docker is a platform that enables users to build, package, ship and run distributed applications. Docker users package up their applications, and any dependent libraries or files, into a Docker image. Docker images are portable artifacts that can be distributed across Linux environments. Images that have been distributed can be used to instantiate containers where applications can run in isolation from other applications running in other containers on the same host operating system

## Workshop Overview

As part of the Docker Workshop, in this document you will see how to create a Docker image using WebLogic zip (developer) distribution and JDK. Then using a custom Dockerfile, this WebLogic install image will be extended to create a domain. The Admin Server of this domain will be started, thereafter starting NodeManager, creating a Machine, and creating a ManagedServer will also be shown. All this will be achieved using custom scripts / Dockerfiles.   

### Requirements / Prerequisites
* Computer with 8GB RAM and 2-4 cores
* VirtualBox 4.2.4+
* Linux VM with Docker and Git installedlo

### Tips
* Allocate at least 4GB RAM to the VM, if not more
* Allocate at least 2 cores to the VM, if not more

## Steps
### Get Oracle Docker Images
This lab document assumes you’ve downloaded the Oracle Docker Images to your home directory. Feel free to use any location you prefer.

    $ git clone --depth=1 https://github.com/oracle/docker-images.git 

### Download Java and WebLogic Binaries
Navigate to ~/docker-images/OracleWebLogic/dockerfiles/12.2.1 and verify the contents. Note the .download files, which are placeholders for the actual files that need to be downloaded.

![](images/01_ls1221.png?raw=true)

#### Java
View the contents of the server-jar-jre-8u<version>.download

![](images/02_catjava.png?raw=true)

    $ cat server-jar-jre-8u<version>.download

Right-click the link and select **Open Link** to open it in a browser.

Accept the license agreement and download server-jre-*.gz.

#### WebLogic
View the contents of the fmw_12.2.1.0.0_wls_quick_Disk1_1of1.download

    $ cat fmw_12.2.1.0.0_wls_quick_Disk1_1of1.download
    
![](images/03_catfmw.png?raw=true)    
    
Right-click the link and select **Open Link** to open it in a browser.

Accept the license agreement. 

Download the **Quick Installer for Mac OSX, Windows and Linux**. You may need to log in with your Oracle ID.

Close the tab.

Return to the terminal and Right-click the link and select **Open Link** to open it in a browser (the license acceptance is finicky, so we’re doing it again)

Accept the license agreement.

Download the **Supplemental Quick Installer** (just below the Quick Installer for Max OSX, Windows and Linux)

Wait for the downloads to complete, then copy them from the ~/Downloads directory to the dockerfiles/12.2.1 directory:

    $ cp ~/Downloads/server-* .
    $ cp ~/Downloads/fmw-* .

### Dockerfiles
This project offers Dockerfiles for WebLogic 12c (12.1.3 and 12.2.1), it also provides one Dockerfile for the 'developer' distribution and a second Dockerfile for the 'generic' distribution. Open ‘Dockerfile.developer’ and verify its contents.

![](images/04_dockerfile.png?raw=true)
 
To assist in building the images, you can use the **buildDockerImage.sh** script. Navigate to up one directory, ‘cd ..’ , and verify the contents of buildDockerImage.sh.

This script initially checks for the checksum of the installers (Java & WebLogic) and then depending on the type of Dockerfile chosen (Developer of Generic), the corresponding Dockerfile.developer or Dockerfile.generic would be invoked and the corresponding image would be generated.

Execute the `buildDockerImage.sh` script to view it’s usage description:

    $ sh buildDockerImage.sh 
    
![](images/05_build.png?raw=true)    
 
`-d` is for developer image and `-g` is for generic image. So now execute the script with the developer option:

    $ sh buildDockerImage.sh –d
    
![](images/06_build-d.png?raw=true)    

While the build is running, open the 12.2.1/Dockerfile.developer in another terminal window to follow the steps.
 
As is evident in the above screen capture, in Steps 1 through 5:

1. 	The Linux container version is specified, 
1. 	The maintainer of the Dockerfile is provided (Bruno Borges)
1. 	Environment variables are set,
1. 	The WebLogic binaries are copied to the container
1. 	The Java binaries are added to the container
     
WebLogic is installed in Step 6:

![](images/07_build-d2.png?raw=true)
 
In steps 7 through 9, the oracle user is created, the working directory is set to /u01/oracle and the command shell is set to bash: 

![](images/08_build-d3.png?raw=true)
 
Once complete, the Docker image, which belongs to the repository ‘**oracle/weblogic**’ with the tag ‘**12.2.1-developer**’ has been created.

To summarize, we:

1. Decided which distribution we wanted to use (12.1.3 or 12.2.1).
1. Downloaded the required binary packages as instructed in the .download files (Java and WebLogic)
1. Ran the buildDockerImage.sh which created our base WebLogic image.

View the new oracle/weblogic Docker image: 

    $ docker images
    
![](images/09_dockerimages.png?raw=true)
  
Please note that this image does NOT have a domain pre-configured. The image must be extended with our own Dockerfile. A new domain will be created using the WebLogic Scripting Tool (WLST).

### Domain Samples
To give users an idea on how to create a domain from a custom Dockerfile to extend the WebLogic install image, we provide samples under the folder ‘samples’ This Dockerfile will create an image by extending oracle/weblogic:12.2.1-developer (from the Developer distribution). It will configure a base_domain with the following settings:

    JPA 2.1 enabled
    JAX-RS 2.0 shared library deployed
    Admin Username: weblogic
    Admin Password: welcome1
    Oracle Linux Username: oracle
    Oracle Linux Password: welcome1
    WebLogic Domain Name: base_domain
    Admin Server on port: 8001
    Managed Servers on port: 7001
    JVM Memory Settings: -Xms256m -Xmx512m -XX:MaxPermSize=2048m

The best way to create your own, or extend domains is by using WebLogic Scripting Tool. The WLST script used to create domains in both Dockerfiles is ‘~/docker-images/OracleWebLogic/samples/1221-domain/container-scripts/create-wls-domain.py’. This script by default adds JMS resources and a few other settings. You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override the existing domain, or create a new one with WLST.

To try a sample of a WebLogic image with a domain configured:

    $ cd ~/docker-images/OracleWebLogic/samples/1221-domain
    $ docker build -t samplewls:12.2.1-domain --build-arg ADMIN_PASSWORD=welcome1 .

Like before, you can open the Dockerfile in another terminal window to see the definition of the build steps Docker is running.

![](images/10_dockerbuild.png?raw=true)
 
Is steps 1 through 6 above, we extend the ‘oracle/weblogic:12.2.1-developer’ image, retrieve the admin password, define WebLogic configuration settings such as the server ports and copy the WLST scripts that have been written to create the WebLogic domain.

Steps 7 through 10 run the WLST script, open the node manager, admin and managed server ports and define the default run command as startWebLogic.sh:

![](images/11_dockerbuild2.png?raw=true)

The image is successfully built, belonging to the repository ‘samplewls’ and tag ’12.2.1-domain’.

And now that this image is created, this will be reflected when we do a `docker images`

![](images/12_dockerimages.png?raw=true)

The `docker run` command instructs Docker to run a command in a specified container. 

To start the WebLogic AdminServer, you can simply call `docker run -d samplewls:12.2.1-domain` command. The sample Dockerfile mentioned above defines startWebLogic.sh as the default CMD. This is the command to start the WebLogic Admin Server.

If you want to run the container on a remote server for later access it, or if you want to run locally but bind ports to your computer, you must expose ports and addresses for the Admin Server, as you regularly do with Docker for any network process.

Alternatively, you can specify everything on the command line:

    $  docker run -d -p 8001:8001 --name=wlsadmin samplewls:12.2.1-domain startWebLogic.sh

In the above command:

    --name   =    Assign a name to the container
    -d       =    Run container in background and print container ID
    -p       =    Publish a container's port(s) to the host

This means for the image ‘samplewls:12.2.1-domain’ we want to start the Admin Server on port 8001 in a new container named ‘wlsadmin’ which would run in the background.

![](images/13_dockerrun.png?raw=true)
 
If you notice in the above figure, after the command was executed - a container ID has been printed. We can use the `docker logs` command to fetch the logs of a container.  Using the `--tail=all` option prints all the lines in the logs. Use the container ID printed after execution of the ‘startWeblogic.sh’ command above and print the logs of the container (as in the image above):

    $ docker logs --tail=all <container id>

Executing the above command multiple times would show you that finally the Admin Server is started:

![](images/13_dockerlogs.png?raw=true)
 
We have to get the port / IP Address at which this container is running. Execute the following to get the information:

    $ docker inspect --format '{{ .NetworkSettings.IPAddress }}' wlsadmin
    
![](images/14_dockerinspect.png?raw=true)
 
Now you can access the AdminServer Web Console at http://<ip address>:8001/console.

![](images/15_dockerinspect2.png?raw=true)

Login using weblogic/welcome1 and verify that only one server (Admin Server) exists.

![](images/16_console.png?raw=true)

The ‘~/docker-images/OracleWebLogic/samples/1221-domain/container-scripts’ has useful Bash and WLST scripts that provide three possible modes to run WebLogic Managed Servers on a Docker container. Make sure you have an AdminServer container running before starting a ManagedServer container.

The sample scripts will by default, attempt to find the AdminServer running at t3://wlsadmin:8001. You can change this. But most importantly, the AdminServer container has to be linked with Docker's `--link` parameter.

Below, are the three suggestions for running ManagedServer Container within the sample 12c-domain:

1. Start NodeManager (Manually):

	 docker run -d --link wlsadmin:wlsadmin <image-name> startNodeManager.sh

2. Start NodeManager and Create a Machine Automatically:

	 docker run -d --link wlsadmin:wlsadmin <image-name>  createMachine.sh

3. Start NodeManager, Create a Machine, and Create a ManagedServer Automatically

	 docker run -d --link wlsadmin:wlsadmin <image-name>  createServer.sh

Parameters you can use:

     docker run -d --link wlsadmin:wlsadmin \
         -p <NM Port>:5556 -p <MS Port>:<MS Port> \
         --name=<Container name> \
         -e MS_HOST=<Host address where Managed server container runs> \
         -e MS_PORT=<Managed server port, use same unique port internally and externally> \
         -e NM_HOST=<Host address where NM container runs> \
         -e NM_PORT=<NM Port (should match the externally exposed port with -p)> \
         <image name based on 12c-domain sample> \
         <createMachine.sh, startNodeManager.sh, createServer.sh>


![](images/17_scripts.png?raw=true)

Log out of the Weblogic Server Admin Console. Let us go for the 3rd option : ‘Start NodeManager, Create a Machine, and Create a ManagedServer Automatically’

    $ docker run -d --link wlsadmin:wlsadmin samplewls:12.2.1-domain createServer.sh
    
![](images/18_createserver.png?raw=true)
 
As previously stated, the ‘docker run’ command prints a container ID as output. The `docker logs` command can be used to get the logs of this container ID. 

Running it multiple times would finally show that the Managed Server is up and running:

![](images/19_dockerrun.png?raw=true)

Login to WebLogic Server Admin Console and notice that a new Managed Server has been created and it is up and running on port 7001. 

![](images/20_console.png?raw=true)
 
Click on Machines and notice that a new Machine has also been created:

![](images/21_consolemachines.png?raw=true)
 
Click on the newly created Machine and then verify the NodeManager Configuration. A new Nodemanager has been created and started

![](images/22_consolenodemanager.png?raw=true)

Instead of using these scripts (in location ~/docker-images/OracleWebLogic/samples/1221-domain/container-scripts) – we can also use the default scripts which come as part of the WebLogic Server domain setup. One such example is shown below, where we use the ‘stopManagedServer.sh’ script to stop a Managed Server

    $ docker run -d --link wlsadmin:wlsadmin samplewls:12.2.1-domain stopManagedWebLogic.sh <managed server name> t3://<ip address of admin console>:8001 weblogic welcome1
    
![](images/23_stop.png?raw=true)

This `docker run` command will print a container ID. We can see the logs of the same and notice that the Managed Server has been stopped.

![](images/24_dockerlogs.png?raw=true)
 
Verify the same in the Admin Console:

![](images/25_console.png?raw=true)

### Clean Up
List all the containers that are running:

    $ docker ps -a
    
![](images/26_dockerps.png?raw=true)
 
A script has been provided to kill all the ‘containers’ that have been started.  It is ‘/u02/Docker/docker-master/OracleWebLogic/samples/rm-containers.sh’. Executing the same is shown below:

    $ ./rm-containers.sh
    
![](images/27_rmcontainers.png?raw=true)
 
Verify the Docker images that exist currently :  

    $ docker images

![](images/28_dockerimages.png?raw=true)
 
Use the `docker rmi` command to delete each of these Docker images

    $ docker rmi <IMAGE ID>

![](images/29_dockerrmi.png?raw=true)
 
### More Information
* [Oracle WebLogic Server 12.2.1 Running on Docker Containers ](https://blogs.oracle.com/WebLogicServer/entry/oracle_weblogic_server_12_21)

* [White Paper - Oracle  WebLogic Server on Docker Containers](http://www.oracle.com/technetwork/middleware/weblogic/overview/weblogic-server-docker-containers-2491959.pdf)

* [Docker on Oracle Linux](https://docs.docker.com/engine/installation/linux/oracle/)

