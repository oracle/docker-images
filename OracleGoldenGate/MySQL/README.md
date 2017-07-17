Oracle GoldenGate for MySQL on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. 

For more information about Oracle GoldenGate 12c please see the Oracle GoldenGate Online Documentation at http://docs.oracle.com/goldengate/c1221/gg-winux/index.html.

For more information about Oracle MySQL, please see the Oracle MySQL Online Documentaion at http://docs.oracle.com/cd/E17952_01/index.html.

## How to build Oracle GoldenGate for MySQL database on Docker
This project offers sample Dockerfile and other associated file for this build:
 * ggs_Linux_x64_MySQL_64bit.zip (Oracle GoldenGate 12c for MySQL(12.2.0.1.1))
 * Dockerfile - Build file for Docker image
 * ogg_cnf.txt - GoldenGate requirement for log capture
 * ogg_inst.txt - Additional OGG specific installation to entrypoint.sh
 * ogg_func.txt - Additional script functions to entrypoint.sh

To rebuild the Oracle GoldenGate for MySQL Docker image, use the following command:

	docker build -t oggmysql:12.2.0.1.1 -f Dockerfile .
 
## Running Oracle GoldenGate for MySQL database in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

	docker run -d --name oggmysql \
	-p 3306:3306 \
	-p 1700:1700 \
        -e MYSQL_ROOT_PASSWORD=<your root password>
	oggmysql:12.2.0.1.1
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   -p:            The port mapping of the host port to the container port. 
	                  Three ports are exposed: 
	                  	- 3306 (MySQL Listener) 
	                  	- 1700 (OGG Manager Port (non-default))
           -e:            MYSQL_ROOT_PASSWORD is required by MySQL Docker image 

Once the container has been started and the database created you can connect to it just like to any other database:

	mysql -uroot -p 


To access Oracle GoldenGate 12c, run the following from the command line:

	$OGG_HOME/ggsci

### Running mysql cli in a Docker container
You may use the same Docker image you used to start the database, to run `mysql` to connect to it, for example:

	docker exec -ti <container name> mysql -uroot -p

## Known issues
* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

*PATH environment variable is not set correctly after being built.  

## Support 
MySQL Database support Docker
For more details please see My Oracle Support note: **Mysql Support On VMWare (Doc ID 1383964.1)**

## License
To download and run MySQL Database or Oracle GoldenGate, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleGoldenGate/MySQL](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
