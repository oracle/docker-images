Building an Oracle Access Management Image using Dockerfiles, Scripts and Base Image from Oracle Container Registry (OCR)
=========================================================================================================================
Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This Image includes binaries for Oracle Access Management (OAM) Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OAM specific Managed Servers.

***Image***: oracle/oam:<version; example:12.2.1.4.0>

## Prerequisites
The following prerequisites are necessary before building OAM images:

* A working installation of Docker 18.03 or later

## Pulling the Oracle JDK (Server JRE) base image
You can pull the Oracle Server JRE 8 image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the Server JRE 8 image, re-tag the image so that it works with the dependent Dockerfile which refer to the JRE 8 image through oracle/serverjre:8.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions".

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Java** and then click on **serverjre**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

        
        $ docker login container-registry.oracle.com
        $ docker pull container-registry.oracle.com/java/serverjre:8
        $ docker tag container-registry.oracle.com/java/serverjre:8 oracle/serverjre:8

## Pulling Oracle FMW Infrastructure 12.2.1.4.x image
You can pull Oracle FMW Infrastructure 12.2.1.4.x image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the FMW Infrastructure 12.2.1.4.x image, re-tag the image so that it works with the dependent dockerfile which refer to the FMW Infrastructure 12.2.1.4.x image through oracle/fmw-infrastructure:12.2.1.4.0.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions". fmw-infrastructure images can be found under Middleware section.

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Middleware** and then click on **fmw-infrastructure**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

        
        $ docker login container-registry.oracle.com
        $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-191222
        $ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-191222 oracle/fmw-infrastructure:12.2.1.4.0

## Building a Container Image for Oracle Access Management

### Downloading the OAM Docker files

  1. Make a work directory to place the OAM Docker files:
     
	$ mkdir <work directory>
	
  2. Download the OAM Docker files from the OAM [repository](https://github.com/oracle/docker-images) by running the following command:

   
    $ cd <work directory>
	$ git clone https://github.com/oracle/docker-images

### Downloading the 12.2.1.4.0 Identity Management shiphome.

  1. Download the [Oracle Identity and Access Management 12cPS4 software](https://www.oracle.com/middleware/technologies/identity-management/downloads.html) to a stage directory. Unzip the downloaded `fmw_12.2.1.4.0_idm_Disk1_1of1.zip` file and copy the `fmw_12.2.1.4.0_idm.jar` to `<work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/`:
    
    $ unzip fmw_12.2.1.4.0_idm_Disk1_1of1.zip
    $ cp fmw_12.2.1.4.0_idm.jar <work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_idm_generic.jar
	
   **Note**: The filename must be changed to `fmw_12.2.1.4.0_idm_generic.jar` when copying to the 12.2.1.4.0 directory.	
   
  2. If you are creating the OAM image with patches create the following directories under the `12.2.1.4.0` directory, where patches directory will contain the patches and opatch_patch directory will contain the Opatch patch:
	
	$ mkdir -p <work directory>/OracleAccessManagement/dockerfiles/12.2.1.4.0/patches
	$ mkdir -p <work directory>/OracleAccessManagement/dockerfiles/12.2.1.4.0/opatch_patch
	
  
  3. If required run the following to set the proxy server appropriately. This is required so the build process can pull the relevant Linux packages via yum:

    $ export http_proxy=http://<proxy_server_hostname>:<proxy_server_port>
    $ export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>
	
  4. Run the following command to build the OAM image:

    $ cd <work directory>/docker-images/OracleAccessManagement/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4.0

    If successful, one can see the following at the end:

      Oracle OAM suite Docker Image for version: 12.2.1.4.0 is ready to be extended.

        --> oracle/oam:12.2.1.4.0

      Build completed in 786 seconds.
	  

   The OAM docker image is now built successfully! 
   
   To create OAM containers refer to the **OAM  Container Configuration** below.



## OAM  Container Configuration
 
 To configure the OAM Docker Containers follow the tutorial [Creating Oracle Access Management Docker Containers](https://docs.oracle.com/en/middleware/idm/access-manager/12.2.1.4/tutorial-oam-docker/)
 
## OAM Kubernetes Configuration

To configure the OAM Containers with Kubernetes see the [Oracle Access Management on Kubernetes](https://oracle.github.io/fmw-kubernetes/oam/) documentation.

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleAccessManagement](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
