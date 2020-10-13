Oracle Unified Directory (OUD) on Docker
========================================

## Contents

1. [Introduction](#1-introduction-1)
2. [Hardware and Software Requirements](#2-hardware-and-software-requirements)
3. [Prerequisites](#3-prerequisites)
4. [Building OUD Docker Image](#4-loading-or-building-oud-docker-image)
5. [Preparing to Run OUD Docker Image](#5-preparing-to-run-oud-docker-image)
6. [Running OUD Docker Container](#6-running-oud-docker-container)

# 1. Introduction

Oracle Unified Directory provides comprehensive Directory Solution for robust Identity Management.

Oracle Unified Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Unified Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project offers Dockerfile and scripts to build an Oracle Unified Directory image based on 12cPS4 (12.2.1.4.0) release. Use this Docker Image to facilitate installation, configuration, and environment setup for DevOps users. 

This Image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create different types of OUD Instances (Directory Service, Proxy, Replication) on containers targeted for development and testing.

***Image***: oracle/oud:12.2.1.4.0

# 2. Hardware and Software Requirements
Oracle Unified Directory Docker Image has been tested and is known to run on following hardware and software:

## 2.1 Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

## 2.2 Software Requirements

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 18.03 or higher | docker version            |

# 3. Prerequisites

## 3.1 Pulling the Oracle JDK (Server JRE) base image
You can pull the Oracle Server JRE 8 image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the Server JRE 8 image, re-tag the image so that it works with the dependent Dockerfiles which refer to the JRE 8 image through oracle/serverjre:8.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions".

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Java** and then click on **serverjre**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

        
        $ docker login container-registry.oracle.com
        $ docker pull container-registry.oracle.com/java/serverjre:8
        $ docker tag container-registry.oracle.com/java/serverjre:8 oracle/serverjre:8


# 4. Loading or Building OUD Docker Image

## 4.1 Loading OUD Docker Image
If OUD Docker Image is to be loaded into a Docker environment through a TAR file (oracle_oud_122140.tar.gz), the following command can be invoked to load the image.

        
        $ docker load < oracle_oud_122140.tar.gz

If the TAR file (oracle_oud_122140.tar.gz) containing the OUD Docker Image is accessible via an HTTP URL, the following command can be invoked to load the image.
        
        $ wget -O - http://<URL to access oracle_oud_122140.tar.gz> | docker load
        
You should see output similar to that below:

        b87942114db6: Loading layer [==================================================>]  124.2MB/124.2MB
        bda521d1195e: Loading layer [==================================================>]  162.7MB/162.7MB
        fc1edb4cdeef: Loading layer [==================================================>]  9.562MB/9.562MB
        29bf3f1d3e51: Loading layer [==================================================>]  509.6MB/509.6MB
        881c99b5c480: Loading layer [==================================================>]  152.1MB/152.1MB
        Loaded image: oracle/oud:12.2.1.4.0

If you run the 'docker images' command, loaded image should be displayed similar to the output below:

       $ docker images
       REPOSITORY                                     TAG                 IMAGE ID            CREATED             SIZE
       oracle/oud                                     12.2.1.4.0          1855f331f5ef        8 days ago          945MB
       ....

## 4.2 Building OUD Docker Image

### Clone and download Oracle Unified Directory docker scripts and binary file
1. Clone the [GitHub repository](https://github.com/oracle/docker-images) or download and extract the OUD Docker Repository TAR file (OracleUnifiedDirectory.tar.gz).
The repository contains Docker files and scripts to build Docker images for Oracle products.
2. You must download and save the Oracle Unified Directory 12.2.1.4.0 binary into the cloned/downloaded repository folder at location : `OracleUnifiedDirectory/dockerfiles/12.2.1.4.0/` (see **Checksum** for file name which is inside dockerfiles/12.2.1.4.0/oud.download).

### Build OUD Docker Image using cloned/downloaded docker-images repository
To assist in building the image, you can use the [`buildDockerImage.sh`](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

**IMPORTANT**: If you are building the Oracle Unified Directory image, you must first download the Oracle Unified Directory 12.2.1.x binary (fmw_12.2.1.4.0_oud.jar) and locate it in the folder, `./dockerfiles/12.2.1.4.0`.

Note: Copy the **fmw_12.2.1.4.0_oud.jar** under the directory "FMW-DockerImages-stage/OracleUnifiedDirectory/dockerfiles/12.2.1.4.0"

    Build script "buildDockerImage.sh" is located at "FMW-DockerImages-stage/OracleUnifiedDirectory/dockerfiles"

        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version]
        Builds a Docker Image for Oracle Unified Directory

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.4.0
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

# 5. Preparing to Run OUD Docker Image

## 5.1. Mount a host directory as a data volume
You need to mount volume(s), which are directories stored outside a container's file system, to store OUD Instance files and any other configuration. The default location of the `user_projects` volume in the container is `/u01/oracle/user_projects` (under this directory, the OUD instance directory is created). 

This option lets you mount a directory from your host to a container as volume. This volume is used to store OUD Instance files. 

To prepare a host directory (for example: /scratch/test/oud_user_projects) for mounting as a data volume, execute the command below:

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.
> This ensures 'oracle' user has access to shared volume.

```
sudo su - root
mkdir -p /scratch/test/oud_user_projects
chown 1000:1000 /scratch/test/oud_user_projects
exit
```

All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**

## 5.2 Bridged Network for running containers with OUD Instances/Components
In Docker, a bridged network is a software bridge which allows containers connected to the bridge to communicate, while isolating containers that are not connected to the bridge. You will be running OUD 12c containers on a single Docker daemon host so require a bridged network.

Create the Docker network for the Infra servers to run:

	$ docker network create -d bridge InfraNET

When creating different containers with OUD components, the same network can be specified for connectivity across containers.

# 6. Running OUD Docker Container

OUD Docker Image supports running containers as either of following:
*  Directory Server/Service [instanceType=Directory]
*  Directory Proxy Server/Service [instanceType=Proxy]
*  Replication Server/Service [instanceType=Replication]
*  Directory Server/Service added to existing Directory or Replication Server/Service [instanceType=AddDS2RS]
*  Directory Client to run CLIs like ldapsearch, dsconfig, dsreplication, etc.

The functionality and features available from the OUD container will depend on the environment variables passed when setting up/starting container. Configuration of instances with support for Proxy and Replication require invocation of dsconfig and dsreplication commands following the execution of oud-setup. With invocation of such commands, most of the possible configurations can be performed. To provide flexibility , the OUD 12c Docker Image is designed to support passing dsconfig and dsreplication parameters as required, to be used with commands after instance creation through oud-setup or oud-proxy-setup.

Commands and parameters to Start/Create a container running an OUD instance, based on the image built/loaded in the previous section are shown below. Following is an example for command to start/run container with OUD Docker Image:

    $ docker run -d -P --network=InfraNET \
    --name=<container name> \
    --volume <Path for the directory on Host which is to be mounted in container for user_projects>:/u01/oracle/user_projects \
    --env OUD_INSTANCE_NAME=<name for the instance> \
    --env hostname=<hostname for the instance in container> \
    --env-file <Path for the file containing environment variables>  \
    oracle/oud:12.2.1.X

> Parameters used in this example are described briefly in table below...

| **Parameter** | **Description** | **Default Value** |
| ------ | ------ | ------ |
| --name | Name for the container. While wiring multiple containers, this name would be useful for referencing. | ------ |
| --volume | When it's required to keep OUD configuration and data outside container, this volume parameter would be helpful. | ------ |
| --network | Based on the value for this parameter, container would be connected to network | ------ |
| --env OUD_INSTANCE_NAME | Name for the OUD instance. This is even used to decide directory name inside user_projects. If instance name is 'myoudasinst_1', location for OUD instance would be /u01/oracle/user_projects/myoudasinst_1. When user_projects directory is shared and outside container, avoid having same name for multiple instances. | asinst_1 |
| --env instanceType | Based on the value for this, type of OUD instance creation would be decided.| Directory |
| --env hostname | hostname to be used while invoking oud-setup, oud-proxy-setup, dsconfig and dsreplication commands. | localhost |
| --env-file | Instead of passing environment variables through command line with parameter --env,  multiple environment variables can be stored in file and path for the same can be passed. | ------ |

In the section(s) below, more parameters/variables are described.

## Environment Variables

| **Environment Variable** (To be passed through --env or --env-file) | **Description** | **Default Value** |
| ------ | ------ | ------ |
| OUD_INSTANCE_NAME | Name for the OUD instance. This is even used to decide directory name inside user_projects. If instance name is 'myoudasinst_1', location for OUD instance would be /u01/oracle/user_projects/myoudasinst_1. When user_projects directory is shared and outside container, avoid having same name for multiple instances. | asinst_1 |
| instanceType | Based on the value for this, type of OUD instance creation would be decided.| Directory |
| hostname | hostname to be used while invoking oud-setup, oud-proxy-setup, dsconfig and dsreplication commands. This will be taken into account even for the generation of self-signed certificate. | localhost |
| ldapPort | Port on which OUD Instance in the container should listen for LDAP Communication. Use 'disabled' if you do not want to enable it. | 1389 |
| ldapsPort | Port on which OUD Instance in the container should listen for LDAPS Communication. Use 'disabled' if you do not want to enable it. | 1636 |
| rootUserDN | DN for the initial root user for OUD Instance |   |
| rootUserPassword | Password for rootUserDN |   |
| adminConnectorPort | Port on which OUD Instance in the container should listen for Administration Communication over LDAPS Protocol. Use 'disabled' if you do not want to enable it. Note that at least one of the LDAP or the HTTP administration ports must be enabled. | 1444 |
| httpAdminConnectorPort | Port on which OUD Instance in the container should listen for Administration Communication over HTTPS Protocol. Use 'disabled' if you do not want to enable it. Note that at least one of the LDAP or the HTTP administration ports must be enabled. | 1888 |
| httpPort | Port on which OUD Instance in the container should listen for HTTP Communication. Use 'disabled' if you do not want to enable it. | 1080 |
| httpsPort | Port on which OUD Instance in the container should listen for HTTPS Communication. Use 'disabled' if you do not want to enable it. | 1081 |
| sampleData | Specifies that the database should be populated with the specified number of sample entries. When the parameter is having non-numeric value, --addBaseEntry would be added the command instead of --sampleData. when the ldifFile_n parameter is specified sampleData will not be considered and ldifFile entries will be populated. | 0 |
| adminUID | User ID of the Global Administrator to use to bind to the server. This parameter would be mainly used with dsreplication command. |   |
| adminPassword | Password for adminUID |   |
| bindDN1 | BindDN to be used while setting up replication using dsreplication to connect to First Directory/Replication Instance. This parameter would be mainly used with dsreplication command. |   |
| bindPassword1 | Password for bindDN1 |   |
| bindDN2 | BindDN to be used while setting up replication using dsreplication to connect to Second Directory/Replication Instance. This parameter would be mainly used with dsreplication command. |   |
| bindPassword2 | Password for bindDN2 |   |
| replicationPort | Port value to be used while setting up replication server. This variable is only used to substitute values in dsreplication parameters. It's helpful if you need to use the value multiple times in different dsreplication parameters. | 1898 |
| sourceHost | Value for the hostname which is to be considered as source while setting up replication. This variable is only used to substitute values in dsreplication parameters. It's helpful if you need to use the value multiple times in different dsreplication parameters.  | --- |
| initializeFromHost | Hostname to be used while initializing data on new instance from existing instance. This variable is only used to substitute values in dsreplication parameters. It's helpful if you need to use the value multiple times in different dsreplication parameters. It's possible to have different value for sourceHost and initializeFromHost - while setting up replication with Replication Server, sourceHost can be used for Replication Server and initializeFromHost can be used for existing Directory instance from data is required to be initialized.| $sourceHost |
| serverTuning | ServerTuning value to be used to tune the jvm settings. This variable if not specified will consider JVM-default as the default value or need to specify the complete set of values with options if you want to set to specific values for tuning | jvm-default |
| offlineToolsTuning | offlineToolsTuning value to be used to specify the tuning for offline tools. This variable if not specified will consider jvm-default as the default or specify the complete set of values with options if wanted to set to specific tuning | jvm-default|
| generateSelfSignedCertificate | generateSelfSignedCertificate value should be provided as "true" to use generateSelfSignedCertificate parameter for OUD-SETUP. By default this parameter will be set to "true" if no value is provided. If any other certificate parameter needs to be used for OUD-SETUP generateSelfSignedCertificate should be provided as false. | true |
| usePkcs11Keystore | usePkcs11Keystore value should be provided as "true" to use usePkcs11Keystore parameter for OUD-SETUP. By default this parameter will be set to empty. To use this option generateSelfSignedCertificate should be provided as false.| --- |
| enableStartTLS | enableStartTLS value should be provided as "true" to use usePkcs11Keystore parameter for OUD-SETUP. By default this parameter will be set to empty. To use this option generateSelfSignedCertificate should be provided as false. | --- |
| useJCEKS | useJCEKS value should be with the path of the keyStore. for example useJCEKS=/u01/oracle/config/keystore to use useJCEKS parameter for OUD-SETUP. By default this parameter will be set to empty. To use this option generateSelfSignedCertificate should be provided as false. | --- |
| useJavaKeystore | useJavaKeystore value should be with the path of the keyStore. for example useJavaKeystore=/u01/oracle/config/keystore to use useJavaKeystore parameter for OUD-SETUP. By default this parameter will be set to empty. To use this option generateSelfSignedCertificate should be provided as false. | --- |
| usePkcs12keyStore | usePkcs12keyStore value should be with the path of the keyStore. for example usePkcs12keyStore=/u01/oracle/config/keystore.p12 to use usePkcs12keyStore parameter for OUD-SETUP. By default this parameter will be set to empty. | --- |
| keyStorePasswordFile | keyStorePasswordFile value should be with the path of the Password File. for example keyStorePasswordFile=/u01/oracle/config/keystorepassword.txt to use keyStorePasswordFile parameter for OUD-SETUP. By default this parameter will be set to empty. | --- |
| eusPasswordScheme | eusPasswordScheme value should be with value either "sha1/sha2" to use eusPasswordScheme parameter for OUD-SETUP. By default this parameter will be set to empty. | --- |
| jmxPort | Port on which the Directory Server should listen for JMX communication.  Use 'disabled' if you do not want to enable it. | disabled |
| javaSecurityFile | javaSecurityFile value to be used to update the existing java.security file with the new java security file, The path of the new file should be accessible from the container and has to be mentioned as the varible in env file i.e., ex: javaSecurityFile=/u01/oracle/config/new_security_file . By default this value will be empty. | --- |
| schemaConfigFile_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents full path of ldif file that needs to be passed to OUD instance for schema configuration/extension. Path of each file should be accessible from the container. ex: schemaConfigFile_1=/u01/oracle/config/00_test.ldif variable. If file is having "changeType: modify", schema would be loaded using ldapmodify command. | --- |
| ldifFile_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents the full path of the ldif file that needs to be passed to initialize the new input ldif file, The path of the new file should be accessible from the container and has to be mentioned as the varible in env file i.e., ex: ldifFile_1=/u01/oracle/config/test1.ldif variable.| --- |
| dsconfigBatchFile_n |n' in variable name represents numeric value between 1 to 50. Each such variable represents the full path of file that needs to be passed to dsconfig command as batch file. Path of each file should be accessible from container. For each dsconfigBatchFile_n variable, dsconfig command would be invoked. While executing dsconfig command for each variable, ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} parameters would be added implicitly. ex: dsconfigBatchFile_1=/u01/oracle/config/dsconfig_1.txt | --- |
| dstune_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents a command that needs to be passed with all the options for dstune command. Based on the method specified its subcommand, options need to be provided as a full command for dstune_n variable.| --- |
| dsconfig_n | 'n' in variable name represents numeric value between 1 to 300. Each such variable represents set of execution parameters for dsconfig command. While executing dsconfig command for the variable, ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} parameters would be added implicitly. In each such dsconfig_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost} and ${baseDN} would be replaced with value for them as individual variables. | --- |
| dsreplication_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents set of execution parameters for dsreplication command. While executing dsreplication command for the variable, $bindDN1, $bindPasswordFile1, $bindDN2, $bindPasswordFile2, $adminUID and $adminPasswordFile parameters would be added implicitly based on the dsreplication sub-command. In each such dsreplication_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost} and ${baseDN} would be replaced with value for them as individual variables.  | --- |
| post_dsreplication_dsconfig_n | This is for dsconfig commands which are to be executed after execution of dsreplication commands. Apart from the parameters mentioned for post_dsreplication_dsconfig_n, parameter --provider-name "Multimaster Synchronizatin" would be additionally added implicitly. While executing dsconfig command for the variable, ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} parameters would be added implicitly. In each such dsconfig_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost} and ${baseDN} would be replaced with value for them as individual variables. | --- |
| rebuildIndex_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents set of execution parameters for rebuild-index command. While executing rebuild-index command for the variable, ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} parameters would be added implicitly. In each such rebuild-index_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${baseDN}, etc. would be replaced with value for them as individual variables. | --- |
| manageSuffix_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents set of execution parameters for manage-suffix command. While executing manage-suffix command for the variable, ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} parameters would be added implicitly. In each such manageSuffix_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost} and ${baseDN} would be replaced with value for them as individual variables. | --- |
| importLdif_n | 'n' in variable name represents numeric value between 1 to 50. Each such variable represents set of execution parameters for import-ldif command. While executing import-ldif command for the variable, ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} parameters would be added implicitly. In each such importLdif_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost} and ${baseDN} would be replaced with value for them as individual variables. | --- |
| execCmd_n | 'n' in variable name represents numeric value between 1 to 300. Each such variable represents a command to be executed from container. In each such execCmd_n variable value, strings (case-sensitive) like ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost} and ${baseDN} would be replaced with value for them as individual variables. | --- |
| restartAfterDstune | Based on this, OUD instance would be restarted after executing all dstune commands according to dstune_n variables. | false |
| restartAfterDsconfig | Based on this, OUD instance would be restarted after executing all dsconfig commands according to dsconfig_n variables. | false |
| restartAfterPostDsreplDsconfig | Based on this, OUD instance would be restarted after executing all dsconfig commands according to post_dsreplication_dsconfig_n variables. | false |
| restartAfterDsreplication | Based on this, OUD instance would be restarted after executing all dsreplication commands according to dsreplication_n variables. | false |
| restartAfterJavaSecurityFile | Based on this, OUD instance would be restarted after updating java.security file. | false |
| restartAfterSchemaConfig | Based on this, OUD instance would be restarted after processing all schema config files. | false |
| restartAfterRebuildIndex | Based on this, OUD instance would be restarted after executing all rebuild-index commands according to rebuildIndex_n variables. | false |
| restartAfterManageSuffix | Based on this, OUD instance would be restarted after executing all manage-suffix commands according to managSuffix_n variables. | false |
| restartAfterImportLdif | Based on this, OUD instance would be restarted after executing all import-ldif commands according to importLdif_n variables. | false |
| ignoreErrorDstune | If the value for this variable is 'false' and if the execution of dstune command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorDsconfig | If the value for this variable is 'false' and if the execution of dsconfig command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorPostDsreplDsconfig | If the value for this variable is 'false' and if the execution of dsconfig (based on post_dsreplication_dsconfig_n) command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorDsreplication | If the value for this variable is 'false' and if the execution of dsreplication command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorSchemaConfig | If the value for this variable is 'false' and if the execution of ldapmodify command for updating schema has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorRebuildIndex | If the value for this variable is 'false' and if the execution of rebuild-index command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorManageSuffix | If the value for this variable is 'false' and if the execution of manage-suffix command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorImportLdif | If the value for this variable is 'false' and if the execution of import-ldif command has returend non-zero execution status, OUD instance configuration would be aborted. | true |
| ignoreErrorExecCmd | If the value for this variable is 'false' and if the execution of command based on execCmd_n variable has returend non-zero execution status, OUD instance configuration would be aborted. | true |

## Example 1: Directory Server/Service [instanceType=Directory]

In this example you will create two containers, each of which will host a single OUD 12c Directory Server/Service.

Environment variables will be passed as default values, additional variables in [samples/oud-dir.env](samples/oud-dir.env) and variables passed with the `docker run` command.

[samples/oud-dir.env](samples/oud-dir.env):<br>
   **instanceType**=*Directory*<br>
   **OUD_INSTANCE_NAME**=myoudds1<br>
   **hostname**=myoudds1<br>
   **baseDN**=dc=example1,dc=com<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123
   
Save [samples/oud-dir.env](samples/oud-dir.env) as ~/oud-dir.env.

Run the docker command to create the OUD12c Directory Server container.

    docker run -d --network=InfraNET \
    --name=myoudds1 \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env-file ~/oud-dir.env \
    oracle/oud:12.2.1.4.0
    
Check that you can retrieve entries from the OUD instance.

    docker run -it --rm --network=InfraNET \
    --name=MyOUDClient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/ldapsearch \
    -h myoudds1 \
    -p 1389 \
    -D "cn=Directory Manager" \
    -w "Oracle123" \
    -b "dc=example1,dc=com" \
    "(objectClass=person)" dn

You should see entries output similar to that below:

    ...
    dn: uid=user.97,ou=People,dc=example1,dc=com
    dn: uid=user.98,ou=People,dc=example1,dc=com
    dn: uid=user.99,ou=People,dc=example1,dc=com

> According to baseDN value in env file, Directory instance would be created with base-dn dc=example1,dc=com.

Run the docker command a second time to create another OUD 12c Directory Server container.

    docker run -d --network=InfraNET  \
    --name=myoudds2 \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env-file ~/oud-dir.env \
    --env OUD_INSTANCE_NAME=myoudds2 \
    --env hostname=myoudds2 \
    --env baseDN="dc=example2,dc=com" \
    oracle/oud:12.2.1.4.0
> Based on the --env parameters, values for environment variables specified with --env-file would be overridden.

Check that you can retrieve entries from the OUD instance.

    docker run -it --rm --network=InfraNET \
    --name=MyOUDClient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/ldapsearch \
    -h myoudds2 \
    -p 1389 \
    -D "cn=Directory Manager" \
    -w "Oracle123" \
    -b "dc=example2,dc=com" \
    "(objectClass=person)" dn

You should see entries output similar to those below:

    ...
    dn: uid=user.97,ou=People,dc=example2,dc=com
    dn: uid=user.98,ou=People,dc=example2,dc=com
    dn: uid=user.99,ou=People,dc=example2,dc=com

## Example 2: Directory Proxy Server/Service [instanceType=Proxy]

In this example you will create a single container, which will host a single OUD 12c Proxy Server/Service which can be used to front end the Directory Servers created in Example 1.

Environment variables will be passed as default values, additional variables in [samples/oud-proxy.env](samples/oud-proxy.env) and variables passed with the `docker run` command.

Note: To allow different samples/examples to work together, it's assumed that there would be same password used with different OUD instances for rootUser. 

[samples/oud-proxy.env](samples/oud-proxy.env):<br>
   **instanceType**=*Proxy*<br>
   **OUD_INSTANCE_NAME**=myoudp<br>
   **hostname**=myoudp<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123<br>
   **dsconfig_1**=create-extension --set enabled:true --set remote-ldap-server-address:myoudds1 --set remote-ldap-server-port:1389 --set remote-ldap-server-ssl-port:1636 --extension-name ldap_extn_1 --type ldap-server<br>
   **dsconfig_2**=create-workflow-element --set client-cred-mode:use-client-identity --set enabled:true --set ldap-server-extension:ldap_extn_1 --type proxy-ldap --element-name proxy_ldap_wfe_1<br>
   **dsconfig_3**=create-workflow --set base-dn:dc=example1,dc=com --set enabled:true --set workflow-element:proxy_ldap_wfe_1 --type generic --workflow-name wf_1<br>
   **dsconfig_4**=set-network-group-prop --group-name network-group --add workflow:wf_1<br>
   **dsconfig_5**=create-extension --set enabled:true --set remote-ldap-server-address:myoudds2 --set remote-ldap-server-port:1389 --set remote-ldap-server-ssl-port:1636 --extension-name ldap_extn_2 --type ldap-server<br>
   **dsconfig_6**=create-workflow-element --set client-cred-mode:use-client-identity --set enabled:true --set ldap-server-extension:ldap_extn_2 --type proxy-ldap --element-name proxy_ldap_wfe_2<br>
   **dsconfig_7**=create-workflow --set base-dn:dc=example2,dc=com --set enabled:true --set workflow-element:proxy_ldap_wfe_2 --type generic --workflow-name wf_2<br>
   **dsconfig_8**=set-network-group-prop --group-name network-group --add workflow:wf_2
> Note the usage of hostname values myoudds1 and myoudds2.

Save [samples/oud-proxy.env](samples/oud-proxy.env) as ~/oud-proxy.env.

Run the docker command to create the OUD12c Proxy Server container.

    docker run -d --network=InfraNET \
    --name=myoudp \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env-file ~/oud-proxy.env \
    oracle/oud:12.2.1.4.0
    
Validate that you can access the myoudds1 (cd=example1,dc=com) and myoudds2 (cd=example2,dc=com) OUD instances via the Proxy Server, myoudp.

    docker run -it --rm --network=InfraNET \
    --name=MyOUDClient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/ldapsearch \
    -h myoudp \
    -p 1389 \
    -D "cn=Directory Manager" \
    -w "Oracle123" \
    -b "dc=example1,dc=com" \
    "(objectClass=person)" dn
    
Returns:

    ...
    dn: uid=user.97,ou=People,dc=example1,dc=com
    dn: uid=user.98,ou=People,dc=example1,dc=com
    dn: uid=user.99,ou=People,dc=example1,dc=com
    
 While:   

    docker run -it --rm --network=InfraNET \
    --name=MyOUDClient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/ldapsearch \
    -h myoudp \
    -p 1389 \
    -D "cn=Directory Manager" \
    -w "Oracle123" \
    -b "dc=example2,dc=com" \
    "(objectClass=person)" dn
    
Returns:

    ...
    dn: uid=user.97,ou=People,dc=example2,dc=com
    dn: uid=user.98,ou=People,dc=example2,dc=com
    dn: uid=user.99,ou=People,dc=example2,dc=com

## Example 3: Replication Server/Service [instanceType=Replication]

In this example you will create a single container, which will host a single OUD 12c Replication Server/Service.  You will also add the Directory Server created in Example 1 (myoudds1) into the replication group managed by this Replication Server.

Environment variables will be passed as default values, additional variables in [samples/oud-add-replication.env](samples/oud-add-replication.env) and variables passed with the `docker run` command.

[samples/oud-add-replication.env](samples/oud-add-replication.env):<br>
   **instanceType**=*Replication*<br>
   **OUD_INSTANCE_NAME**=myoudrs1<br>
   **hostname**=myoudrs1<br>
   **baseDN**=dc=example1,dc=com<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123<br>
   **adminUID**=admin<br>
   **adminPassword**=Oracle123<br>
   **bindDN1**=cn=Directory Manager<br>
   **bindPassword1**=Oracle123<br>
   **bindDN2**=cn=Directory Manager<br>
   **bindPassword2**=Oracle123<br>
   **sourceHost**=myoudds1<br>
   **dsreplication_1**=disable --disableAll --hostname ${sourceHost} --port ${adminConnectorPort}<br>
   **dsreplication_2**=enable --host1 ${sourceHost} --port1 ${adminConnectorPort} --noReplicationServer1 --host2 ${hostname} --port2 ${adminConnectorPort} --replicationPort2 ${replicationPort} --onlyReplicationServer2 --baseDN ${baseDN}<br>
   **dsreplication_3**=status --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN} --dataToDisplay compat-view<br>
   **dsreplication_4**=verify --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN}<br>
> Before enabling the replication, disable is executed to make sure that if there is any existing replication in place, that's removed first.

Save [samples/oud-add-replication.env](samples/oud-add-replication.env) as ~/oud-add-replication.env.

    docker run -d --network=InfraNET \
    --name=myoudrs1 \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env-file ~/oud-add-replication.env \
    oracle/oud:12.2.1.4.0
    
To verify the replication server, run the following command:

    docker exec -it myoudrs1 \
    /u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
    --trustAll \
    --hostname myoudrs1 \
    --port 1444 \
    --adminUID admin \
    --dataToDisplay compat-view \
    --dataToDisplay rs-connections

Enter the admin password when prompted:

    >>>> Specify Oracle Unified Directory LDAP connection parameters/u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
    Password for user 'admin': Oracle123
    
Output should be similar to the following:

    Establishing connections and reading configuration ..... Done.
    dc=example1,dc=com - Replication Enabled
    ========================================
    Server         : Entries  : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
    ---------------:----------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------
    myoudrs1:1444  : -- [11]  : 0        : --           : 1898     : Disabled       : --        : --       : Up         : --            : 1            : --
    myoudds1:1444  : 102      : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudrs1:1898 (GID=1)

You can see that the Replication Server myoudrs1 has been created, and that myoudrs1 and the Directory Server myoudds1 have been added to the same replication group.

## Example 4: Directory Server/Service added to existing Replication Server/Service [instanceType=AddDS2RS]

In this example you will create a single container, which will host a single OUD 12c Directory Server/Service.  You will add this Directory Server to the replication group created in Example 3.

Environment variables will be passed as default values, additional variables in [samples/oud-add-dir-to-rs.env](samples/oud-add-dir-to-rs.env) and variables passed with the `docker run` command.

[samples/oud-add-dir-to-rs.env](samples/oud-add-dir-to-rs.env):<br>
   **instanceType**=*AddDS2RS*<br>
   **OUD_INSTANCE_NAME**=myoudds1b<br>
   **hostname**=myoudds1b<br>
   **baseDN**=dc=example1,dc=com<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123<br>
   **adminUID**=admin<br>
   **adminPassword**=Oracle123<br>
   **bindDN1**=cn=Directory Manager<br>
   **bindPassword1**=Oracle123<br>
   **bindDN2**=cn=Directory Manager<br>
   **bindPassword2**=Oracle123<br>
   **sourceHost**=myoudrs1<br>
   **initializeFromHost**=myoudds1<br>
   **dsreplication_1**=verify --hostname ${sourceHost} --port ${adminConnectorPort} --baseDN ${baseDN} --serverToRemove ${hostname}:${adminConnectorPort}<br>
   **dsreplication_2**=enable --host1 ${hostname} --port1 ${adminConnectorPort} --noReplicationServer1 --host2 ${sourceHost} --port2 ${adminConnectorPort} --replicationPort2 ${replicationPort} --onlyReplicationServer2 --baseDN ${baseDN}<br>
   **dsreplication_3**=initialize --hostSource ${initializeFromHost} --portSource ${adminConnectorPort} --hostDestination ${hostname} --portDestination ${adminConnectorPort} --baseDN ${baseDN}<br>
   **dsreplication_4**=verify --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN}<br>
   **dsreplication_5**=status --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN} --dataToDisplay compat-view
   
   Save [samples/oud-add-dir-to-rs.env](samples/oud-add-dir-to-rs.env) as ~/oud-add-dir-to-rs.env.

    docker run -d --network=InfraNET \
    --name=myoudds1b \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env OUD_INSTANCE_NAME=myoudds1b \
    --env hostname=myoudds1b \
    --env-file ~/oud-add-dir-to-rs.env \
    oracle/oud:12.2.1.4.0

To verify the replication server, run the following command:

    docker exec -it myoudrs1 \
    /u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
    --trustAll \
    --hostname myoudrs1 \
    --port 1444 \
    --adminUID admin \
    --dataToDisplay compat-view \
    --dataToDisplay rs-connections

Enter the admin password when prompted:

    >>>> Specify Oracle Unified Directory LDAP connection parameters/u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
    Password for user 'admin': Oracle123
    
Output should be similar to the following - the new Directory Server is displayed:

    Establishing connections and reading configuration ..... Done.
    dc=example1,dc=com - Replication Enabled
    ========================================
    Server         : Entries  : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
    ---------------:----------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------
    myoudrs1:1444  : -- [11]  : 0        : --           : 1898     : Disabled       : --        : --       : Up         : --            : 1            : --
    myoudds1:1444  : 102      : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudrs1:1898 (GID=1)
    myoudds1b:1444 : 102      : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudrs1:1898 (GID=1)

You can see that the new Directory Server myoudds1b has been created and added to the replication group.

## Example 5: Directory Server/Service (myoudds2b) added to existing Directory Server/Service (myoudds2) [instanceType=AddDS2RS]

In this example you will create a single container, which will host a single OUD 12c Directory/Replication Server/Service.  This server will form part of a new replication group which includes the Directory Server created in Example 1 (myoudds2).

Environment variables will be passed as default values, additional variables in [samples/oud-add-ds_rs.env](samples/oud-add-ds_rs.env) and variables passed with the `docker run` command.

[samples/oud-add-ds_rs.env](samples/oud-add-ds_rs.env):<br>
   **instanceType**=*AddDS2RS*<br>
   **OUD_INSTANCE_NAME**=myoudds2b<br>
   **hostname**=myoudds2b<br>
   **baseDN**=dc=example2,dc=com<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123<br>
   **adminUID**=admin<br>
   **adminPassword**=Oracle123<br>
   **bindDN1**=cn=Directory Manager<br>
   **bindPassword1**=Oracle123<br>
   **bindDN2**=cn=Directory Manager<br>
   **bindPassword2**=Oracle123<br>
   **sourceHost**=myoudds2<br>
   **dsreplication_1**=verify --hostname ${sourceHost} --port ${adminConnectorPort} --baseDN ${baseDN} --serverToRemove ${hostname}:${adminConnectorPort}<br>
   **dsreplication_2**=enable --host1 ${sourceHost} --port1 ${adminConnectorPort} --replicationPort1 ${replicationPort} --host2 ${hostname} --port2 ${adminConnectorPort} --replicationPort2 ${replicationPort} --baseDN ${baseDN}<br>
   **dsreplication_3**=initialize --hostSource ${initializeFromHost} --portSource ${adminConnectorPort} --hostDestination ${hostname} --portDestination ${adminConnectorPort} --baseDN ${baseDN}<br>
   **dsreplication_4**=verify --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN}<br>
   **dsreplication_5**=status --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN} --dataToDisplay compat-view <br>
   **post_dsreplication_dsconfig_1**=set-replication-domain-prop --domain-name ${baseDN} --set group-id:2<br>
   **post_dsreplication_dsconfig_2**=set-replication-server-prop --set group-id:2<br>
   
   Save [samples/oud-add-ds_rs.env](samples/oud-add-add-ds_rs.env) as ~/oud-add-ds_rs.env.

    docker run -d --network=InfraNET \
    --name=myoudds2b \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env OUD_INSTANCE_NAME=myoudds2b \
    --env hostname=myoudds2b \
    --env-file ~/oud-add-ds_rs.env \
    oracle/oud:12.2.1.4.0
    
To verify the replication server, run the following command:

    docker exec -it myoudds2 \
    /u01/oracle/user_projects/myoudds2/OUD/bin/dsreplication status \
    --trustAll \
    --hostname myoudds2 \
    --port 1444 \
    --adminUID admin \
    --dataToDisplay compat-view \
    --dataToDisplay rs-connections

Enter the admin password when prompted:

    >>>> Specify Oracle Unified Directory LDAP connection parameters/u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
    Password for user 'admin': Oracle123
    
Output should be similar to the following - the new directory server is displayed:

    Establishing connections and reading configuration ..... Done.
    dc=example2,dc=com - Replication Enabled
    ========================================
    Server          : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
    ---------------:----------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------
    myoudds2:1444   : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudds2:1898 (GID=1)
    myoudds2b:1444  : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 2            : myoudds2b:1898 (GID=2)
    Replication Server [11] : RS #1 : RS #2
    ------------------------:-------:------
    myoudds2:1898 (#1)      : --    : Yes
    myoudds2b:1898 (#2)     : Yes   : --

You can see that tmyoudds2 and the newly created myoudds2b have been added to the replication group, and are both acting as replication and directory servers.

## Example 6: Directory Client to run CLIs like ldapsearch, dsconfig, dsreplication, etc.

### Run `ldapsearch` CLI through a container from OUD Docker Image. `ldapsearch` can be executed to retrieve details from Directory and Proxy instances created in Example 1 and 2.

    docker run -it --rm --network=InfraNET \
    --name=myoudclient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/ldapsearch \
    -h myoudp -p 1389 \
    -D "cn=Directory Manager"  \
    -w "Oracle123" \
    -b "" -s base "(objectClass=*)" dn + | grep naming
> Based on --rm, container will be deleted after execution of ldapsearch in container. 

Returns:

    ds-private-naming-contexts: cn=schema
    namingContexts: dc=example1,dc=com
    namingContexts: dc=example2,dc=com

### Run `dsconfig` CLI through a container from OUD Docker Image. 

    docker run -it --rm --network=InfraNET \
    --name=myoudclient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/dsconfig \
    -h myoudp -p 1444 --portProtocol LDAP \
    -D "cn=Directory Manager" \
    -X --advanced --displayCommand
> Based on --rm, container will be deleted after execution of ldapsearch in container. 


### Run `dsreplication` CLI through a container from OUD Docker Image. Replication status can be checked for instance created in Example 4 and 5.

    docker run -it --rm --network=InfraNET \
    --name=myoudclient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/dsreplication status \
    -h myoudds1b -p 1444 --portProtocol LDAP \
    -D "cn=Directory Manager" \
    --trustAll
> Based on --rm, container will be deleted after execution of ldapsearch in container. 


    docker run -it --rm --network=InfraNET \
    --name=myoudclient \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    oracle/oud:12.2.1.4.0 \
    /u01/oracle/oud/bin/dsreplication status \
    -h myoudds2b -p 1444 --portProtocol LDAP \
    -D "cn=Directory Manager" \
    --trustAll
> Based on --rm, container will be deleted after execution of ldapsearch in container. 

## Example 7: Directory Server/Service [instanceType=Directory] with dstune configuration options

In the examples below you will create two containers, which will each host a single OUD 12c Directory Server/Service.  In this case you pass in dstune parameters.

Environment variables will be passed as default values, additional variables in [samples/oud-dir-dstune.env](samples/oud-dir-dstune.env) and variables passed with the `docker run` command.

[samples/oud-dir-dstune.env](samples/oud-dir-dstune.env):<br>
   **instanceType**=*Directory*<br>
   **OUD_INSTANCE_NAME**=myouddstune<br>
   **hostname**=myouddstune<br>
   **baseDN**=dc=example1,dc=com<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123<br>
   **dstune_1**=mem-based --memory 2.5g --targetTool server<br>
   **dstune_2**=data-based --entryNumber 10000 --entrySize 512
   
   Save [samples/oud-dir-dstune.env](samples/oud-dir-dstune.env) as ~/oud-dir-dstune.env.
   
    docker run -d --network=InfraNET \
    --name=myouddstune \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env-file ~/oud-dir-dstune.env \
    oracle/oud:12.2.1.4.0
    
**NOTE**: Multiple dstune options/settings can be passed as dstune_1=value1 dstune_2=value2 and so on, as provided in the above sample file.

Environment variables will be passed as default values, additional variables in [samples/oud-dir-dstune-autotune.env](samples/oud-dir-dstune-autotune.env) and variables passed with the `docker run` command.

[samples/oud-dir-dstune-autotune.env](samples/oud-dir-dstune-autotune.env):<br>
   **instanceType**=*Directory*<br>
   **OUD_INSTANCE_NAME**=myouddstune1<br>
   **hostname**=myouddstune1<br>
   **baseDN**=dc=example1,dc=com<br>
   **rootUserDN**=cn=Directory Manager<br>
   **rootUserPassword**=Oracle123<br>
   **dstune_1**=set-runtime-options --value autotune —-targetTool server
   
   Save [samples/oud-dir-dstune-autotune.env](samples/oud-dir-dstune-autotune.env) as ~/oud-dir-dstune-autotune.env.
   
    docker run -d --network=InfraNET \
    --name=myouddstune1 \
    --volume /scratch/test/oud_user_projects:/u01/oracle/user_projects \
    --env-file ~/oud-dir-dstune-autotune.env \
    oracle/oud:12.2.1.4.0
    
**NOTE**: Multiple dstune options/settings can be passed as dstune_1=value1 dstune_2=value2 and so on, as provided in the above sample file.
    
## Access interfaces (LDAP / LDAPS / HTTP / HTTPS) exposed by OUD container

You can use the docker inspect command to return various configuration parameters from your container.

To return the full list of parameters run the following command:

    docker inspect <container-name>
    
For example:

    docker inspect myoudds1
    
From the list returned you can select specific parameters to interrogate using the following syntax:

    docker inspect --format '{{<paramname>}}' <container-name>
    
For example, to return the IP address for your containers:

    docker inspect --format '{{.NetworkSettings.Networks.InfraNET.IPAddress}}' myoudds1 myoudds2 myoudds1b myoudds2b

Returns:

    172.19.0.2
    172.19.0.3
    172.19.0.6
    172.19.0.7

You can return multiple values:

    docker inspect --format '{{.Name}} : {{.NetworkSettings.Networks.InfraNET.IPAddress}}' myoudds1 myoudds2 myoudds1b myoudds2b

    /myoudds1 : 172.19.0.2
    /myoudds2 : 172.19.0.3
    /myoudds1b : 172.19.0.6
    /myoudds2b : 172.19.0.72


When container ports are mapped to the host port (through -p parameter for `docker run`), you can access those ports using the `hostname` as well.

Using `ldapsearch` CLI, access to ldapPort and ldapsPort can be validated.

Using `dsconfig` CLI, access to adminConnectorPort and httpAdminConnectorPort can be validated.

Using REST Client, access to httpPort and httpsPort can be validated.

# Licensing & Copyright

## License<br>
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.<br><br>

All scripts and files hosted in this project and GitHub [docker-images/OracleUnifiedDirectory](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.<br><br>

## Copyright<br>
Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.<br>
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl<br><br>

