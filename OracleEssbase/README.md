Oracle Essbase Container Images
=============
Sample containers to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) for Oracle Essbase 21c based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle FMW Infrastructure 12.2.1.4.0.

For more information about Oracle Essbase please see the [Oracle Essbase 21c Online Documentation](https://docs.oracle.com/en/database/other-databases/essbase/21/index.html).

The certification of Oracle Essbase on containers does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## Oracle Essbase Container Image Creation

To build the Essbase image either you can start from building Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle Fusion Middleware Infrastructure image. The Fusion Middleware Infrastructure image is available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there. If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with "Building the Oracle Essbase Image".

NOTE: If you download the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you need to retag the image with appropriate version. e.g. for the 12.2.1.4.0 version, retag from `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4` to `oracle/fmw-infrastructure:12.2.1.4`.

```
$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4
```

### Building the Oracle Java (Server JRE) Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleJava/README.md) under docker/OracleJava for details on how to build Oracle Database image.

https://github.com/oracle/docker-images/tree/master/OracleJava/README.md

### Building the Oracle FMW Infrastructure Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleFMWInfrastructure/README.md) under docker/OracleFMWInfrastructure for details on how to build Oracle Fusion Middleware Infrastructure image.
 
### Building the Oracle Essbase Image

IMPORTANT: To build the Oracle Essbase image, you must first download the required version of the Oracle Essbase installer. This installer must be downloaded and copied into the folder with the same version for e.g. 21.1.0.0.0 binaries need to be dropped into `../OracleEssbase/dockerfiles/21.1.0`. 

The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com). Search for "Oracle Essbase" and download the version which is required, e.g. 21.1.0.0.0.

Extract the downloaded zip files and copy the `essbase_211_installer/essbase-21.1.0.0.0-171-linux64.jar` file to `dockerfiles/21.1.0` for building Oracle Essbase 21.1.0 image.

>IMPORTANT: To build the Essbase image with patches, you need to download and drop the patch zip files (for e.g. `p29928100_122134_Generic.zip`) into the `patches/` folder under the version which is required, for e.g. for `21.1.0.0.0` the folder is `21.1.0/patches`. Then run the `buildContainerImage.sh` script as mentioned below:

If a proxy is needed for the host to access yum.oracle.com during build, then first set up the appropriate environment, e.g.:

```
$ export http_proxy=myproxy.example.com:80
$ export https_proxy=myproxy.example.com:80
$ export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
```

Build the Oracle Essbase 21.1.0 image using:

```
$ sh buildContainerImage.sh -v 21.1.0

Usage: buildContainerImage.sh -v [version]
Builds a Container Image for Oracle Essbase.
```

Verify you now have the image `oracle/essbase:21.1.0` in place with 

```
$ docker images | grep "essbase"
```

If you are building the Essbase image with patches, you can verify the patches applied with:

```
$ docker run oracle/essbase:21.1.0 sh -c '$ORACLE_HOME/OPatch/opatch lspatches'
```

>IMPORTANT: The image created in above step will NOT have a domain pre-configured. But it has the scripts to create and configure a Essbase domain.

## Creating an Oracle Essbase Container

The Essbase image provides a script to create and start a single-node Essbase domain.

This script is invoked when a container is started using the image. If the container is subsequently restarted, then the Essbase domain is restarted automatically.

### Starting a new container

The following environment variables are supported when starting the container:

| Name | Required | Default | Description |
| ---- | -------- | ------- | ----------- |
| DOMAIN_ROOT | | /u01/config/domains |	|
| ARBORPATH   | | /u01/data/essbase | |
| TMP_DIR     | | /u01/tmp | |
| ADMIN_USERNAME | | admin | |
| ADMIN_PASSWORD | | welcome1 | |	
| DATABASE_TYPE  | | oracle | |
| DATABASE_CONNECT_STRING | | rcu-db:1521/PDBORCL | |
| DATABASE_ADMIN_USERNAME | | sys | |	
| DATABASE_ADMIN_PASSWORD | | |
| DATABASE_ADMIN_ROLE     | | | If not set, the container will use sysdba if the database type is oracle and the user is 'sys' |
| DATABASE_SCHEMA_PASSWORD | | | If not set, the container will randomly set the value |
| DATABASE_SCHEMA_PREFIX   | | ESS1 | |
| DATABASE_SCHEMA_TABLESPACE | | | Tablespace to apply when creating the RCU schemas. If not provided, will use the default for each schema. |
| DATABASE_SCHEMA_TEMP_TABLESPACE | | | Temp tablespace to apply when creating the schemas. If not provided, will use the default for each schema. |
| DATABASE_WAIT_TIMEOUT | | 0 | If set to a non-zero value, the container will wait for up to the provided value for the database to be available. |
| CREATE_SCHEMA | | TRUE | |
| DROP_SCHEMA | | FALSE	| |
| ADMIN_SERVER_PORT | | 7001 | Standard listen port of the admin server. This is not the host port. |
| ADMIN_SERVER_SSL_PORT | | 7002 | Standard ssl listen port of the admin server. This is not the host port. |
| ADMIN_SERVER_HOSTNAME_ALIAS | | | Defines the network alias with which to connect to the adminserver. Used for composed environments. |
| MANAGED_SERVER_PORT | | 9000 | Standard listen port for the managed server. This is not the host port. |
| MANAGED_SERVER_SSL_PORT | | 9001 | Standard ssl listen port for the managed server. This is not the host port. |
| ESSBASE_CLUSTER_SIZE | | 1 | Number of managed servers to create in the configuration. |
| MANAGED_SERVER_HOSTNAME_ALIAS | | | Defines the network alias with which to connect to the managed server. Used only at runtime for composed environments to register the "external" hostname for the target server.
| AGENT_PORT | | 1423 | |
| AGENT_SSL_PORT | | 6423 | |
| ESSBASE_SERVER_MIN_PORT | | 30768 | |
| ESSBASE_SERVER_MAX_PORT | | 31768 | |
| ENABLE_EAS | | FALSE | | 
| EAS_SERVER_PORT | | 9100 | |	
| EAS_SERVER_SSL_PORT | | 9101 | |
| ESSBASE_CFG_OVERRIDES | | /etc/essbase/essbase_overrides.cfg | Specifies an essbase.cfg file mounted in the container to be used to update the runtime essbase.cfg settings during domain creation. |


ORACLE_HOME is fixed to `/u01/oracle`. DOMAIN_NAME is fixed to `essbase_domain`

## Known Issues

1. If the container is restarted, it requires the same set of environment variables passed in again, even though the domain has already been created.

## License

To download and run Oracle Essbase 21c regardless of inside or outside a container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [docker/OracleEssbase](./) repository required to build the container images are, unless otherwise noted, released under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## Copyright

Copyright (c) 2021, Oracle and/or its affiliates.
