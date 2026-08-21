# Oracle Free Lite Container

The Oracle Free Lite Container is one of the database container images provided by Oracle that contains the Oracle Database Free based on an Oracle Linux base image.

The goal of the image is to provide an easy-to-use database with a quick download and startup time, as well as a small storage footprint.

The Lite image achieves this with 
- A stripped down installation of the database that retains only its core features
- A trimmed OS base image without system files unused by the database.
- A pre-built database within the image that speeds up the container startup time.

Additional information can be found in the documentation:
[https://container-registry.oracle.com/ords/ocr/ba/database/free](https://container-registry.oracle.com/ords/ocr/ba/database/free)


## Build the image

**NOTE:** You need to have Internet connectivity for yum.

Clone the repository with:
```bash
git clone git@orahub.oci.oraclecorp.com:db-inst-dbinstall/docker-images.git
cd docker-images/OracleDatabase/SingleInstance/extensions/slimming
```

Setup the environment and build the Lite image using a Full Free Database container image as base.
```bash
. ./env
oracle_lite_docker_build -v 23.26.0 -b dbcs-dev-docker.dockerhub-phx.oci.oraclecorp.com/oracle/database-free:RDBMS_23.0.0.0.0_LINUX.X64_250113
```
In this example, the Lite image is built with the Free image from the RDBMS_23.0.0.0.0_LINUX.X64_250113 label.

oracle_lite_docker_build is the parent script used to build the image.
```bash
Usage: oracle_lite_docker_build [-h] [-v] [version] [-b] [base_image] [-n] [-t] [image_name:tag]
Builds a lite container image for Oracle Database.

Parameters:
   -h: show config options
   -v: version to build
       Choose one of: 23
                      26
       Default image is 26
   -b: database image to use as a base
   -n: creates nanovos base image based on 'Enterprise Edition' image
   -t: image_name:tag for the generated docker image
```
Once the build is complete, the images can be viewed via
```bash
$ podman images
REPOSITORY                                    TAG            IMAGE ID      CREATED         SIZE
localhost/oracle/database/free                lite           6d0c8dc87065  2 days ago      1.88 GB
```
## Usage
Run the database container with command like

```bash
podman run --name oradb -p 2500:1521 -e ORACLE_PWD=knl_test7 localhost/oracle/database/free:23.26.0-lite
```

```bash
podman run --name <container name> \
-p <host port>:1521 \
-e ORACLE_PDB=<your PDB name> \
-e ORACLE_PWD=<your database passwords> \
-v [<host mount point>:]/opt/oracle/oradata \
<image name:tag>

Parameters:
   --name:        The name of the container (default: auto generated).
   -p:            The port mapping of the host port to the container port.
                  The following ports is exposed: 1521 (Oracle Listener).

   -e ORACLE_PDB: The Oracle Database PDB name that should be used (default: FREEPDB1).
   -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated).
   -v /opt/oracle/oradata
                  The data volume to use for the database.
                  Has to be writable by the Unix "oracle" (uid: 54321) user inside the container.
                  If omitted the database will not be persisted over container recreation.

```
**Important Note:** The ORACLE_SID for Oracle Database 23ai Free Lite is always FREE and cannot be changed, hence there is no ORACLE_SID parameter provided for the Free build.

Once the container has been started and the database created you can connect to it just like to any other database:
```bash
sqlplus sys/knl_test7@localhost:2500/FREE as sysdba
```

```bash
sqlplus sys/<your password>@localhost:<host port>/<your service name> as sysdba
sqlplus system/<your password>@localhost:<host port>/<your service name>
sqlplus pdbadmin/<your password>@localhost:<host port>/<Your PDB name>
```

### Changing the admin accounts passwords

On the first startup of the container, a random password will be generated for the database if not provided. The user has to mandatorily change the password after the database is created and the corresponding container is healthy.

The password for those accounts can be changed via the podman exec command. Note, the container has to be running:

```bash
podman exec <container name> ./setPassword.sh <your password>
```

# Oracle NanoVOS Container

NanoVOS is a lightweight pluggable instance framework that provides Oracle Database-like server functionalities for non-RDBMS applications.
A NanoVOS instance is a pluggable unit, and the application logic is segregated from the functionalities.

## Build the Base image

The Oracle NanoVOS Base Container image serves as a base, on top of which the application logic needs to be appended to build a NanoVOS instance image.

Build the base image with the -n option to the build script and using an Enterprise Database Container image as base.
```bash
. ./env
oracle_lite_docker_build -n -v 26.0.0 -b dbcs-dev-docker.dockerhub-phx.oci.oraclecorp.com/oracle/database:RDBMS_MAIN_LINUX.X64_250115
```

The image can be viewed via
```bash
$ podman images
REPOSITORY                                    TAG                    IMAGE ID      CREATED         SIZE
localhost/oracle/nanovos                      latest                 c8275e287227  3 minutes ago   1.28 GB
```

## Build the NanoVOS image
The Nanovos image is built as a layer on top of a base image. We will use the sample hello_world nanovos library to demonstrate the build.

Add the Nanovos library and .ora parameter file to the same directory as the Dockerfile.
```bash
$ cd make_app
$ cp $T_WORK/libhelloworld.so $T_WORK/tkinnvos1.ora .
$ ls
Dockerfile  libhello_world.so  runNanovos.sh  startInstance.sh  tkinnvos1.ora
```
Now build the image using command
```bash
podman build -f Dockerfile -t <image_name>:<tag> . --build-arg PARAM_FILE=<parameter_file> --build-arg NANOVOS_LIB=<library_name> --format=docker
```

For the hello-world example,
```bash 
$ podman build -f Dockerfile -t nanoapp . --build-arg PARAM_FILE=tkinnvos1.ora --build-arg NANOVOS_LIB=libhello_world.so --format=docker 

$ podman images
REPOSITORY                                   TAG                         IMAGE ID      CREATED         SIZE
localhost/nanoapp                            latest                      07764d0906dc  3 seconds ago   1.28 GB
localhost/oracle/nanovos                     26.0.0                      c8275e287227  14 minutes ago  1.28 GB
```

## Usage
Run the NanoVOS container with command

```bash 
podman run --name <container name> \
<image-name>:<tag>

Parameters:
   --name:        The name of the container (default: auto generated).
```
In our example,

```bash 
$ podman run --name nanovos localhost/nanoapp:latest
```

You can connect to the instance from within the container.
```bash 
$ podman exec -it nanovos /bin/bash

bash-4.4$ sqlplus sys/knl_test7 as sysdba

SQL*Plus: Release 26.0.0.0.0 - Development on Mon Jul 15 19:10:13 2024
Version 26.1.0.24.00

Copyright (c) 1982, 2024, Oracle.  All rights reserved.

Last Successful login time: Mon Jul 15 2024 19:05:32 +00:00

Connected to:
Oracle Database 26ai Enterprise Edition Release 26.0.0.0.0 - Development
Version 26.1.0.24.00

SQL> show sga

Total System Global Area  235438856 bytes
Fixed Size		    4752136 bytes
Variable Size		  230686720 bytes
```
