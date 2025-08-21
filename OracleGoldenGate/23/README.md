# Oracle GoldenGate 23ai Microservices Edition Container Images

Sample container image build files to provide an installation of Oracle GoldenGate for DevOps users.
These instructions apply to building container images for Oracle GoldenGate version 23ai.

## Contents

- [Oracle GoldenGate 23ai Microservices Edition Container Images](#oracle-goldengate-23ai-microservices-edition-container-images)
  - [Contents](#contents)
  - [Before You Start](#before-you-start)
  - [Build an Oracle GoldenGate Container Image](#build-an-oracle-goldengate-container-image)
    - [Changing the Base Image](#changing-the-base-image)
  - [Running Oracle GoldenGate in a Container](#running-oracle-goldengate-in-a-container)
    - [Administrative Account Password](#administrative-account-password)
    - [SSL Certificate](#ssl-certificate)
    - [Running the Administration Client](#running-the-administration-client)
    - [Running Scripts Before Setup and on Startup](#running-scripts-before-setup-and-on-startup)
  - [Known Issues](#known-issues)
  - [License](#license)
  - [Copyright](#copyright)

## Before You Start

This project was tested with:

- Oracle GoldenGate 23.4 Microservices for Oracle on Linux x86-64
- Oracle GoldenGate 23.4 Microservices for PostgreSQL on Linux x86-64
- Oracle GoldenGate 23.4 Microservices for MSSQL on Linux x86-64
- Oracle GoldenGate 23.4 Microservices for MYSQL on Linux x86-64
- Oracle GoldenGate 23.8 Microservices for Distributed Applications and Analytics on Linux x86-64

**IMPORTANT:** You must download the installation binaries of Oracle GoldenGate. You only need to provide the binaries for the version you plan to install. The binaries can be downloaded from the [Oracle Technology Network](https://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html). Do not decompress the Oracle GoldenGate ZIP file. The container build process will handle that
for you. You also must have Internet connectivity when building the container image for the package manager to perform additional software installations.

All shell commands in this document assume the usage of Bash shell.

For more information about Oracle GoldenGate please see the [Oracle GoldenGate 23ai On-line Documentation](https://docs.oracle.com/en/middleware/goldengate/core/23/index.html).

## Build an Oracle GoldenGate Container Image

Once you have downloaded the Oracle GoldenGate software, a container image can be created using container management command-line applications.
A single `--build-arg` is needed to indicate the GoldenGate installer that was downloaded.

To create a container image for GoldenGate for Oracle Database, use the following script:

```sh
$ docker build --tag=oracle/goldengate:23.4 \
               --build-arg INSTALLER=234000_fbo_ggs_Linux_x64_Oracle_services_shiphome.zip .
Sending build context to Docker daemon
...
Successfully tagged oracle/goldengate:23.4
```

Similarly, for other Databases like BigData, MySQL, PostgreSQL, etc. provide the name of the zip file for the INSTALLER argument.

### Changing the Base Image

By default, the base container image used to create the Oracle GoldenGate container image is `oraclelinux:8`. This can be changed using the `BUILD_IMAGE` build argument. For example:

```sh
docker build --tag=oracle/goldengate:23.4 \
             --build-arg BASE_IMAGE="localregistry/oraclelinux:8" \
             --build-arg INSTALLER=234000_fbo_ggs_Linux_x64_Oracle_services_shiphome.zip .
```

Oracle GoldenGate 23ai requires a base container image with Oracle Linux 8 or later.

## Running Oracle GoldenGate in a Container

Use the `docker run` command to create and start a container from the Oracle GoldenGate container image.

```sh
docker run \
    --name <container name> \
    -p <host port>:443 \
    -e OGG_ADMIN=<admin user name> \
    -e OGG_ADMIN_PWD=<admin password> \
    -e OGG_DEPLOYMENT=<deployment name> \
    -v [<host mount point>:]/u01/ogg/scripts \
    -v [<host mount point>:]/u02 \
    -v [<host mount point>:]/u03 \
    -v [<host mount point>:]/etc/nginx/cert \
    oracle/goldengate:23.4
```

Parameters:

- `<container name>`   - A name for the new container (default: auto-generated)
- `-p <host-port>`     - The host port to map to the Oracle GoldenGate HTTPS server (default: no mapping)
- `-e OGG_ADMIN`       - The name of the administrative account to create (default: `oggadmin`)
- `-e OGG_ADMIN_PWD`   - The password for the administrative account (default: auto-generated)
- `-e OGG_DEPLOYMENT`  - The name of the deployment (default: `Local`)
- `-v /u01/ogg/scripts`- The volume used for executing setup (`${OGG_HOME}/scripts/setup`) and startup (`${OGG_HOME}/scripts/startup`) user scripts (default: none)
- `-v /u02`            - The volume used for persistent GoldenGate data (default: use container storage)
- `-v /u03`            - The volume used for temporary GoldenGate data (default: use container storage)
- `-v /etc/nginx/cert` - The volume used for storing the SSL certificate for the HTTPS server (default: create a self-signed certificate)

All parameters are optional, so the following command will work, too:

```sh
$ docker run oracle/goldengate:23.4
----------------------------------------------------------------------------------
--  Password for OGG administrative user 'oggadmin' is 'XU2k7cMastmt-DJKs'
----------------------------------------------------------------------------------
...
```

See the following sections for additional details.

### Administrative Account Password

On the first startup of the container, a random password will be generated for the Oracle GoldenGate administrative user if not provided by the `OGG_ADMIN_PWD` environment variable. You can find this password at the start of the container log:

```sh
$ docker logs <container name> | head -3
----------------------------------------------------------------------------------
--  Password for OGG administrative user 'oggadmin' is 'ujX7sqQ430G9-xSlr'
----------------------------------------------------------------------------------
```

### SSL Certificate

When bringing your own SSL certificate to an Oracle GoldenGate container, two files are needed:

1. `ogg.key` - The private key for the SSL certificate.
1. `ogg.pem` - The SSL leaf certificate, and a full certificate trust chain

If these files are located in a directory called `cert`, they can be used in the GoldenGate container with a volume mount as shown here:

```sh
$ docker run -v ${PWD}/cert:/etc/nginx/cert:ro -p 8443:443 oracle/goldengate:23.4
...
```

The certificate file, `ogg.pem`, must contain a full certificate chain starting with the leaf certificate, and followed by all other certificates in the Certificate Authority chain.

```pem
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
```

### Running the Administration Client

The **Administration Client** utility can be run with this command:

```sh
$ docker exec -ti --user ogg <container name> adminclient
Oracle GoldenGate Administration Client for Oracle
Version 23.4 ...
```

### Running Scripts Before Setup and on Startup

The container images can be configured to run scripts before setup and on startup. Currently, `.sh` and `.py` extensions are supported. For setup scripts just mount the volume `/u01/ogg/scripts/setup` or extend the image to include scripts in this directory. For startup scripts just mount the volume `/u01/ogg/scripts/startup` or extend the image to include scripts in this directory. Both of those locations
are static and the content is controlled by the volume mount.

The example below mounts the local directory `${PWD}/myScripts` to `/u01/ogg/scripts` which is then searched for custom startup scripts:

```sh
docker run -v "${PWD}/myScripts:/u01/ogg/scripts" oracle/goldengate:23.4
```

## Known Issues

None

## License

All scripts and files hosted in this project and GitHub [docker-images/OracleGoldenGate](../) repository required to build the container images are, unless otherwise noted, released under the Universal Permissive License (UPL), Version 1.0.  See [LICENSE](/LICENSE) for details.

To download and run Oracle GoldenGate, regardless of whether inside or outside a container, you must download the binaries from the [Oracle Technology Network](https://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html) and accept the license indicated on that page.

## Copyright

Copyright &copy; 2022, 2024 Oracle and/or its affiliates.
