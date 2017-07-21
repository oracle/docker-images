Oracle GoldenGate on Docker
===============
Sample Docker build files to provide an installation of Oracle GoldenGate for DevOps users. For more information about Oracle GoldenGate please see the [Oracle GoldenGate On-line Documentation](https://docs.oracle.com/goldengate/c1221/gg-winux/index.html).

## How to build and run
This project provides a Dockerfile tested with:
 * Oracle GoldenGate 12c Release 2 (12.2.0.1)
 * Oracle GoldenGate Standard Edition 12c Release 3 (12.3.0.1)
 * Oracle GoldenGate Microservices Architecture 12c Release 3 (12.3.0.1)

To build the images, use the [dockerBuild.sh](dockerBuild.sh) script.

### Building Oracle GoldenGate Docker Images
**IMPORTANT:** You must download the installation binaries of Oracle GoldenGate. You only need to provide the binaries for the version you plan to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html). You also must have Internet connectivity when building the Docker image for the package manager. Note that you must not uncompress the Oracle GoldenGate binaries. The script will handle that for you and fail if you uncompress them manually!

Once you have downloaded the Oracle GoldenGate software, run the **`dockerBuild.sh`** script:

    [oracle@localhost dockerfiles]$ ./dockerBuild.sh -h
    Oracle GoldenGate distribution ZIP file not specified.

    Usage: ./dockerBuild.sh [-h | <ogg-zip-file-name>] [<docker-build-options> ...]
    Where:
      ogg-zip-file-name       Name of OGG ZIP file
      docker-build-options    Command line options for Docker build

    Example:
      dockerBuild.sh ~/Downloads/fbo_ggs_Linux_x64_shiphome.zip --no-cache

**IMPORTANT:** The result will be a Docker image with the Oracle GoldenGate binaries installed. Created images will follow the naming convention of **oracle/goldengate-&lt;edition&gt;:&lt;version&gt;**, for example:

- `oracle/goldengate-standard:12.2.0.1.1`
- `oracle/goldengate-standard:12.3.0.1.0`
- `oracle/goldengate-microservices:12.3.0.1.0`

#### Changing the Base Image
By default, the base image used when building Oracle GoldenGate Docker images is `container-registry.oracle.com/database/instantclient:12.2.0.1`.  This value can be changed by setting the environment variable `BASE_IMAGE` when executing the `dockerBuild.sh` script. For example:

    BASE_IMAGE="container-registry.oracle.com/database/enterprise" ./dockerBuild.sh ~/Downloads/fbo_ggs_Linux_x64_shiphome.zip

### Running Oracle GoldenGate in a Docker container

To run your Oracle GoldenGate Docker image use the **docker run** command as follows:

    docker run --name <container name> \
        -e OGG_SCHEMA=<schema for OGG> \
        -e OGG_ADMIN=<admin user name> \
        -e OGG_ADMIN_PWD=<admin password> \
        -e OGG_DEPLOYMENT=<deployment name for Microservices Architecture> \
        -v [<host mount point>:]/u02/ogg \
        -v [<host mount point>:]/u02/ogg/var/data \
        oracle/goldengate-microservices:12.3.0.1.0

    Parameters:
       --name:        The name of the container (default: auto generated)
       -e OGG_SCHEMA: The GGSCHEMA to use for OGG (default: `oggadmin`)
       -e OGG_ADMIN:  The name of the administrative account to create for Microservices Architecture (default: `oggadmin`)
       -e OGG_ADMIN_PWD:
                      The password for the administrative account (default: value of `OGG_ADMIN`)
       -e OGG_DEPLOYMENT:
                      The name of the deployment for Microservices Architecture (default: `Local`)
       -v /u02/ogg
                      The data volume for Microservices Architecture configuration data
       -v /u02/ogg/var/data
                      The data volume for Microservices Architecture trail data

#### Administrative Account Password for Microservices Architecture

On the first startup of a Microservices Architecture container, a random password will be generated for the Oracle GoldenGate administrative user if not provided. You can find this password at the start of the Docker container log:

    docker logs <container name> | head -3
    ----------------------------------------------------------------------------------
    --  Password for administrative user 'oggadmin' is 'qVc3bqNlwijk'
    ----------------------------------------------------------------------------------

#### Running GGSCI in an OGG Standard Edition Docker container
The **GGSCI** utility can be run in the OGG container with this command:

    docker exec -ti --user oracle <container name> ggsci

**GGSCI** is not installed for containers created with the Microservices Architecture.

#### Running Admin Client in an OGG Microservices Architecture Docker container
The **Admin Client** utility can be run in the OGG container with this command:

    docker exec -ti --user oracle <container name> adminclient

**Admin Client** is only available in containers created with the Microservices Architecture.

## Known issues
None

## License
To download and run Oracle GoldenGate, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleGoldenGate](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright &copy; 2014-2017 Oracle and/or its affiliates. All rights reserved.
