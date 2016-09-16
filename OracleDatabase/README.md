Oracle Database on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](http://docs.oracle.com/database/121/index.htm).

## How to build and run
This project offers sample Dockerfiles for both Oracle Database 12c (12.1.0.2) Enterprise Edition and Standard Edition as well as Oracle Database 11g Express Edition. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle Database Docker Install Images
**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install. You also have to make sure to have internet connectivity for yum.

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root or with `sudo` privileges:

	[oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h

	Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-i]
	Builds a Docker Image for Oracle Database.
	
	Parameters:
	   -v: version to build
	       Choose one of: 11.2.0.2  12.1.0.2
	   -e: creates image based on 'Enterprise Edition'
	   -s: creates image based on 'Standard Edition 2'
	   -x: creates image based on 'Express Edition'
	   -i: ignores the MD5 checksums
	
	* select one edition only: -e, -s, or -x

	LICENSE CDDL 1.0 + GPL 2.0

	Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will be an image with the Oracle binaries installed. On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:

	#########################
	DATABASE IS READY TO USE!
	#########################

You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

### Running Oracle Database in a Docker container

#### Running Oracle Database Enterprise and Standard Edition in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

	docker run --name oracle -p 1521:1521 -p 5500:5500 -e ORACLE_SID=<your SID> -e ORACLE_PDB=<your PDB name> oracle/database:12.1.0.2-ee
	
	Parameters:
	   --name: The name of the container itself
	   -p:     The port mapping of the host port to the container port. Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express)
	   -e ORACLE_SID: The Oracle Database SID that should be used (default: ORCLCDB)
	   -e ORACLE_PDB: The Oracle Database PDB name that should be used (default: ORCLPDB1)

Once the container has been started and the database created you can connect to it just like to any other database:

	sqlplus sys/<your password>@//localhost:1521/<your SID> as sysdba
	sqlplus system/<your password>@//localhost:1521/<your SID>
	sqlplus pdbadmin/<your password>@//localhost:1521/<Your PDB name>

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

	https://localhost:5500/em/

#### Changing the admin accounts passwords

On the first startup of the container a random password will be generated for the database. You can find this password in the output line:  
	
	ORACLE AUTO GENERATED PASSWORD FOR SYS, SYSTEM AND PDBAMIN:

The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:
	docker exec oracle ./setPassword.sh <your password>

#### Running Oracle Database Express Edition in a Docker container
To run your Oracle Database Express Edition Docker image use the **docker run** command as follows:

	docker run --name oraclexe --shm-size=1g -p 1521:1521 -p 8080:8080 oracle/database:11.2.0.2-xe
	
	Parameters:
	   --name: The name of the container itself
	   --shm-size: Amount of Linux shared memory
	   -p:     The port mapping of the host port to the container port. Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express)

There are two ports that are exposed in this image:
* 1521 which is the port to connect to the Oracle Database.
* 8080 which is the port of Oracle Application Express (APEX).

On the first startup of the container a random password will be generated for the database. You can find this password in the output line:
	ORACLE AUTO GENERATED PASSWORD FOR SYS AND SYSTEM:

The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:
	docker exec oraclexe /u01/app/oracle/setPassword.sh <your password>

Once the container has been started you can connect to it just like to any other database:

	sqlplus sys/<your password>@//localhost:1521/XE as sysdba
	sqlplus system/<your password>@//localhost:1521/XE

### Running SQL*Plus in a Docker container
You may use the same Docker image you used to start the database, to run `sqlplus` to connect to it, for example:

	docker run --rm -ti oracle/database:12.1.0.2-ee sqlplus pdbadmin/<yourpassword>@//<db-container-ip>:1521/ORCLPDB1

Another option is to use `docker exec` and run `sqlplus` from within the same container already running the database:

	docker exec -ti <container-id> sqlplus pdbadmin@ORCLPDB1

## Support
Currently Oracle Database on Docker is **NOT** supported by Oracle. Use these files at your own discretion.

## License
To download and run Oracle Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
