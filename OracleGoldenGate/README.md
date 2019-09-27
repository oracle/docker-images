Oracle GoldenGate on Docker
===============
Sample Docker build files to provide an installation of Oracle GoldenGate for DevOps users.

## Contents

* [Before You Start](#before-you-start)
* [Option 1 - Using `dockerBuild.sh` to Build Oracle GoldenGate Docker Images](#option-1---using-dockerbuildsh-to-build-oracle-goldengate-docker-images)
  * [Docker Build Options](#docker-build-options)
* [Option 2 - Manually Building Oracle GoldenGate Docker Images](#option-2---manually-building-oracle-goldengate-docker-images)
  * [Extracting *Oracle GoldenGate for Oracle* Installation Media](#extracting-oracle-goldengate-for-oracle-installation-media)
  * [Extracting *Oracle GoldenGate* Installation Media for non-Oracle Databases](#extracting-oracle-goldengate-installation-media-for-non-oracle-databases)
  * [Building the Docker image](#building-the-docker-image)
* [Changing the Base Image](#changing-the-base-image)
* [Running a Command from the Base Image](#running-a-command-from-the-base-image)
* [Running Oracle GoldenGate in a Docker container](#running-oracle-goldengate-in-a-docker-container)
  * [SSL Certificate for Microservices Architecture](#ssl-certificate-for-microservices-architecture)
  * [Administrative Account Password for Microservices Architecture](#administrative-account-password-for-microservices-architecture)
  * [Running GGSCI in an OGG Standard Edition Docker container](#running-ggsci-in-an-ogg-standard-edition-docker-container)
  * [Running Admin Client in an OGG Microservices Architecture Docker container](#running-admin-client-in-an-ogg-microservices-architecture-docker-container)
* [Additional Utilities](#additional-utilities)
* [Known issues](#known-issues)
* [License](#license)
* [Copyright](#copyright)

## Before You Start
This project provides a Dockerfile tested with:

- Oracle GoldenGate 12.2.0.1.1 for Oracle
- Oracle GoldenGate 12.3.0.1.4 for Oracle
- Oracle GoldenGate 12.3.0.1.4 Microservices for Oracle
- Oracle GoldenGate 18.1.0.0.0 for Oracle
- Oracle GoldenGate 18.1.0.0.0 Microservices for Oracle
- Oracle GoldenGate 19.1.0.0.2 for Oracle
- Oracle GoldenGate 19.1.0.0.2 Microservices for Oracle

To build the images, use the [dockerBuild.sh](dockerBuild.sh) script or follow the instructions for manually building an image.

**IMPORTANT:** To create images for Oracle GoldenGate on Docker, you must use Docker version 17.05.0 or later. You can check the version of Docker on your system with the `docker version` command.

**IMPORTANT:** You must download the installation binaries of Oracle GoldenGate. You only need to provide the binaries for the version you plan to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html). Do not uncompress the Oracle GoldenGate ZIP file. The `dockerBuild.sh` script will handle that for you. You also must have Internet connectivity when building the Docker image for the package manager to perform additional software installations.

For more information about Oracle GoldenGate please see the [Oracle GoldenGate 12c On-line Documentation](https://docs.oracle.com/goldengate/c1230/gg-winux/index.html).

## Option 1 - Using `dockerBuild.sh` to Build Oracle GoldenGate Docker Images
Once you have downloaded the Oracle GoldenGate software, run the `dockerBuild.sh` script without command line options to view usage instructions:

    $ ./dockerBuild.sh
    Oracle GoldenGate distribution ZIP file not specified.

    Usage: dockerBuild.sh [-h | <ogg-zip-file-name>] [<docker-build-options> ...]
    Where:
      ogg-zip-file-name       Name of OGG ZIP file
      docker-build-options    Command line options for Docker build

    Example:
      ./dockerBuild.sh ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip --no-cache

When the name of an Oracle GoldenGate ZIP file is specified, the result of `dockerBuild.sh` will be a Docker image with the Oracle GoldenGate binaries installed. Created Docker images will follow the naming convention of **oracle/goldengate-&lt;edition&gt;:&lt;version&gt;**, for example:

- `oracle/goldengate-standard:12.2.0.1.1`
- `oracle/goldengate-standard:12.3.0.1.4`
- `oracle/goldengate-microservices:12.3.0.1.4`

The `dockerBuild.sh` script determines the version and edition of Oracle GoldenGate by inspecting the ZIP file.

**IMPORTANT:** When creating Docker images for *Oracle GoldenGate for Oracle*, the `dockerBuild.sh` script automatically selects the Oracle GoldenGate software for Oracle RDBMS 12c. To create Docker images for a different version of Oracle RDBMS, follow the instructions for **Option 2**.

### Docker Build Options
When using `dockerBuild.sh`, all command line options after the name of the Oracle GoldenGate ZIP file are passed directly to the `docker build` command. This allows you to modify the behavior of `docker build`. For example, adding `--no-cache` to the `dockerBuild.sh` command line instructs Docker to not use cached images when building the Oracle GoldenGate Docker image. The `--tag` option can be used to give the new Docker image a custom tag.

The following example creates a Oracle GoldenGate Docker image and names it `devops/goldengate-microservices:production`. Output from `docker build` is not shown unless an error occurs.

    $ ./dockerBuild.sh ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip --tag devops/goldengate-microservices:production --quiet

## Option 2 - Manually Building Oracle GoldenGate Docker Images
Building an Oracle GoldenGate Docker image can be done manually, without using the **`dockerBuild.sh`** script, by following the steps in this section.

First, the installation media must be extracted from the downloaded ZIP file and converted to a TAR file for the Docker build process. The extraction process depends on the version of Oracle GoldenGate downloaded.

### Extracting *Oracle GoldenGate for Oracle* Installation Media
The *Oracle GoldenGate for Oracle* software is packaged differently than for other databases. If *Oracle GoldenGate for Oracle* was downloaded, locate the appropriate `filegroup1.jar` file and extract it.  For example, *Oracle GoldenGate 12.3.0.1.4 Microservices for Oracle* contains two candidates:

    $ unzip -l ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip | grep 'oracle.oggcore.*.ora.*filegroup1.jar'
    125089328  2018-04-16 05:46   fbo_ggs_Linux_x64_services_shiphome/Disk1/stage/Components/oracle.oggcore.services.ora11g/12.3.0.1.2/1/DataFiles/filegroup1.jar
    119782012  2018-04-16 05:45   fbo_ggs_Linux_x64_services_shiphome/Disk1/stage/Components/oracle.oggcore.services.ora12c/12.3.0.1.2/1/DataFiles/filegroup1.jar


The `filegroup1.jar` for Oracle RDBMS 12c can be extracted into the current directory with a command like this:

    $ unzip -j ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip \
               fbo_ggs_Linux_x64_services_shiphome/Disk1/stage/Components/oracle.oggcore.services.ora12c/12.3.0.1.2/1/DataFiles/filegroup1.jar

Then, conversion of `filegroup1.jar` to `123014_fbo_ggs_Linux_x64_services_shiphome.tar` is done with this command:

    $ unzip -q filegroup1.jar -d ./oggcore && \
      tar Ccf ./oggcore 123014_fbo_ggs_Linux_x64_services_shiphome.tar --owner=54321 --group=54321 . && \
      rm -fr  ./oggcore

**NOTE:** The group id and owner id of '54321' is used by the Dockerfile when creating the 'oracle' user account.

When the above commands are executed successfully, the resulting TAR file, `123014_fbo_ggs_Linux_x64_services_shiphome.tar`, will be used by the Dockerfile to create the Oracle GoldenGate image. Pass the filename to the Docker build command with the `OGG_TARFILE` build argument. This is covered in greater detail in a later section.

### Extracting *Oracle GoldenGate* Installation Media for non-Oracle Databases
For non-Oracle databases, the installation software is packaged as a TAR file in a ZIP file, along with release notes.

    $ unzip -lv ~/Downloads/123011_ggs_Linux_x64_MySQL_64bit.zip
    Archive:  /home/sbalousek/Downloads/123011_ggs_Linux_x64_MySQL_64bit.zip
     Length   Method    Size  Cmpr    Date    Time   CRC-32   Name
    --------  ------  ------- ---- ---------- ----- --------  ----
    260648960  Defl:N 62574810  76% 2017-08-05 07:25 2dcd70bf  ggs_Linux_x64_MySQL_64bit.tar
        1542  Defl:N      559  64% 2017-08-13 16:22 cb9f1c1b  OGG-12.3.0.1-README.txt
      181443  Defl:N   139000  23% 2017-08-13 16:22 92c6c95c  OGG_WinUnix_Rel_Notes_12.3.0.1.pdf
    --------          -------  ---                            -------
    260831945         62714369  76%                            3 files

Extract the TAR file with a command like:

    $ unzip ~/Downloads/123011_ggs_Linux_x64_MySQL_64bit.zip ggs_Linux_x64_MySQL_64bit.tar

**NOTE:** The name of the TAR file depends on the version of Oracle GoldenGate that was downloaded.

Optionally, rebuild the TAR file using the group and user identifiers 54321:54321. If this step is skipped, the resulting image file will be larger than necessary.

    $ mkdir ./oggcore && \
      tar Cxf ./oggcore ggs_Linux_x64_MySQL_64bit.tar && \
      tar Ccf ./oggcore ggs_Linux_x64_MySQL_64bit.tar --owner=54321 --group=54321 . && \
      rm -fr  ./oggcore

**NOTE:** The group id and owner id of '54321' is used by the Dockerfile when creating the 'oracle' user account.

When the above commands are executed successfully, the resulting TAR file, `ggs_Linux_x64_MySQL_64bit.tar`, can be used by the Dockerfile to create the Oracle GoldenGate image. Pass the filename to the Docker build command with the `OGG_TARFILE` build argument. This is described in the next section.

### Building the Docker image
Once the TAR file is created, the Docker image can be built. The Dockerfile requires three build arguments be defined for the `docker build` command.

- `OGG_VERSION` - The Oracle GoldenGate version used for the Docker image. "12.3.0.1.4", for example. This value is used to set the `OGG_VERSION` environment variable in the resulting Docker image and is otherwise not used.
- `OGG_EDITION` - The Oracle GoldenGate edition, either "standard" or "microservices". This value determines the additional software added to the Docker image.
- `OGG_TARFILE` - The name of the TAR file extracted using the commands above. The TAR file must be located in the same directory as `Dockerfile`.

An Oracle GoldenGate Docker image is built with a `docker build` command like this:

    $ docker build --build-arg OGG_VERSION="12.3.0.1.4" \
                   --build-arg OGG_EDITION="microservices" \
                   --build-arg OGG_TARFILE="123014_fbo_ggs_Linux_x64_services_shiphome.tar" \
                   --tag oracle/goldengate-microservices:12.3.0.1.4 --no-cache .

## Changing the Base Image
By default, the base image used by Docker to build Oracle GoldenGate Docker images is `oracle/instantclient:12.2.0.1`. The Oracle Instant Client image can be built using the files in [OracleInstantClient](../OracleInstantClient). You can change the base image used by the Oracle GoldenGate Docker images if your Oracle GoldenGate software is for a non-Oracle RDBMS or if you have more complex requirements of the Oracle GoldenGate Docker image.

The base image is changed by setting the environment variable `BASE_IMAGE` when executing the `dockerBuild.sh` script as described in **Option 1** above. This example uses an Oracle Database 12c Release 2 (12.2.0.1) Enterprise Edition image created using the files in [OracleDatabase](../OracleDatabase):

    $ BASE_IMAGE="oracle/database:12.2.0.1-ee" ./dockerBuild.sh ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip

When manually creating the Docker image (see **Option 2**), the base image is specified as a Docker build argument. For example, using an Oracle Database 12c Release 2 (12.2.0.1) Enterprise Edition base image is done with a command like this:

    $ docker build --build-arg BASE_IMAGE="oracle/database:12.2.0.1-ee" \
                   --build-arg OGG_VERSION="12.3.0.1.4" \
                   --build-arg OGG_EDITION="microservices" \
                   --build-arg OGG_TARFILE="123014_fbo_ggs_Linux_x64_services_shiphome.tar" \
                   --tag oracle/goldengate-microservices:12.3.0.1.4 --no-cache .

## Running a Command from the Base Image
If the base image provides run-time services, they can be specified at Docker image build time with the `BASE_COMMAND` argument. They can also be specified at run time with the `BASE_COMMAND` environment variable. The command specified by `BASE_COMMAND` will be executed in the background, before the Oracle GoldenGate services are run. For example, when the Oracle GoldenGate Docker image is based on `oracle/database:12.2.0.1-ee`, the RDBMS services can be specified with this command:

    $ BASE_IMAGE="oracle/database:12.2.0.1-ee" ./dockerBuild.sh ~/Downloads/123014_fbo_ggs_Linux_x64_services_shiphome.zip --build-arg BASE_COMMAND="runuser -u oracle -- /opt/oracle/runOracle.sh"

## Running Oracle GoldenGate in a Docker container
To run your Oracle GoldenGate Docker image use a **docker run** command like this:

    $ docker run --name <container name> \
        --cap-add SYS_RESOURCE \
        -e OGG_SCHEMA=<schema for OGG> \
        -e OGG_ADMIN=<admin user name> \
        -e OGG_ADMIN_PWD=<admin password> \
        -e OGG_DEPLOYMENT=<deployment name for Microservices Architecture> \
        -v <host mount point>:<container-mount-point> ... \
        <image name>

Parameters:

- `<container name>`  - The name of the container (default: auto generated)
- `--cap-add SYS_RESOURCE` - Required privileges for Docker container to allow `su - oracle`
- `-e OGG_SCHEMA`     - The GGSCHEMA to use for OGG (default: `oggadmin`)
- `-e OGG_ADMIN`      - The name of the administrative account to create for Microservices Architecture (default: `oggadmin`)
- `-e OGG_ADMIN_PWD`  - The password for the Microservices Architecture administrative account (default: auto generated)
- `-e OGG_DEPLOYMENT` - The name of the deployment for Microservices Architecture (default: `Local`)
- `<image name>`      - The Docker image name created using **Option 1** or **Option 2**

**NOTE:** Only the `OGG_SCHEMA` environment variable is used by Oracle GoldenGate Standard Edition containers. The other environment variables are used by the Microservices Architecture.

Mount points for Oracle GoldenGate Standard Edition are located in the container under the `/u01/app/ogg/` directory. For example:

- `/u01/app/ogg/dirprm` - The parameter file directory
- `/u01/app/ogg/dirdat` - The standard trail file directory

For the Microservices Architecture, Oracle GoldenGate data is located under the `/u02/ogg` directory. Some examples are:

- `/u02/ogg/Local/etc/conf`     - Configuration files for the 'Local' deployment
- `/u02/ogg/Local/var/lib/data` - Trail files for the 'Local' deployment

### SSL Certificate for Microservices Architecture
When the Oracle GoldenGate Docker image is created for Microservices Architecture, a dummy SSL certificate is generated for the OGG Web UI. Your own SSL certificate can be used instead of the dummy certificate like this:

    docker run --name ogg-test \
        -e OGG_SCHEMA=ggadmin \
        -e OGG_ADMIN=oggadmin \
        -v /path/to/certificate.pem:/etc/nginx/ogg.pem \
        oracle/goldengate-microservices:12.3.0.1.4

The certificate file, `/path/to/certificate.pem`, needs to contain a full certificate chain including the private key and all intermediate and root CA public keys. For example:

    -----BEGIN PRIVATE KEY-----
    MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDCqx5mEeaMNCqr
    +5Bs+75+tA93TPus3Q8Q3LZnEw3Wp+fRPzBY69Q/pLF/kuByewoJVjPHOoSoQry4
    ...
    G4eJ5TiYh2TBWdt1DGqATYBVCVcdwsOn0GFHmo2bmdMHgA8EBLjVNhiHoysPCOtB
    aecxSyWi/kHOBObhFe93xb7p
    -----END PRIVATE KEY-----
    -----BEGIN CERTIFICATE-----
    MIIFBTCCA+2gAwIBAgISBJSzNXE+Ha5eDw76N5lgHhTpMA0GCSqGSIb3DQEBCwUA
    MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD
    ...
    dr7wTE+AQwcOLAGjIvFOL7GK8JrhKvuFvnSoys/1O2CK3vVhBgS+mEF6D+QjIGTv
    VC01LCPT51q58INy4RtDBPSqlJwrzz+pOOWd5rBWhu2UPktVHz3AtYE=
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/
    MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
    ...
    PfZ+G6Z6h7mjem0Y+iWlkYcV4PIWL1iwBi8saCbGS5jN2p8M+X+Q7UNKEkROb3N6
    KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg==
    -----END CERTIFICATE-----

### Administrative Account Password for Microservices Architecture
On the first startup of a Microservices Architecture container, a random password will be generated for the Oracle GoldenGate administrative user if not provided by the `OGG_ADMIN_PWD` environment variable. You can find this password at the start of the Docker container log:

    $ docker logs <container name> 2>/dev/null | head -3
    ----------------------------------------------------------------------------------
    --  Password for administrative user 'oggadmin' is 'qVc3bqNlwijk'
    ----------------------------------------------------------------------------------

### Running GGSCI in an OGG Standard Edition Docker container
The **GGSCI** utility can be run in the OGG container with this command:

    $ docker exec -ti --user oracle <container name> ggsci

**GGSCI** is not installed for containers created with the Microservices Architecture.

### Running Admin Client in an OGG Microservices Architecture Docker container
The **Admin Client** utility can be run in the OGG container with this command:

    $ docker exec -ti --user oracle <container name> adminclient

**Admin Client** is only available in containers created with the Microservices Architecture.

## Additional Utilities
Additional utilities, installed to the Docker Image at `/usr/local/bin`, can be found in the [bin](bin) directory.

## Known issues
None

## License
All scripts and files hosted in this project and GitHub [docker-images/OracleGoldenGate](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License (UPL), Version 1.0.  See [LICENSE](./LICENSE) for details.

To download and run Oracle GoldenGate, regardless whether inside or outside a Docker container, you must download the binaries from the [Oracle Technology Network](http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html) and accept the license indicated at that page.

## Copyright
Copyright &copy; 2017 Oracle and/or its affiliates. All rights reserved.
