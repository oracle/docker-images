Oracle REST Data Services on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. 
For more information about Oracle REST Data Services (ORDS) please see the [ORDS Documentation](http://www.oracle.com/technetwork/developer-tools/rest-data-services/documentation/index.html).

## How to build and run
This project offers sample Dockerfiles for:
 * Oracle REST Data Services 3.0.10
 
To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle REST Data Services Install Images
**IMPORTANT:** You will have to provide the installation binaries of ORDS and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the version you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html). You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which version you want to build an image of, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root or with `sudo` privileges:

    [root@localhost dockerfiles]# ./buildDockerImage.sh -h
    
    Usage: buildDockerImage.sh -v [version] [-i]
    Builds a Docker Image for Oracle Rest Data Services
    
    Parameters:
       -v: version to build
            Choose one of: 3.0.10
       -i: ignores the MD5 checksums
    
    LICENSE UPL 1.0
    
    Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.


**IMPORTANT:** The resulting images will be an image with the ORDS binaries installed. On first startup of the container ORDS will be setup.

### Running Oracle REST Data Services in a Docker container

To run your ORDS Docker image use the **docker run** command as follows:

	docker run --name <container name> \
	-p <host port>:8888 \
	-e ORACLE_HOST=<Your Oracle DB host (default: localhost)> \
	-e ORACLE_PORT=<Your Oracle DB port (default: 1521)> \
	-e ORACLE_SERVICE=<your Oracle DB Service name (default: ORCLPDB1)> \
	-e ORACLE_PWD=<your database password> \
	-e ORDS_PWD=<your ORDS password> \
	oracle/restdataservices:3.0.10
	
	Parameters:
	   --name:            The name of the container (default: auto generated)
	   -p:                The port mapping of the host port to the container port. 
	                      One port is exposed: 8888
	   -e ORACLE_HOST:    The Oracle Database hostname that ORDS should use (default: localhost)
	   -e ORACLE_PORT:    The Oracle Database port that ORSD should use (default: 1521)
	   -e ORACLE_SERVICE: The Oracle Database Service name that ORDS should use (default: ORCLPDB1)
	   -e ORACLE_PWD:     The Oracle Database SYS password
	   -e ORDS_PWD:       The ORDS_PUBLIC_USER password

Once the container has been started and ORDS configured you can send REST calls to ORDS.


## Known issues
None

## Support

## License
To download and run ORDS, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleRestDataServices](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License (UPL), Version 1.0.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
