Oracle Database on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](http://docs.oracle.com/database/121/index.htm).

## How to build and run
This project offers sample Dockerfiles for:
 * Oracle Database 12c Release 2 (12.2.0.1) Enterprise Edition and Standard Edition 2
 * Oracle Database 12c Release 1 (12.1.0.2) Enterprise Edition and Standard Edition 2
 * Oracle Database 11g Release 2 (11.2.0.2) Express Edition.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle Database Docker Install Images
**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html). You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root or with `sudo` privileges:

	[oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h
	
	Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-i]
	Builds a Docker Image for Oracle Database.
	
	Parameters:
	   -v: version to build
	       Choose one of: 11.2.0.2  12.1.0.2  12.2.0.1
	   -e: creates image based on 'Enterprise Edition'
	   -s: creates image based on 'Standard Edition 2'
	   -x: creates image based on 'Express Edition'
	   -i: ignores the MD5 checksums
	
	* select one edition only: -e, -s, or -x
	
	LICENSE CDDL 1.0 + GPL 2.0
	
	Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will be an image with the Oracle binaries installed. On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:

	#########################
	DATABASE IS READY TO USE!
	#########################

You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

The character set for the database is set during creating of the database. 11g Express Edition supports only UTF-8. You can set the character set for the Standard Edition 2 and Enterprise Edition during the first run of your container and may keep separate folders containing different tablespaces with different character sets.

### Running Oracle Database in a Docker container

#### Running Oracle Database Enterprise and Standard Edition 2 in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

	docker run --name <container name> \
	-p <host port>:1521 -p <host port>:5500 \
	-e ORACLE_SID=<your SID> \
	-e ORACLE_PDB=<your PDB name> \
	-e ORACLE_PWD=<your database passwords> \
	-e ORACLE_CHARACTERSET=<your character set> \
	-v [<host mount point>:]/opt/oracle/oradata \
	oracle/database:12.2.0.1-ee
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   -p:            The port mapping of the host port to the container port. 
	                  Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express)
	   -e ORACLE_SID: The Oracle Database SID that should be used (default: ORCLCDB)
	   -e ORACLE_PDB: The Oracle Database PDB name that should be used (default: ORCLPDB1)
	   -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated)
	   -e ORACLE_CHARACTERSET:
	                  The character set to use when creating the database (default: AL32UTF8)
	   -v /opt/oracle/oradata
	                  The data volume to use for the database.
	                  Has to be owned by the Unix user "oracle" or set appropriately.
	                  If omitted the database will not be persisted over container recreation.
	   -v /opt/oracle/scripts/startup
	                  Optional: A volume with custom scripts to be run after database startup.
	                  For further details see the "Running scripts after setup and on startup" section below.
	   -v /opt/oracle/scripts/setup
	                  Optional: A volume with custom scripts to be run after database setup.
	                  For further details see the "Running scripts after setup and on startup" section below.

Once the container has been started and the database created you can connect to it just like to any other database:

	sqlplus sys/<your password>@//localhost:1521/<your SID> as sysdba
	sqlplus system/<your password>@//localhost:1521/<your SID>
	sqlplus pdbadmin/<your password>@//localhost:1521/<Your PDB name>

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

	https://localhost:5500/em/

**NOTE**: Oracle Database bypasses file system level caching for some of the files by using the `O_DIRECT` flag. It is not advised to run the container on a file system that does not support the `O_DIRECT` flag.

#### Changing the admin accounts passwords

On the first startup of the container a random password will be generated for the database if not provided. You can find this password in the output line:  
	
	ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN:

The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:

	docker exec <container name> ./setPassword.sh <your password>

#### Running Oracle Database Express Edition in a Docker container
To run your Oracle Database Express Edition Docker image use the **docker run** command as follows:

	docker run --name <container name> \
	--shm-size=1g \
	-p 1521:1521 -p 8080:8080 \
	-e ORACLE_PWD=<your database passwords> \
	-v [<host mount point>:]/u01/app/oracle/oradata \
	oracle/database:11.2.0.2-xe
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   --shm-size:    Amount of Linux shared memory
	   -p:            The port mapping of the host port to the container port.
	                  Two ports are exposed: 1521 (Oracle Listener), 8080 (APEX)
	   -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated)

	   -v /u01/app/oracle/oradata
	                  The data volume to use for the database.
	                  Has to be owned by the Unix user "oracle" or set appropriately.
	                  If omitted the database will not be persisted over container recreation.
	   -v /u01/app/oracle/scripts/startup
	                  Optional: A volume with custom scripts to be run after database startup.
	                  For further details see the "Running scripts after setup and on startup" section below.
	   -v /u01/app/oracle/scripts/setup
	                  Optional: A volume with custom scripts to be run after database startup.
	                  For further details see the "Running scripts after setup and on startup" section below.

There are two ports that are exposed in this image:
* 1521 which is the port to connect to the Oracle Database.
* 8080 which is the port of Oracle Application Express (APEX).

On the first startup of the container a random password will be generated for the database if not provided. You can find this password in the output line:
	ORACLE PASSWORD FOR SYS AND SYSTEM:

The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:
	docker exec oraclexe /u01/app/oracle/setPassword.sh <your password>

Once the container has been started you can connect to it just like to any other database:

	sqlplus sys/<your password>@//localhost:1521/XE as sysdba
	sqlplus system/<your password>@//localhost:1521/XE

### Running SQL*Plus in a Docker container
You may use the same Docker image you used to start the database, to run `sqlplus` to connect to it, for example:

	docker run --rm -ti oracle/database:12.2.0.1-ee sqlplus pdbadmin/<yourpassword>@//<db-container-ip>:1521/ORCLPDB1

Another option is to use `docker exec` and run `sqlplus` from within the same container already running the database:

	docker exec -ti <container name> sqlplus pdbadmin@ORCLPDB1

### Running scripts after setup and on startup
The docker images can be configured to run scripts after setup and on startup. Currently `sh` and `sql` extensions are supported.
For post-setup scripts just mount the volume `/opt/oracle/scripts/setup` or extend the image to include scripts in this directory.
For post-startup scripts just mount the volume `/opt/oracle/scripts/startup` or extend the image to include scripts in this directory.

After the database is setup and/or started the scripts in those folders will be executed against the database in the container.
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user. To ensure proper order it is
recommended to prefix your scripts with a number. For example `01_users.sql`, `02_permissions.sql`, etc.

**Note:** The startup scripts will also be executed after the first time database setup is complete.

The example below mounts the local directory myScripts to `/opt/oracle/myScripts` which is then searched for custom startup scripts:

    docker run --name oracle-ee -p 1521:1521 -v /home/oracle/myScripts:/opt/oracle/scripts/startup -v /home/oracle/oradata:/opt/oracle/oradata oracle/database:12.2.0.1-ee
    

## Known issues
* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

## Support
Oracle Database in single instance configuration is supported for Oracle Linux 7 and Red Hat Enterprise Linux (RHEL) 7.
For more details please see My Oracle Support note: **Oracle Support for Database Running on Docker (Doc ID 2216342.1)**

## License
To download and run Oracle Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
