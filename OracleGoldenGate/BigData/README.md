Oracle GoldenGate for Oracle on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. 

For more information about Oracle Database 12c for BigData, please see the Oracle Database Online Documentaion at http://docs.oracle.com/goldengate/bd1221/gg-bd/index.html.

## How to build Oracle GoldenGate for Oracle on Docker
This project offers sample Dockerfile and other associated file for this build:
 * V839824-01.zip (Oracle GoldenGate 12c for BigData (12.3.0.1))
 * Dockerfile - Build file for Docker image
 * entrypoint.sh - steps required to install Oracle Database 12c and Oracle GoldenGate 12c

To rebuild the Oracle GoldenGate for Oracle Docker image, use the following command:

	docker build -t oggbd:12.3.0.1 -f Dockerfile .
 
## Running Oracle GoldenGate for Oracle in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

	docker run -d --name oggbd \
	-p 9500:9500 \
	oggbd:12.3.0.1
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   -p:            The port mapping of the host port to the container port. 
	                  Three ports are exposed: 
	                  	- 9500 (OGG Manager Port (non-default))

To access Oracle GoldenGate 12c, run the following from the command line:

	$OGG_HOME/ggsci

### Running GGSCI in a Docker container
You may use the same Docker image you used to start the database, to run `sqlplus` to connect to it, for example:

	docker exec -ti <container name> ggsci

## Known issues
* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

*PATH environment variable is not set correctly after being built.  

## Support
Oracle Database in single instance configuration is supported for Oracle Linux 7 and Red Hat Enterprise Linux (RHEL) 7.

## License
To download and run Oracle Database or Oracle GoldenGate, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
