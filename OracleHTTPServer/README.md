Oracle HTTP Server on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start dockerfiles and samples for Oracle HTTP Server Standalone 12.2.1 based on Oracle Linux and Oracle JDK 8 (Server).
The certification of OHS on Docker does not require the use of any file presented in this repository.
Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## How to Build and Run
This project offers sample Dockerfiles for Oracle HTTP Server 12cR2 (12.2.1) in standalone mode. To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage

The **buildDockerImage.sh** script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their prefered set of parameters.

### Building OHS Docker Install Images
IMPORTANT: You have to download the binaries of OHS and Oracle JDK and put them in place (see .download files inside dockerfiles/).

Download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

IMPORTANT: the resulting images will NOT have a domain pre-configured.
You must extend the image with your own Dockerfile, and create your domain using WLST. You might take a look at the use case samples as well below.

## Samples for OHS Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the OHS image, we provide a few samples. For an example on 12.2.1, you can use the sample inside **samples/1221-OHS-domain** folder for creating standalone OHS domain

### Sample Domain for OHS 12.2.1
This Dockerfile will create an image by extending **oracle/ohs:12.2.1-sa** . It will configure a ohsDomain with the following settings:

 - Oracle Linux Username: oracle
 - Oracle Linux Password: welcome1
 - OHS Domain Name: ohsDomain
 - OHS Component name : ohs_sa1
 - NodeManager on port: 5556
 - OHS on port: 7777

### Write your own OHS domain with WLST
The best way to create your own, or extend domains is by using WebLogic Scripting Tool. You can find an example of a WLST script to create domains at create-sa-ohs-domain.py. You may want to tune this script with your own setup . You can also extend images and override an existing domain, or create a new one with WLST.

## Building a sample Docker Image of a OHS Domain
To try a sample of a OHS standalone image with a domain configured, follow the steps below:

Make sure you have oracle/ohs:12.2.1-sa image built. If not go into **dockerfiles/12.2.1** and call:

        $ sh buildDockerImage.sh -v 12.2.1

Go to folder **samples/1221-OHS-domain**

Run the following command:

        $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 --build-arg NM_PASSWORD=welcome1 .

Verify you now have this image in place with

        $ docker images

## Running Oracle HTTP Server
To start the OHS container you can simply call:

        $ docker run -d sampleohs:12.2.1

        Or

        $ docker run -d --name ohssa --hostname ohssa -p 7777:7777 sampleohs:12.2.1

Note the sample Dockerfile defines startNMandOHS.sh as the default CMD. This script will start the Node Manager and OHS server component.
Now you can access the OHS index page at http://localhost:7777/index.html

You can also run a sanity check to see if OHS server is rendering the test static html packages by accessing URL http://localhost:7777/helloWorld.html

## Configuring the Oracle WebLogic Server Proxy Plug-In with Oracle HTTP Server
Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs)is used for proxying requests from Oracle HTTP Server to Oracle WebLogic Server. The Oracle WebLogic Server Proxy Plug-In is included in the Oracle HTTP Server 12c (12.2.1) installation.
Refer https://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553

To test the sample OHS server with WLS Proxy Plugin, a sample file mod_wl_ohs.conf.sample has been provided under **samples/1221-ohs-domain/container-scripts** folder for reference.

The sample mod_wl_ohs.conf.sample file assumes that:

  1. WLS Admin Servers is running and accessible @ http://myhost:8001/console
  2. An application called chat is deployed on a cluster which has 2 WLS Managed server running under it and is accessible @ http://myhost:7001/chat and http://myhost:7004/chat

###How to configure WLS proxy plugin on OHS container :

  1. Build your docker image and run docker container using sample file under samples/1221-OHS-domain
  2. Login to the running OHS docker container (as oracle user) by executing


        $ docker exec -i -t <container_id> /bin/bash

  ** container_id can be found by running command $ docker ps -a

  3. Navigate to /container-scripts folder and edit the mod_wl_ohs.conf.sample file with correct directives . Refer section 2.4 in above Oracle docs
  4. Run the script configureWLSProxyPlugin.sh . This will also restart the OHS server
  5. Now you will be able to access all URLS via the OHS Listen Port 7777
     - http://myhost:7777/console
     - http://myhost:7777/consolehelp
     - http://myhost:7777/chat