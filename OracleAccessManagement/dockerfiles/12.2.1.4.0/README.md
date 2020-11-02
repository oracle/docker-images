Building an Oracle Access Management Image using Dockerfiles and Scripts
========================================================================
Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This Image includes binaries for Oracle Access Management (OAM) Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OAM specific Managed Servers.

***Image***: oracle/oam:<version; example:12.2.1.4.0>

## Prerequisites
The following prerequisites are necessary before building OAM images:

* A working installation of Docker 18.03 or later

## How to Build the Oracle Java image

Please refer to [README.md](../../../OracleJava/README.md) under `docker-images/OracleJava` for details on how to build Oracle Java image.

## How to Build the Oracle Fusion Middleware Infrastructure image

Please refer to [README.md](../../../OracleFMWInfrastructure/README.md) under `docker-images/OracleFMWInfrastructure` for details on how to build Oracle Fusion Middleware Infrastructure image.

OAM Dockerfile uses the 'oracle/fmw-infrastructure:12.2.1.4.0' tag to refer to the Oracle Fusion Middleware (FMW) Infrastructure image, hence you should use this tag for the same.

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
