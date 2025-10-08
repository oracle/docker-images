# Oracle REST Data Services on Docker

Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users.
For more information about Oracle REST Data Services (ORDS) please see the [ORDS Documentation](http://www.oracle.com/technetwork/developer-tools/rest-data-services/documentation/index.html).

## How to build and run

This project offers sample Dockerfiles for Oracle REST Data Services

To assist in building the images, you can use the [buildContainerImage.sh](dockerfiles/buildContainerImage.sh) script. See below for instructions and usage.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their preferred set of parameters.

### Building Oracle REST Data Services Install Images

**IMPORTANT:** You can provide the installation binaries of ORDS and put them into the `dockerfiles` folder. You only need to provide the binaries for the version you are going to install.\
The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html) and placed in `OracleRestDataServices/dockerfiles` directory. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!  

**If no binaries are provided, [the latest ords zip](https://download.oracle.com/otn_software/java/ords/ords-latest.zip) file is downloaded automatically.**

The image builds on top of the `oracle/serverjre:8` image which is also provided in this repository, see [OracleJava](../OracleJava). This base image is fetched from the container registry. So for successful fetch the user needs to login to the [container-registry](container-registry.oracle.com) and accept the license agreement.\
The user can also build the `oracle/serverjre:8` image locally before building this image using the [OracleJava](../OracleJava) repo. After building this image locally, the user can run the following command:

```bash
./buildContainerImage.sh -o '--build-arg BASE_IMAGE=<local-image>'
```

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have done that go into the **dockerfiles** folder and run the **buildContainerImage.sh** script:

```bash
    [oracle@localhost dockerfiles]$ ./buildContainerImage.sh -h
    
    Usage: buildContainerImage.sh [-i] [-o] [Docker build option]
    Builds a Docker Image for Oracle Rest Data Services
    
    Parameters:
       -i: ignores the MD5 checksums
       -o: passes on Docker build option
    
    LICENSE UPL 1.0
    
    Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
```

**IMPORTANT:** The resulting images will be an image with the ORDS binaries installed. On first startup of the container ORDS will be setup.

### Running Oracle REST Data Services in a Docker container

Before you run your ORDS Docker container you will have to specify a network in which ORDS will communicate with the database you would like it to expose via REST.
In order to do so you need to create a [user-defined network](https://docs.docker.com/engine/userguide/networking/#user-defined-networks) first.
This can be done via following command:

```bash
    docker network create <your network name>
```

Once you have created the network you can double check by running:

```bash
    docker network ls
```

You should see your network, amongst others, in the output.

As a next step you will have to start your database container with the specified network. This can be done via the `docker run` `--network` option, for example:

```bash
    docker run --name oracledb --network=<your network name> oracle/database:12.2.0.1-ee
```

The database container will be visible within the network by its name passed on with the `--name` option, in the example above **oracledb**.
Once your database container is up and running and the database available, you can run a new ORDS container.

To run your ORDS Docker image use the **docker run** command as follows:

```bash
    docker run --name <container name> \
    --network=<name of your created network> \
    -p <host port>:8888 \
    -e ORACLE_HOST=<Your Oracle DB host (default: localhost)> \
    -e ORACLE_PORT=<Your Oracle DB port (default: 1521)> \
    -e ORACLE_SERVICE=<your Oracle DB Service name (default: ORCLPDB1)> \
    -e ORACLE_PWD=<your database SYS password> \
    -e ORDS_PWD=<your ORDS password> \
    -e CONTEXT_ROOT=<http context-root to use (default: ords)> \
    -v [<host mount point>:]/opt/oracle/ords/config/ords \
    oracle/restdataservices:3.0.12
    
    Parameters:
       --name:            The name of the container (default: auto generated)
       --network:         The network to use to communicate with databases.
       -p:                The port mapping of the host port to the container port. 
                          One port is exposed: 8888
       -e ORACLE_HOST:    The Oracle Database hostname that ORDS should use (default: localhost)
                          This should be the name that you gave your Oracle database Docker container, e.g. "oracledb"
       -e ORACLE_PORT:    The Oracle Database port that ORSD should use (default: 1521)
       -e ORACLE_SERVICE: The Oracle Database Service name that ORDS should use (default: ORCLPDB1)
       -e ORACLE_PWD:     The Oracle Database SYS password
       -e ORDS_PWD:       The ORDS_PUBLIC_USER password
       -e CONTEXT_ROOT:   (optional) The http context-root that ORDS should use (default: ords)
       -v /opt/oracle/ords/config/ords
                          The data volume to use for the ORDS configuration files.
                          Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
                          If omitted the ORDS configuration files will not be persisted over container recreation.
```

Once the container has been started and ORDS configured you can send REST calls to ORDS.

## Known issues

None

## Support

## License

To download and run ORDS, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleRestDataServices](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License (UPL), Version 1.0.

## Copyright

Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
