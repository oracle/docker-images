Oracle GoldenGate for Oracle on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. 

For more information about Oracle GoldenGate 12c please see the Oracle GoldenGate Online Documentation at http://docs.oracle.com/goldengate/c1221/gg-winux/index.html.

For more information about Oracle Database 12c, please see the Oracle Database Online Documentaion at http://docs.oracle.com/en/database/index.html.

## How to build Oracle GoldenGate for Oracle on Docker
This project offers sample Dockerfile and other associated file for this build:
 * V100691-01.zip (Oracle GoldenGate 12c for MySQL(12.2.0.1.1))
 * mysql-community-server-minimal-5.7.18-1.el7.x86_64.rpm (MySQL Community Edition 5.7.18)
 * Dockerfile - Build file for Docker image
 * entrypoint.sh - steps required to install MySQL 5.7 and Oracle GoldenGate 12c

To rebuild the Oracle GoldenGate for MySQL Docker image, use the following command:

	docker build -t oggmysql:12.2.0.1.1 -f Dockerfile .
 
## Running Oracle GoldenGate for Oracle in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

	docker run -d --privileged --name oggmysql \
	-p 3306:3306 \
	-p 1700:1700 \
	oggmysql:12.2.0.1.1
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   -p:            The port mapping of the host port to the container port. 
	                  Three ports are exposed: 
	                  	- 3306 (MySQL Listener) 
	                  	- 1700 (OGG Manager Port (non-default))

Once the container has been started and the database created you can connect to it just like to any other database:

	mysql -uroot -p 


To access Oracle GoldenGate 12c, run the following from the command line:

	$OGG_HOME/ggsci

### Running SQL*Plus in a Docker container
You may use the same Docker image you used to start the database, to run `sqlplus` to connect to it, for example:

	docker exec -ti <container name> mysql -uroot -p

## Known issues
* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

*PATH environment variable is not set correctly after being built.  

## Support (XXX) 
MySQL Database support Docker
For more details please see My Oracle Support note: **Mysql Support On VMWare (Doc ID 1383964.1)**

## License
To download and run MySQL Database or Oracle GoldenGate, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.