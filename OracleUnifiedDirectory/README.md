Oracle Unified Directory 
========================

## Contents

1. [Introduction](#introduction)
1. [Installing the Oracle Unified Directory image](#installing-the-oracle-unified-directory-image)
1. [Running the Oracle Unified Directory image in a container](#running-the-oracle-unified-directory-image-in-a-container)
1. [Oracle Unified Directory Docker container configuration](#oracle-unified-directory-docker-container-configuration)
1. [Oracle Unified Directory Kubernetes Configuration](#oracle-unified-directory-kubernetes-configuration)

## Introduction

Oracle Unified Directory provides comprehensive directory solution for robust identity management.

Oracle Unified Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Unified Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project offers dockerfile and scripts to build and configure an Oracle Unified Directory image based on 12cPS4 (12.2.1.4.0) release. Use this image to facilitate installation, configuration, and environment setup for DevOps users. 

This image refers to binaries for Oracle Unified Directory Release 12.2.1.4.0 and it has the capability to create different types of Oracle Unified Directory Instances (Directory Service, Proxy, Replication) on containers targeted for development and testing.

***Image***: `oracle/oud:12.2.1.4.0`

## Installing the Oracle Unified Directory image

An Oracle Unified Directory image can be created and/or made available for deployment in the following ways:

1. Build your own Oracle Unified Directory image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own Oracle Unified Directory 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. For more information, see [Building an Oracle Unified Directory image with WebLogic Image Tool](imagetool/12.2.1.4.0)
1. Build your own Oracle Unified Directory image using the dockerfile, scripts and base image from Oracle Container Registry (OCR). To customize the image for specific use-cases, Oracle provides dockerfile and build scripts. For more information, see [Building an Oracle Unified Directory Image with Dockerfile, Scripts and Base Image from OCR](dockerfiles/12.2.1.4.0/README-OCR-Base.md).
1. Build your own Oracle Unified Directory image using the dockerfile and scripts. To customize the image for specific use-cases, Oracle provides dockerfile and build scripts. For more information, see [Building an Oracle Unified Directory Image with Dockerfiles and Scripts](dockerfiles/12.2.1.4.0/README.md).

## Running the Oracle Unified Directory image in a container

The Oracle Unified Directory image supports running the following services in a container:

*  Directory Server/Service [instanceType=Directory]
*  Directory Proxy Server/Service [instanceType=Proxy]
*  Replication Server/Service [instanceType=Replication]
*  Directory Server/Service added to existing Directory or Replication Server/Service [instanceType=AddDS2RS]
*  Directory Client to run CLIs like ldapsearch, dsconfig, and dsreplication.

The functionality and features available from the Oracle Unified Directory image will depend on the environment variables passed when setting up/starting the container. Configuration of instances with support for Proxy and Replication require invocation of `dsconfig` and `dsreplication` commands following the execution of `oud-setup`. The Oracle Unified Directory 12c image is designed to support passing `dsconfig` and `dsreplication` parameters as required, to be used with commands after instance creation using `oud-setup` or `oud-proxy-setup`.  This provides flexibility in the types of Oracle Unified Directory service that can be configured to run in a container.

Commands and parameters to create and start a container running an Oracle Unified Directory instance, based on the Oracle Unified Directory image are shown below. The command to create and start a container is as follows:

```
$ docker run -d -P \
--network=OUDNet \
--name=<container name> \
--volume <Path for the directory on Host which is to be mounted in container for user_projects>:/u01/oracle/user_projects \
--env OUD_INSTANCE_NAME=<name for the instance> \
--env instanceType=<Type of OUD instance to create and start>
--env hostname=<hostname for the instance in container> \
--env-file <Path for the file containing environment variables> \
oracle/oud:12.2.1.4.0
```

The parameters used in the example above are described in the table below:

| **Parameter** | **Description** | **Default Value** |
| ------ | ------ | ------ |
| --name | Name for the container. When configuring multiple containers, this name is useful for referencing. | ------ |
| --volume | Location of Oracle Unified Directory configuration and data outside the container. Path for the directory on Host which is to be mounted in container for user_projects : `/u01/oracle/user_projects` | ------ |
| --network | Connect a container to a network.  This specifies the networking layer to which the container will connect.  | ------ |
| --env OUD_INSTANCE_NAME | Name for the Oracle Unified Directory instance.  This decides the directory location for the Oracle Unified Directory instance configuration files.  If the Oracle Unified Directory instance name is 'myoudasinst_1', the location for the Oracle Unified Directory instance would be /u01/oracle/user_projects/myoudasinst_1 When user_projects directory is shared and outside container, avoid having same name for multiple instances. | asinst_1 |
| --env instanceType | Type of Oracle Unified Directory instance to create and start.  Takes one of the following values: Directory, Proxy, Replication, AddDS2RS| Directory |
| --env hostname | Hostname to be used while invoking `oud-setup`, `oud-proxy-setup`, `dsconfig`, and `dsreplication` commands. | localhost |
| --env-file | Parameter file.  This can be used to list and store parameters and pass them to the container command, as an alternative to specifying the parameters on the command line. | ------ |

Additional parameters supported by the Oracle Unified Directory image are listed below.  These parameters are all passed to the container command using the --env or --env-file arguments:

| **Environment Variable** (To be passed through --env or --env-file) | **Description** | **Default Value** |
| ------ | ------ | ------ |
| ldapPort | Port on which the Oracle Unified Directory instance in the container should listen for LDAP communication. Use 'disabled' if you do not want to enable it. | 1389 |
| ldapsPort | Port on which the Oracle Unified Directory instance in the container should listen for LDAPS communication. Use 'disabled' if you do not want to enable it. | 1636 |
| rootUserDN | DN for the Oracle Unified Directory instance root user. | ------ |
| rootUserPassword | Password for the Oracle Unified Directory instance root user. | ------ |
| adminConnectorPort | Port on which the Oracle Unified Directory instance in the container should listen for administration communication over LDAPS. Use 'disabled' if you do not want to enable it. Note that at least one of the LDAP or the HTTP administration ports must be enabled. | 1444 |
| httpAdminConnectorPort | Port on which the Oracle Unified Directory Instance in the container should listen for Administration Communication over HTTPS Protocol. Use 'disabled' if you do not want to enable it. Note that at least one of the LDAP or the HTTP administration ports must be enabled. | 1888 |
| httpPort | Port on which the Oracle Unified Directory Instance in the container should listen for HTTP Communication. Use 'disabled' if you do not want to enable it. | 1080 |
| httpsPort | Port on which the Oracle Unified Directory Instance in the container should listen for HTTPS Communication. Use 'disabled' if you do not want to enable it. | 1081 |
| sampleData | Specifies the number of sample entries to populate the Oracle Unified Directory instance with on creation. If this parameter has a non-numeric value, the parameter addBaseEntry is added to the command instead of sampleData.  Similarly, when the ldifFile_n parameter is specified sampleData will not be considered and ldifFile entries will be populated.| 0 |
| adminUID | User ID of the Global Administrator to use to bind to the server. This parameter is primarily used with the dsreplication command. | ------ |
| adminPassword | Password for adminUID | ------ |
| bindDN1 | BindDN to be used while setting up replication using `dsreplication` to connect to First Directory/Replication Instance. | ------ |
| bindPassword1 | Password for bindDN1 | ------ |
| bindDN2 | BindDN to be used while setting up replication using `dsreplication` to connect to Second Directory/Replication Instance. | ------ |
| bindPassword2 | Password for bindDN2 | ------ |
| replicationPort | Port value to be used while setting up a replication server. This variable is used to substitute values in `dsreplication` parameters. | 1898 |
| sourceHost | Value for the hostname to be used while setting up a replication server. This variable is used to substitute values in `dsreplication` parameters. | ------ |
| initializeFromHost | Value for the hostname to be used while initializing data on a new Oracle Unified Directory instance replicated  from an existing instance. This variable is used to substitute values in `dsreplication` parameters. It is possible to have a different value for sourceHost and initializeFromHost while setting up replication with Replication Server, sourceHost can be used for the Replication Server and initializeFromHost can be used for an existing Directory instance from which data will be initialized.| $sourceHost |
| serverTuning | Values to be used to tune JVM settings. The default value is jvm-default.  If specific tuning parameters are required, they can be added using this variable.  | jvm-default |
| offlineToolsTuning | Values to be used to specify the tuning for offline tools. This variable if not specified will consider jvm-default as the default or specify the complete set of values with options if wanted to set to specific tuning | jvm-default|
| generateSelfSignedCertificate | Set to "true" if the requirement is to generate a self signed certificate when creating an Oracle Unified Directory instance using `oud-setup`. If no value is provided this value takes the default, "true". If using a certificate generated separately from oud-setup this value should be set to "false". | true |
| usePkcs11Keystore | Use a certificate in a PKCS#11 token that the replication gateway will use as servercertificate when accepting encrypted connections from the Oracle Directory Server Enterprise Edition server. Set to "true" if the requirement is to use the usePkcs11Keystore parameter when creating an Oracle Unified Directory instance using `oud-setup`. By default this parameter is not set. To use this option generateSelfSignedCertificate should be set to "false".| ------ |
| enableStartTLS | Enable StartTLS to allow secure communication with the directory server by using the LDAP port. By default this parameter is not set. To use this option generateSelfSignedCertificate should be set to "false". | ------ |
| useJCEKS | Specifies the path of a JCEKS that contains a certificate that the replication gateway will use as server certificate when accepting encrypted connections from the Oracle Directory Server Enterprise Edition server.  If required this should specify the keyStorePath, for example, `/u01/oracle/config/keystore`. | ------ |
| useJavaKeystore | Specify the path to the Java Keystore (JKS) that contains the server certificate. If required this should specify the path to the JKS, for example, `/u01/oracle/config/keystore`. By default this parameter is not set. To use this option generateSelfSignedCertificate should be set to "false". | ------ |
| usePkcs12keyStore | Specify the path to the PKCS#12 keystore that contains the server certificate. If required this should specify the path, for example, `/u01/oracle/config/keystore.p12`. By default this parameter is not set. | ------ |
| keyStorePasswordFile | Use the password in the specified file to access the certificate keystore. A password is required when you specify an existing certificate (JKS, JCEKS, PKCS#11, orPKCS#12) as a server certificate. If required this should specify the path of the password file, for example, `/u01/oracle/config/keystorepassword.txt`. By default this parameter is not set. | ------ |
| eusPasswordScheme | Set password storage scheme, if configuring Oracle Unified Directory for Enterprise User Security.  Set this to a value of either "sha1" or "sha2". By default this parameter is not set. | ------ |
| jmxPort | Port on which the Directory Server should listen for JMX communication.  Use 'disabled' if you do not want to enable it. | disabled |
| javaSecurityFile | Specify the path to the Java security file. If required this should specify the path, for example, `/u01/oracle/config/new_security_file`. By default this parameter is not set. | ------ |
| schemaConfigFile_n | 'n' in the variable name represents a numeric value between 1 and 50. This variable is used to set the full path of LDIF files that need to be passed to the Oracle Unified Directory instance for schema configuration/extension. If required this should specify the path, for example, `schemaConfigFile_1=/u01/oracle/config/00_test.ldif`. | ------ |
| ldifFile_n | 'n' in the variable name represents a numeric value between 1 and 50. This variable is used to set the full path of LDIF files that need to be passed to the Oracle Unified Directory instance for initial data population. If required this should specify the path, for example, `ldifFile_1=/u01/oracle/config/test1.ldif`. | ------ |
| dsconfigBatchFile_n | 'n' in the variable name represents a numeric value between 1 and 50. This variable is used to set the full path of LDIF files that need to be passed to the Oracle Unified Directory instance for batch processing by the `dsconfig` command. If required this should specify the path, for example, `dsconfigBatchFile_1=/u01/oracle/config/dsconfig_1.txt`.  When executing the `dsconfig` command the following values are added implicitly to the arguments contained in the batch file : ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} | ------ |
| dstune_n | 'n' in the variable name represents a numeric value between 1 and 50. Allows commands and options to be passed to the `dstune` utility as a full command. | ------ |
| dsconfig_n | 'n' in the variable name represents a numeric value between 1 and 300. Each file represents a set of execution parameters for the `dsconfig` command.  For each `dsconfig` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| dsreplication_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `dsreplication` command.  For each `dsreplication` execution, the following variables are added implicitly : ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost}, and ${baseDN}.  Depending on the dsreplication sub-command, the following variables are added implicitly : ${bindDN1}, ${bindPasswordFile1}, ${bindDN2}, ${bindPasswordFile2}, ${adminUID}, and ${adminPasswordFile}. | ------ |
| post_dsreplication_dsconfig_n | 'n' in the variable name represents a numeric value between 1 and 300. Each file represents a set of execution parameters for the `dsconfig` command to be run following execution of the `dsreplication` command. For each `dsconfig` execution, the following variables/values are added implicitly : --provider-name "Multimaster Synchronization", ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| rebuildIndex_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `rebuild-index` command. For each `rebuild-index` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}, and ${baseDN}. | ------ |
| manageSuffix_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `manage-suffix` command. For each `manage-suffix` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| importLdif_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `import-ldif` command. For each `import-ldif` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| execCmd_n | 'n' in the variable name represents a numeric value between 1 and 300. Each file represents a command to be executed in the container. For each command execution, the following variables are replaced, if present in the command : ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}. | ------ |

**Note** For the following parameters above the following statement applies:

* dsconfig_n
* dsreplication_n
* post_dsreplication_dsconfig_n
* rebuildIndex_n
* manageSuffix_n
* importLdif_n
* execCmd_n

If values are provided the following variables will be substituted with their values: ${hostname},${ldapPort},${ldapsPort},${adminConnectorPort},${replicationPort},${sourceHost},${initializeFromHost},${sourceAdminConnectorPort},${sourceReplicationPort},${baseDN},${rootUserDN},${adminUID},${rootPwdFile},${bindPasswordFile},${adminPwdFile},${bindPwdFile1},${bindPwdFile2}

## Oracle Unified Directory Docker container Configuration

To configure the Oracle Unified Directory containers on Docker only, see the tutorial [Creating Oracle Unified Directory Docker containers](https://docs.oracle.com/en/middleware/idm/unified-directory/12.2.1.4/tutorial-oud-docker/).

## Oracle Unified Directory Kubernetes Configuration

To configure the Oracle Unified Directory containers with Kubernetes see the [Oracle Unified Directory on Kubernetes](https://oracle.github.io/fmw-kubernetes/oud/) documentation.

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleUnifiedDirectory](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl


