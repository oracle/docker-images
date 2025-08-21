# Oracle Database container images

Sample container build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

* [How to build and run](#how-to-build-and-run)
  * [Building Oracle Database container images](#building-oracle-database-container-images)
    * [Building patched container images](#building-patched-container-images)
    * [Building the container images using Podman](#building-the-container-images-using-podman)
  * [Running Oracle Database in a container](#running-oracle-database-in-a-container)
    * [Running Oracle Database Enterprise and Standard Edition 2 in a container](#running-oracle-database-enterprise-and-standard-edition-2-in-a-container)
    * [Securely specifying the password when using Podman (Supported from 19.3.0 onwards)](#securely-specifying-the-password-when-using-podman-supported-from-1930-onwards)
      * [Encrypting the database password (Supported from 23ai onwards))](#encrypting-the-database-password-supported-from-23ai-onwards)
    * [Selecting the Edition (Supported from 19.3.0 release)](#selecting-the-edition-supported-from-1930-release)
    * [Setting the SGA and PGA memory (Supported from 19.3.0 release)](#setting-the-sga-and-pga-memory-supported-from-1930-release)
    * [Setting the CPU_COUNT and PROCESSES (Supported from 19.3.0 release)](#setting-the-cpu_count-and-processes-supported-from-1930-release)
    * [Changing the admin accounts passwords](#changing-the-admin-accounts-passwords)
    * [Enabling archive log mode and/or force logging mode while creating the database](#enabling-archive-log-mode-andor-force-logging-mode-while-creating-the-database)
    * [Configuring TCPS connections for Oracle Database (Supported from version 19.3.0 onwards)](#configuring-tcps-connections-for-oracle-database-supported-from-version-1930-onwards)
    * [Running Oracle Database 23ai Free in a container](#running-oracle-database-23ai-free-in-a-container)
    * [Running Oracle Database 21c/18c Express Edition in a container](#running-oracle-database-21c18c-express-edition-in-a-container)
    * [Running Oracle Database 11gR2 Express Edition in a container](#running-oracle-database-11gr2-express-edition-in-a-container)
  * [Running Oracle True Cache in a container (Supported from version 23ai onwards)](#running-oracle-true-cache-in-a-container-supported-from-version-23ai-onwards)
    * [Setting Up the Network for Communication Between the Primary Database and the True Cache Container](#setting-up-the-network-for-communication-between-the-primary-database-and-the-true-cache-container)
    * [Running Oracle Database Free True Cache in a Container](#running-oracle-database-free-true-cache-in-a-container)
  * [Containerizing an on-premise database (Supported from version 19.3.0 release)](#containerizing-an-on-premise-database-supported-from-version-1930-release)
  * [Deploying Oracle Database on Kubernetes](#deploying-oracle-database-on-kubernetes)
  * [Running SQL*Plus in a container](#running-sqlplus-in-a-container)
  * [Running scripts after setup and on startup](#running-scripts-after-setup-and-on-startup)
* [Known issues](#known-issues)
* [Frequently asked questions](#frequently-asked-questions)
* [Support](#support)
* [License](#license)
* [Copyright](#copyright)

## How to build and run

This project offers sample Dockerfiles for:

* Oracle Database 23ai (23.9.0) Free
* Oracle Database 21c (21.3.0) Enterprise Edition, Standard Edition 2 and Express Edition (XE)
* Oracle Database 19c (19.3.0) Enterprise Edition and Standard Edition 2
* Oracle Database 18c (18.4.0) Express Edition (XE)
* Oracle Database 18c (18.3.0) Enterprise Edition and Standard Edition 2
* Oracle Database 12c Release 2 (12.2.0.2) Enterprise Edition and Standard Edition 2
* Oracle Database 12c Release 1 (12.1.0.2) Enterprise Edition and Standard Edition 2
* Oracle Database 11g Release 2 (11.2.0.2) Express Edition (XE)

To assist in building the images, you can use the [buildContainerImage.sh](dockerfiles/buildContainerImage.sh) script. See below for instructions and usage.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` or `podman build` with their preferred set of parameters.

### Building Oracle Database container images

**IMPORTANT:** You will have to provide the installation binaries of Oracle Database (except for Oracle Database 18c XE, 21c XE and 23ai Free) and put them into the `dockerfiles/<version>` folder.
You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html), make sure you use the linux link: *Linux x86-64*. The needed file is named *linuxx64_\<version\>_database.zip*.

**Linux ARM64 Support:** Oracle Database 19c Enterprise Edition and 23ai Free Edition are now supported on ARM64 platforms. You will have to provide the installation binaries of [Oracle Database 19c](https://www.oracle.com/database/technologies/oracle19c-linux-arm64-downloads.html) and put them into the dockerfiles/19.3.0 folder. The needed file is named *LINUX.ARM64_1919000_db_home.zip*.

You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the **dockerfiles** folder and run the **buildContainerImage.sh** script:

    [oracle@localhost dockerfiles]$ ./buildContainerImage.sh -h
    
    Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-e | -s | -x | -f] [-i] [-p] [-b] [-o] [container build option]
    Builds a container image for Oracle Database.
    
    Parameters:
       -v: version to build
           Choose one of: 11.2.0.2  12.1.0.2  12.2.0.1  18.3.0  18.4.0  19.3.0  21.3.0 23.9.0
       -t: image_name:tag for the generated docker image
       -e: creates image based on 'Enterprise Edition'
       -s: creates image based on 'Standard Edition 2'
       -x: creates image based on 'Express Edition'
       -f: creates image based on Database 'Free'
       -i: ignores the MD5 checksums
       -p: creates and extends image using the patching extension
       -b: build base stage only (Used by extensions)
       -o: passes on container build option
    
    * select one edition only: -e, -s, -x, or -f
    
    LICENSE UPL 1.0
    
    Copyright (c) 2014,2024 Oracle and/or its affiliates.

**IMPORTANT:** The resulting images will be an image with the Oracle binaries installed. On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:

    #########################
    DATABASE IS READY TO USE!
    #########################

You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

The character set for the database is set during creating of the database. 11gR2 Express Edition supports only UTF-8.
You can set the character set for the Standard Edition 2 and Enterprise Edition during the first run of your container and may keep separate folders containing different tablespaces with different character sets.

#### Building patched container images

**NOTE**: This section is intended for container images 19c or higher which has patching extension support. By default, SLIMMING is **true** to remove some components from the image with the intention of making the image slimmer. These removed components cause problems while patching after building patching extension.
So, to use patching extension one should use additional build argument `-o '--build-arg SLIMMING=false'` while building the container image. Example command for building the container image is as follows:

    ./buildContainerImage.sh -e -v 21.3.0 -o '--build-arg SLIMMING=false'

Patched container images can now be built by specifying the parameter -p. Download the database version specific release update and one-offs and place them under `extensions/patching/patches/release_update` and `extensions/patching/patches/one_offs` folder respectively.
If opatch is required, download and place the zip file for patch 6880880 under `extensions/patching/patches/one_offs` folder. In this case, SLIMMING is internally set to **false**. Example command for building the patched container image is as follows:

    ./buildContainerImage.sh -e -v 21.3.0 -p

#### Building the container images using Podman

Building Oracle Database container images using Podman is similar to Docker. Some additional environment variables are required to be set for proper functioning. The description is as follows:

* `export BUILDAH_FORMAT=docker` (Required to support `HEALTHCHECK` specified in the Dockerfile)
* `export BUILDAH_ISOLATION=chroot` (Required while building the container image in rootless mode)

After setting these environment variables, the container image can be built using `buildContainerImage.sh` script as follows:

    ./buildContainerImage.sh -e -v <version-to-build>

### Running Oracle Database in a container

#### Running Oracle Database Enterprise and Standard Edition 2 in a container

To run your Oracle Database image use the `docker run` command as follows:

    docker run --name <container name> \
    -p <host port>:1521 -p <host port>:5500 -p <host port>:2484 \
    --ulimit nofile=1024:65536 --ulimit nproc=2047:16384 --ulimit stack=10485760:33554432 --ulimit memlock=3221225472 \
    -e ORACLE_SID=<your SID> \
    -e ORACLE_PDB=<your PDB name> \
    -e ORACLE_PWD=<your database passwords> \
    -e INIT_SGA_SIZE=<your database SGA memory in MB> \
    -e INIT_PGA_SIZE=<your database PGA memory in MB> \
    -e INIT_CPU_COUNT=<cpu_count init-parameter> \
    -e INIT_PROCESSES=<processes init-parameter> \
    -e ORACLE_EDITION=<your database edition> \
    -e ORACLE_CHARACTERSET=<your character set> \
    -e ENABLE_ARCHIVELOG=true \
    -e ENABLE_FORCE_LOGGING=true \
    -e ENABLE_TCPS=true \
    -v [<host mount point>:]/opt/oracle/oradata \
     oracle/database:21.3.0-ee
    
    Parameters:
       --name:        The name of the container (default: auto generated).
       -p:            The port mapping of the host port to the container port.
                      The following ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express), 2484 (TCPS Listener Port if TCPS is enabled).
       --ulimit:      Resource limits. Update according to Oracle Database documentation.
       -e ORACLE_SID: The Oracle Database SID that should be used (default for 23ai Free Edition: FREE; all others, ORCLCDB).
                      Note: The ORACLE_SID for 11g/18c Express and 23ai Free Editions cannot be changed.
       -e ORACLE_PDB: The Oracle Database PDB name that should be used (default for 23ai Free Edition: FREEPDB1; all others, ORCLPDB1).
                      Note: The ORACLE_PDB for 23ai Free Edition cannot be changed.
       -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDBADMIN password (default: auto generated).
       -e INIT_SGA_SIZE:
                      The total memory in MB that should be used for all SGA components (optional).
                      Supported by Oracle Database 19.3 onwards.
       -e INIT_PGA_SIZE:
                      The target aggregate PGA memory in MB that should be used for all server processes attached to the instance (optional).
                      Supported by Oracle Database 19.3 onwards.
       -e INIT_CPU_COUNT:
                      Specifies the number of CPUs available for Oracle Database to use. 
                      On CPUs with multiple CPU threads, it specifies the total number of available CPU threads (optional).
       -e INIT_PROCESSES:
                      Specifies the maximum number of operating system user processes that can simultaneously connect to Oracle Database. 
                      Its value should allow for all background processes such as locks, job queue processes, and parallel execution processes (optional).
       -e AUTO_MEM_CALCULATION:
                      To enable auto calculation of the DBCA total memory limit during the database creation, based on
                      the available memory of the container, which can be constrained using the `docker run --memory`
                      option. If set to 'false', the total memory will be set as 2GB (default: true).
                      Note that this parameter is not taken into account if the `-e INIT_SGA_SIZE` or `-e INIT_PGA_SIZE`
                      are set.
                      Supported by Oracle Database 19.3 onwards.
       -e ORACLE_EDITION:
                      The Oracle Database Edition (enterprise/standard).
                      Supported by Oracle Database 19.3 onwards.
       -e ORACLE_CHARACTERSET:
                      The character set to use when creating the database (default: AL32UTF8).
       -e ENABLE_ARCHIVELOG:
                      To enable archive log mode when creating the database (default: false).
                      Supported by Oracle Database 19.3 onwards.
       -e ENABLE_FORCE_LOGGING:
                      To enable force logging mode when creating the database (default: false).
                      Supported by Oracle Database 23ai onwards.
       -e ENABLE_TCPS:
                      To enable TCPS connections for Oracle Database.
                      Supported by Oracle Database 19.3 onwards.
       -e TCPS_CERTS_LOCATION:
                      Location of user provided SSL certificates for TCPS connection
                      Supported by Oracle Database 19.3 onwards.
       -v /opt/oracle/oradata
                      The data volume to use for the database.
                      Has to be writable by the Unix "oracle" (uid: 54321) user inside the container.
                      If omitted the database will not be persisted over container recreation.
       -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                      Optional: A volume with custom scripts to be run after database startup.
                      For further details see the "Running scripts after setup and on startup" section below.
       -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                      Optional: A volume with custom scripts to be run after database setup.
                      For further details see the "Running scripts after setup and on startup" section below.

Once the container has been started and the database created you can connect to it just like to any other database:

    sqlplus sys/<your password>@//localhost:1521/<your service name> as sysdba
    sqlplus system/<your password>@//localhost:1521/<your service name>
    sqlplus pdbadmin/<your password>@//localhost:1521/<Your PDB name>

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

    https://localhost:5500/em/

**NOTE**: Oracle Database bypasses file system level caching for some of the files by using the `O_DIRECT` flag. It is not advised to run the container on a file system that does not support the `O_DIRECT` flag.

#### Securely specifying the password when using Podman (Supported from 19.3.0 onwards)

`Podman secret` is supported if the user uses the podman runtime and needs to specify the password to the container securely. The user needs to create a secret first with the name **oracle_pwd**, and then run the container image after specifying the secret in the `run` command. The example commands are as follows:

    # Creating podman secret
    echo "<Your Password>" | podman secret create oracle_pwd -

    # Running the Oracle Database 21c XE image with the secret
    podman run -d --name=<container_name> --secret=oracle_pwd oracle/database:21.3.0-xe

##### Encrypting the database password (Supported from 23ai onwards)

Users can generate public-private key pair and pass database password (encrypted) and decryption (private) key to the container securely.

* Generate public-private key pair.

        openssl genrsa -out key.pem
        openssl rsa -in key.pem -out key.pub -pubout

* Create an Oracle Database password file.

        echo "<Your Password>" > pwd.txt

* Encrypt the password file using the public key (key.pub)

        openssl pkeyutl -in pwd.txt -out encrypted_pwd.txt -pubin -inkey key.pub -encrypt

    You should make sure you delete the pwd.txt once done

* Create a podman secret for both the encrypted password file and the decrytion key (key.pem).

        podman secret create oracle_pwd encrypted_pwd.txt
        podman secret create oracle_pwd_privkey key.pem

* Run the Oracle Database 23ai Free image with the secrets

        podman run -td --name=<container_name> --secret=oracle_pwd --secret=oracle_pwd_privkey oracle/database:23.9.0-free

#### Selecting the Edition (Supported from 19.3.0 release)

The edition of the database can be changed during runtime by passing the ORACLE_EDITION parameter to the `docker run` command. Therefore, an enterprise container image can be used to run standard edition database and vice-versa. You can find the edition of the running database in the output line:

    ORACLE EDITION:

This parameter modifies the software home binaries but it doesn't have any effect on the datafiles. So, if existing datafiles are reused to bring up the database, the same ORACLE_EDITION must be passed as the one used to create the datafiles for the first time.

#### Setting the SGA and PGA memory (Supported from 19.3.0 release)

The SGA and PGA memory can be set during the first time when database is created by passing the INIT_SGA_SIZE and INIT_PGA_SIZE parameters respectively to the `docker run` command. The user must provide the values in MB and without any units appended to the values (For example: -e INIT_SGA_SIZE=1536). These parameters are optional and dbca calculates these values if they aren't provided.

In case these parameters are passed to the `docker run` command while reusing existing datafiles, even though these values would be visible in the container environment, they would not be set inside the database. The values used at the time of database creation will be used.

#### Setting the CPU_COUNT and PROCESSES (Supported from 19.3.0 release)

The CPU_COUNT and PROCESSES init-parameters can be set during the first time when the database is created by passing the INIT_CPU_COUNT and INIT_PROCESSES parameters respectively to the `docker run` command. These parameters are optional.

In case these parameters are passed to the `docker run` command while reusing existing datafiles, even though these values would be visible in the container environment, they would not be set inside the database. The values used at the time of database creation will be used.

#### Changing the admin accounts passwords

On the first startup of the container, a random password will be generated for the database if not provided. The user has to mandatorily change the password after the database is created and the corresponding container is healthy.

The password for those accounts can be changed via the `docker exec` command. **Note**, the container has to be running:

    docker exec <container name> ./setPassword.sh <your password>

This new password will be used afterwards.

#### Enabling archive log mode and/or force logging mode while creating the database

Archive mode and/or force logging mode can be enabled during the first time when database is created by setting ENABLE_ARCHIVELOG and/or ENABLE_FORCE_LOGGING to `true` and passing them to `docker run` command. Archive logs are stored at the directory location: `/opt/oracle/oradata/$ORACLE_SID/archive_logs` inside the container.

In case these parameter are set `true` and passed to `docker run` command while reusing existing datafiles, even though these parameter would be visible as set to `true` in the container environment, these would not be set inside the database. The values used at the time of database creation will be used.

#### Configuring TCPS connections for Oracle Database (Supported from version 19.3.0 onwards)

There are two ways to enable TCPS connections for the database:

1. Enable TCPS while creating the database.

    * With Self Signed Certificates
        * Use the `-e ENABLE_TCPS=true` option with the `docker run` command. A listener endpoint will be created at the container port 2484 for TCPS.
    * With User provided SSL Certificates
        * Use the `-e ENABLE_TCPS=true` and `-e TCPS_CERTS_LOCATION=<location of certs in container>` option with the `docker run` command. Also mount a local host directory (containing `cert.crt` and `client.key`) at `TCPS_CERTS_LOCATION` using `-v` option.
        * `cert.cert` is a certificate chain in the order of client, followed by intermediate and then root certificate.

2. Enable TCPS after the database is created.

    * With Self Signed Certificates

            docker exec <container name> /opt/oracle/configTcps.sh

    * With User provided SSL Certificates
        * `cert.cert` is a certificate chain in the order of client, followed by intermediate and then root certificate.
        * Copy your `cert.crt` and `client.key` files into the container at `TCPS_CERTS_LOCATION` using the following command

                docker cp cert.crt client.key <container name>:<TCPS_CERTS_LOCATION>

        * Run following command to set up tcps connection using these certificates

                docker exec <container name> env TCPS_CERTS_LOCATION=<location of certs in container>  /opt/oracle/configTcps.sh

To disable TCPS connections for the database, please use the following command:

    # Disable TCPS in the database
    docker exec <container name> /opt/oracle/configTcps.sh disable

To configure  wallet password, please use the following command:

    # Setup TCPS for port 16002 and pass wallet password as argument
    docker exec <container name> /opt/oracle/configTcps.sh 16002 localhost <WALLET_PWD>

**NOTE**:

* Only database server authentication is supported (no mTLS).
* The container port at which TCPS listener is listening (i.e. 2484) should be exposed and mapped to some host port using `-p <host-port>:2484` option in the `docker run` command. It is required to connect to the database from the outside world using TCPS.
* When TCPS is enabled, a self-signed certificate will be created. For users' convenience, a client-side wallet is prepared and stored at the location `/opt/oracle/oradata/clientWallet/$ORACLE_SID`. You can use this client wallet along with SQL\*Plus to connect to the database. The sample command to download the client wallet is as follows:

        # ORACLE_SID default value is ORCLCDB
        docker cp <container name>:/opt/oracle/oradata/clientWallet/<ORACLE_SID> <destination wallet directory>

* The client wallet directory above will include wallet files, along with sample `sqlnet.ora` and `tnsnames.ora` files.
* To connect to the database via TCPS you can use SQL*Plus as shown:

        sqlplus sys@tcps://<host>:<port>/<service_name>?wallet_location=<destination wallet directory> as sysdba
        # Default value for host is localhost unless specified while running configTcps.sh
        # port is mapped port of host where container is running
        # destination wallet directory is where client wallet is copied to.

    OR

* Edit the `HOST` and `PORT` fields in the tnsnames.ora accordingly.
* After tnsnames.ora is modified, go inside the downloaded client wallet directory and set TNS_ADMIN for SQL*Plus by using the `export TNS_ADMIN=$(pwd)` command. Then users can connect via TCPS with, for example, the following commands:

        # Connecting Enterprise Edition
        sqlplus sys@ORCLCDB as sysdba
        # Connecting Express Edition
        sqlplus sys@XE as sysdba

* The certificate used with TCPS has validity for 1 year. After the certificate is expired, you can renew it using the following command:

        docker exec <container name> /opt/oracle/configTcps.sh

    After certificate renewal, the client wallet should be updated by downloading it again.
* Supports Oracle Database XE version 21.3.0 onwards.

#### Running Oracle Database 23ai Free in a container

To run your Oracle Database 23ai Free container image use the `podman run` command as follows:

    podman run --name <container name> \
    -p <host port>:1521 \
    -e ORACLE_PWD=<your database passwords> \
    -e ORACLE_CHARACTERSET=<your character set> \
    -e ENABLE_ARCHIVELOG=true \
    -e ENABLE_FORCE_LOGGING=true \
    -v [<host mount point>:]/opt/oracle/oradata \
    oracle/database:23.9.0-free
    
    Parameters:
       --name:        The name of the container (default: auto generated)
       -p:            The port mapping of the host port to the container port.
                      Only one port is exposed: 1521 (Oracle Listener)
       -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDBADMIN password (default: auto generated)
       -e ORACLE_CHARACTERSET:
                      The character set to use when creating the database (default: AL32UTF8)
       -e ENABLE_ARCHIVELOG: 
                      To enable archive log mode when creating the database (default: false)
       -e ENABLE_FORCE_LOGGING:
                      To enable force logging mode when creating the database (default: false)
       -v /opt/oracle/oradata
                      The data volume to use for the database.
                      Has to be writable by the Unix "oracle" (uid: 54321) user inside the container.
                      If omitted the database will not be persisted over container recreation.
       -v /opt/oracle/scripts/startup 
                      Optional: A volume with custom scripts to be run after database startup.
                      For further details see the "Running scripts after setup and on startup" section below.
       -v /opt/oracle/scripts/setup 
                      Optional: A volume with custom scripts to be run after database setup.
                      For further details see the "Running scripts after setup and on startup" section below.

Once the container has been started and the database created you can connect to it just like to any other database:

    sqlplus sys/<your password>@//localhost:1521/FREE as sysdba
    sqlplus system/<your password>@//localhost:1521/FREE
    sqlplus pdbadmin/<your password>@//localhost:1521/FREEPDB1

On the first startup of the container a random password will be generated for the database if not provided. The password for those accounts can be changed via the `podman exec` command. **Note**, the container has to be running:

    podman exec <container name> /opt/oracle/setPassword.sh <your password>

**Important Note:**
The ORACLE_SID for Oracle Database 23ai Free is always `FREE` and the PDB_NAME is always `FREEPDB1`. They cannot be changed, hence there are no ORACLE_SID or PDB_NAME parameters provided for the Free build.

#### Running Oracle Database 21c/18c Express Edition in a container

To run your Oracle Database 21c, or 18c Express Edition container image use the `docker run` command as follows:

    docker run --name <container name> \
    -p <host port>:1521 -p <host port>:5500 \
    -e ORACLE_PWD=<your database passwords> \
    -e ORACLE_CHARACTERSET=<your character set> \
    -v [<host mount point>:]/opt/oracle/oradata \
    oracle/database:21.3.0-xe
    
    Parameters:
       --name:        The name of the container (default: auto generated)
       -p:            The port mapping of the host port to the container port.
                      Two ports are exposed: 1521 (Oracle Listener), 5500 (EM Express)
       -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDBADMIN password (default: auto generated)
       -e ORACLE_CHARACTERSET:
                      The character set to use when creating the database (default: AL32UTF8)
       -v /opt/oracle/oradata
                      The data volume to use for the database.
                      Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
                      If omitted the database will not be persisted over container recreation.
       -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                      Optional: A volume with custom scripts to be run after database startup.
                      For further details see the "Running scripts after setup and on startup" section below.
       -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                      Optional: A volume with custom scripts to be run after database setup.
                      For further details see the "Running scripts after setup and on startup" section below.

Once the container has been started and the database created you can connect to it just like to any other database:

    sqlplus sys/<your password>@//localhost:1521/XE as sysdba
    sqlplus system/<your password>@//localhost:1521/XE
    sqlplus pdbadmin/<your password>@//localhost:1521/XEPDB1

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

    https://localhost:5500/em/

On the first startup of the container a random password will be generated for the database if not provided. The password for those accounts can be changed via the `docker exec` command. **Note**, the container has to be running:

    docker exec <container name> /opt/oracle/setPassword.sh <your password>

**Important Note:**
The ORACLE_SID for Express Edition is always `XE` and cannot be changed, hence there is no ORACLE_SID parameter provided for the XE build.

#### Running Oracle Database 11gR2 Express Edition in a container

To run your Oracle Database Express Edition container image use the `docker run` command as follows:

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
       -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDBADMIN password (default: auto generated)

       -v /u01/app/oracle/oradata
                      The data volume to use for the database.
                      Has to be writable by the Unix "oracle" (uid: 1000) user inside the container!
                      If omitted the database will not be persisted over container recreation.
       -v /u01/app/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                      Optional: A volume with custom scripts to be run after database startup.
                      For further details see the "Running scripts after setup and on startup" section below.
       -v /u01/app/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                      Optional: A volume with custom scripts to be run after database setup.
                      For further details see the "Running scripts after setup and on startup" section below.

There are two ports that are exposed in this image:

* 1521 which is the port to connect to the Oracle Database.
* 8080 which is the port of Oracle Application Express (APEX).

On the first startup of the container a random password will be generated for the database if not provided. You can find this password in the output line:

    ORACLE PASSWORD FOR SYS AND SYSTEM:

**Note:** The ORACLE_SID for Express Edition is always `XE` and cannot be changed, hence there is no ORACLE_SID parameter provided for the XE build.

The password for those accounts can be changed via the `docker exec` command. **Note**, the container has to be running:

    docker exec <container name> /u01/app/oracle/setPassword.sh <your password>

Once the container has been started you can connect to it just like to any other database:

    sqlplus sys/<your password>@//localhost:1521/XE as sysdba
    sqlplus system/<your password>@//localhost:1521/XE

### Running Oracle True Cache in a container (Supported from version 23ai onwards)

Oracle True Cache is an in-memory, consistent, and automatically managed cache for Oracle Database. For more information about Oracle True Cache please see the [Oracle True Cache Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/odbtc/overview-oracle-true-cache.html).

#### Setting Up the Network for Communication Between the Primary Database and the True Cache Container

* Oracle Database Free True Cache container (True Cache container) and the Oracle Database Free Primary Database container (Primary Database container) must be on the same podman network to communicate with each other.\
Set up a podman network for inter-container communication using the following command which creates a bridge connection enabling communication between containers on the same host.

        podman network create tc_net

    Fetch the default subnet assigned to above network by running the following command:

        podman inspect tc_net | grep -iw 'subnet'

    Pick any two IP addresses from the preceding subnet and assign one for the Primary Database container (say, PRI_DB_FREE_IP) and the other for the True Cache container (say, TRU_CC_FREE_IP).

    For communication across hosts, create a macvlan or ipvlan connection per [documentation](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html). \
    Specify the preceding podman network using the --net option to the podman run command of both the Primary Database container and the True Cache container as shown in following sections.

#### Running Oracle Database Free True Cache in a Container

* Launch the Oracle Database Free Primary Database container using the `podman run` command as follows:

        podman run -td --name pri-db-free \
        --hostname pri-db-free \
        --net=tc_net \
        --ip <PRI_DB_FREE_IP> \
        -p :1521 \
        --secret=oracle_pwd \
        -e ENABLE_ARCHIVELOG=true \
        -e ENABLE_FORCE_LOGGING=true \
        -v [<host mount point>:]/opt/oracle/oradata \
        oracle/database:23.9.0-free

    Ensure that your Primary Database container is up and running and in a healthy state.

    **Note:** Enable archive logging and optionally force logging in the Primary Database to support True Cache. These are not enabled by default in the prebuilt database image.
You need to run the preceding podman run command with the host mount point (empty directory) so that a new database setup will start with these options enabled. Otherwise, you must run sql commands manually from the pri-db-free container to enable these options.

* Launch the Oracle Database Free True Cache container using the `podman run` command as follows:

        podman run -td --name tru-cc-free \
        --hostname tru-cc-free \
        --net=tc_net \
        --ip <TRU_CC_FREE_IP> \
        -p :1521 \
        --secret=oracle_pwd \
        -e TRUE_CACHE=true \
        -e PRIMARY_DB_PWD_FILE=/var/tmp/orapwFREE \
        -e PRIMARY_DB_CONN_STR=<PRI_DB_FREE_IP>:1521/FREE \
        -v [<host mount point>:]/opt/oracle/oradata \
        oracle/database:23.9.0-free

    **Note:**  If a common host mount point is used for both pri-db-free and tru-cc-free containers, then you may skip the podman cp step by specifying the location of pri-db-free password file directly using \
    -e PRIMARY_DB_PWD_FILE=/opt/oracle/product/23ai/dbhomeFree/dbs/orapwFREE

* For different host mount points, copy password file (example 'orapwFREE') from the Primary Database container to the True Cache container at location $PRIMARY_DB_PWD_FILE (/var/tmp/orapwFREE) using podman cp command as follows:

        podman cp pri-db-free:/opt/oracle/product/23ai/dbhomeFree/dbs/orapwFREE tru-cc-free:/var/tmp/

* Once the True Cache container turns healthy, create database application services (sales_tc and sales_pdb_tc) for the True Cache by running the following commands from the pri-db-free container:

        podman exec -it pri-db-free bash

        $ORACLE_HOME/bin/dbca -configureDatabase -configureTrueCacheInstanceService -sourceDB FREE \
        -trueCacheConnectString <TRU_CC_FREE_IP>:1521/FREE -trueCacheServiceName sales_tc -serviceName FREE \
        -sysPassword $(cat /run/secrets/oracle_pwd) -silent

        $ORACLE_HOME/bin/dbca -configureDatabase -configureTrueCacheInstanceService -sourceDB FREE \
        -trueCacheConnectString <TRU_CC_FREE_IP>:1521/FREE -trueCacheServiceName sales_pdb_tc -serviceName FREEPDB1 \
        -pdbName FREEPDB1 -sysPassword $(cat /run/secrets/oracle_pwd) -silent

### Containerizing an on-premise database (Supported from version 19.3.0 release)

To containerize an on-premise database, please follow the steps mentioned below:

* Create the gold image from the on-premise database. The required command is as follows:

        cd $ORACLE_HOME && ./runInstaller -silent -createGoldImage -destinationLocation '<location to store the gold image>'

* The gold image created in the step above will have the name like `db_home_2022-03-25_12-43-21PM.zip`. Copy this gold image to the `OracleDatabase/SingleInstance/dockerfiles/<version>` directory. The **version** would be the base version of the gold image, e.g. 19.3.0.
* Create the container image using this gold image by the following sample command:

        ./buildContainerImage.sh -i -e -v 19.3.0 -t oracle/database:19-onprem -o '--build-arg INSTALL_FILE_1=db_home_2022-03-25_12-43-21PM.zip'

* Run the container image created above with cloning option to clone the data files of the on-premise database. The sample command is as follows:

        docker run --name <container-name> -e CLONE_DB=true \
        -e ORACLE_PWD='<sys password of the on-prem database>' \
        -e PRIMARY_DB_CONN_STR='<the on-prem database connection string in <HOST>:<PORT>/<SERVICE_NAME> format>' \
        oracle/database:19-onprem

**NOTE:**
Make sure that the directory structure of the on-premise database matches with the directory structure used in the container image.

### Deploying Oracle Database on Kubernetes

Helm is a package manager which uses a packaging format called charts. [helm-charts](helm-charts/) directory contains all the relevant files needed to deploy Oracle Database on Kubernetes. For more information on default configuration, installing/uninstalling the Oracle Database chart on Kubernetes, please refer [helm-charts/oracle-db/README.md](helm-charts/oracle-db/README.md).

### Running SQL*Plus in a container

You may use the same container image you used to start the database, to run `sqlplus` to connect to it, for example:

    docker run --rm -ti oracle/database:19.3.0-ee sqlplus pdbadmin/<yourpassword>@//<db-container-ip>:1521/ORCLPDB1

Another option is to use `docker exec` and run `sqlplus` from within the same container already running the database:

    docker exec -ti <container name> sqlplus pdbadmin@ORCLPDB1

### Running scripts after setup and on startup

The container images can be configured to run scripts after setup and on startup. Currently `sh` and `sql` extensions are supported.
For post-setup scripts just mount the volume `/opt/oracle/scripts/setup` or extend the image to include scripts in this directory.
For post-startup scripts just mount the volume `/opt/oracle/scripts/startup` or extend the image to include scripts in this directory.
Both of those locations are also represented under the symbolic link `/docker-entrypoint-initdb.d`. This is done to provide
synergy with other database container images. The user is free to decide whether to put the setup and startup scripts
under `/opt/oracle/scripts` or `/docker-entrypoint-initdb.d`.

After the database is setup and/or started the scripts in those folders will be executed against the database in the container.
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user. To ensure proper order it is
recommended to prefix your scripts with a number. For example `01_users.sql`, `02_permissions.sql`, etc.

**Note:** The startup scripts will also be executed after the first time database setup is complete.  
**Note:** For 11gR2 Express Edition only, use `/u01/app/oracle/scripts/` instead of `/opt/oracle/scripts/`.

The example below mounts the local directory myScripts to `/opt/oracle/myScripts` which is then searched for custom startup scripts:

    docker run --name oracle-ee -p 1521:1521 -v /home/oracle/myScripts:/opt/oracle/scripts/startup -v /home/oracle/oradata:/opt/oracle/oradata oracle/database:19.3.0-ee

## Known issues

* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

## Frequently asked questions

Please see [FAQ.md](./FAQ.md) for frequently asked questions.

## Support

Oracle Database in single instance configuration is supported for Oracle Linux 7 and Red Hat Enterprise Linux (RHEL) 7.
For more details please see My Oracle Support note: **Oracle Support for Database Running on Docker (Doc ID 2216342.1)**

## License

To download and run Oracle Database, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the container images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright

Copyright (c) 2014,2024 Oracle and/or its affiliates.
