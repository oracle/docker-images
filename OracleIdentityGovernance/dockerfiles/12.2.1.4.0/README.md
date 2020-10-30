Building an Oracle Identity Governance Image using Dockerfiles and Scripts
==========================================================================

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This image includes binaries for Oracle Identity Governance (OIG) Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OIG specific Managed Servers.

***Image***: oracle/oig:<version; example:12.2.1.4.0>

## Prerequisites
The following prerequisites are necessary before building OIG images:

* A working installation of Docker 18.03 or later

## Hardware Requirements

| Hardware  | Size                                              |
| :-------- | :-------------------------------------------------|
| RAM       | Min 16GB                                          |
| Disk Space| Min 50GB (ensure 10G+ available in Docker Home)   |


## How to build

This project offers a sample Dockerfile and scripts to build an Oracle Identity Governance 12cPS4 (12.2.1.4) image. 

Building your own OIG image involves the following steps:

* Pulling the Oracle SOA 12.2.1.4 image
* Downloading the OIG Docker files
* Downloading the 12.2.1.4.0 Identity Management shiphome and Patches
* Building the OIG image

	
### How to Build the Oracle SOA Image

Please refer to [README.md](../../../OracleSOASuite/README.md) under `docker-images/OracleSOASuite` for details on how to build Oracle Java image.

OIG Dockerfile uses the `fmw-soa:12.2.1.4.0` tag for the Oracle SOA image, hence you should use this tag while referring to the Oracle SOA image.

### Downloading the OIG Docker files

  1. Make a work directory to place the OIG Docker files:
     
	$ mkdir <work directory>
	
  2. Download the OIG Docker files from the OIG [repository](https://github.com/oracle/docker-images/) by running the following command:
   
    $ cd <work directory>
	$ git clone https://github.com/oracle/docker-images/


### Downloading the 12.2.1.4.0 Identity Management shiphome and Patches

  1. Download the [Oracle Identity and Access Management 12cPS4 software](https://www.oracle.com/middleware/technologies/identity-management/downloads.html) to a stage directory. Unzip the downloaded `fmw_12.2.1.4.0_idm_Disk1_1of1.zip` file and copy the `fmw_12.2.1.4.0_idm.jar` to `<work directory>/docker-images/OracleIdentityManagement/dockerfiles/12.2.1.4.0/`:
    
	$ unzip fmw_12.2.1.4.0_idm_Disk1_1of1.zip
    $ cp fmw_12.2.1.4.0_idm.jar <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_idm_generic.jar
	
   **Note**: The filename must be changed to `fmw_12.2.1.4.0_idm_generic.jar` when copying to the 12.2.1.4.0 directory.	
   
  2. If you require patches in your image, you should complete the following steps:
  
  * Create the following directories under the `12.2.1.4.0` directory:
	
	`$ mkdir -p <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/patches`
  
    `$ mkdir -p <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/opatch_patch`
	
  * Download any patches required from [My Oracle Support](https://support.oracle.com).

  * Copy any `Opatch` patches to `<work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/opatch_patch/`.
  
  * Copy the rest of the patches to `<work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/patches/`.
  
  * Run the following command to change the permissions on the patch files: 
  
    `$ chmod 644 <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/patches/*`

	  `$ chmod 644 <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/opatch_patch/*	`
		
### Building the Oracle Identity Governance 12.2.1.x image

  1. Run the following to set the proxy server appropriately. This is required so the build process can pull the relevant Linux packages via yum:

    $ export http_proxy=http://<proxy_server_hostname>:<proxy_server_port>
    $ export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>
	
  2. Run the following command to build the OIG image:

    $ cd <work directory>/docker-images/OracleIdentityGovernance/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4.0

   The output should look similar to the following:
    
    version --> 12.2.1.4.0
    Proxy settings were found and will be used during build.
    Building image 'oracle/oig:12.2.1.4.0' ...
    Proxy Settings ' --build-arg http_proxy=http://proxy.example.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg'
    Sending build context to Docker daemon  1.471GB
    Step 1/15 : FROM fmw-soa:12.2.1.4.0

...

    OPatch succeeded.
    Removing intermediate container 04434d5f71f4
     ---> a1b93666eec6
    Step 15/15 : CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
     ---> Running in 94cd000b0c83
    Removing intermediate container 94cd000b0c83
     ---> b7073c584105
    Successfully built b7073c584105
    Successfully tagged oracle/oig:12.2.1.4.0

      Oracle OIM suite Docker Image for version: 12.2.1.4.0 is ready to be extended.

        --> oracle/oig:12.2.1.4.0

      Build completed in 746 seconds.

  3. Run the `docker images` command to show the OIG image is installed into the repository:
    
	$ docker images
    
   The output should look similar to the following:
   
    REPOSITORY                                                  TAG             IMAGE ID      CREATED             SIZE
    oracle/oig                                                  12.2.1.4.0      b7073c584105  3 minutes ago       7.88GB
	container-registry.oracle.com/soasuite                      2.2.1.4-200612  9e9262639994  6 weeks ago         2.32GB
    oracle/soasuite                                             12.2.1.4.0      9e9262639994  6 weeks ago         2.32GB

   The OIG image is now built successfully! 
   
   To create OIG Docker containers refer to the **OIG Docker Container Configuration** below.

## OIG Docker Container Configuration
 
 To configure the OIG Docker Containers follow the tutorial [Creating Oracle Identity Governance Docker Containers](https://docs.oracle.com/en/middleware/idm/identity-governance/12.2.1.4/tutorial-oig-docker/)

## OIG Kubernetes Configuration

To configure the OIG Containers with Kubernetes see the [Oracle Identity Governance on Kubernetes](https://oracle.github.io/fmw-kubernetes/oig/) documentation. 
 
# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleIdentityGovernance](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

	
