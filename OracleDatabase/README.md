Oracle Database on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](http://docs.oracle.com/database/121/index.htm).

## How to build and run
This project offers sample Dockerfiles for both Oracle Database 12c (12.1.0.2) Enterprise Edition and Standard Edition as well as Oracle Database 11g Express Edition. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle Database Docker Install Images
**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install.

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root or with `sudo` privileges:

	[oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h
	
	Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-p] [-i]
	Builds a Docker Image for Oracle Database.
	
	Parameters:
	   -v: version to build
	       Choose one of: 11.2.0.2  12.1.0.2
	   -e: creates image based on 'Enterprise Edition'
	   -s: creates image based on 'Standard Edition 2'
	   -x: creates image based on 'Express Edition'
	   -p: password for database admin accounts (it will be generated if omitted)
	   -i: ignores the MD5 checksums
	
	* select one edition only: -e, -s, or -x
	
	LICENSE CDDL 1.0 + GPL 2.0
	
	Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will be an newly installed Oracle Database. You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

### Running Oracle Database in a Docker container

#### Running Oracle Database Enterprise and Standard Edition in a Docker container
To run your Oracle Database Docker image just use the **docker run** command as follows:

	docker run -p 1521:1521 -p 5500:5500 oracle/database:12.1.0.2-ee

There are two ports that are exposed in this image:
* 1521 which is the port to connect to the Oracle Database.
* 5500 which is the port of Oracle Enterprise Manager Express.

The admin accounts created are:
* sys (SYSDBA for ORCLCDB and ORCLPDB1)
* system (DBA for ORCLCDB and ORCLPDB1)
* pdbadmin (DBA for ORCLPDB1)

Once the container has been started you can connect to it just like to any other database:

	sqlplus system/<your password>@//localhost:1521/ORCLCDB
	sqlplus pdbadmin/<your password>@//localhost:1521/ORCLPDB1

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

	https://localhost:5500/em/

#### Running Oracle Database Express Edition in a Docker container
To run your Oracle Database Express Edition Docker image just use the **docker run** command as follows:

	docker run --shm-size=1g -p 1521:1521 -p 8080:8080 oracle/database:11.2.0.2-xe

There are two ports that are exposed in this image:
* 1521 which is the port to connect to the Oracle Database.
* 8080 which is the port of Oracle Application Express (APEX).

The admin accounts created are:
* sys (SYSDBA)
* system (DBA)

Once the container has been started you can connect to it just like to any other database:

	sqlplus system/<your password>@//localhost:1521/XE

### Running SQL*Plus in a Docker container
You may use the same Docker image you used to start the database, to run `sqlplus` to connect to it, for example:

        docker run --rm -ti oracle/database:12.1.0.2-ee sqlplus pdbadmin/<yourpassword>@//<db-container-ip>:1521/ORCLPDB1

## License
To download and run Oracle Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
