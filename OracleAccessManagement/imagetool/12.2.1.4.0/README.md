Building an OAM image with WebLogic Image Tool
=============================================

## Contents

1. [Introduction](#1-introduction-1)
2. [Prerequisites](#2-prerequisites)
3. [Download and setup the WebLogic Image Tool](#3-download-and-setup-the-weblogic-image-tool)
4. [Download the required packages/installers&Patches](#4-download-the-required-packagesinstallerspatches)
5. [Required build files](#5-required-build-files)
6. [Steps to create image](#6-steps-to-create-image)
7. [Sample Dockerfile generated with imagetool](#7-sample-dockerfile-generated-with-imagetool)

# 1. Introduction

This README describes the steps involved in building an OAM image with the WebLogic Image Tool.

# 2. Prerequisites

The following prerequisites are necessary before building OAM images with Image Tool:

* A working installation of Docker 18.03.1 or later
* Bash version 4.0 or later, to enable the <tab> command complete feature
* JAVA_HOME environment variable set to the location of your JDK e.g:  /scratch/export/oracle/product/jdk

# 3. Download and setup the WebLogic Image Tool

a) Download the latest WebLogic Image Tool version from the release [page](https://github.com/oracle/weblogic-image-tool/releases).

b) Unzip the release ZIP file to a desired \<work directory\> e.g /scratch.

```
$ unzip imagetool.zip -d <work directory>
Archive:  imagetool.zip
   creating: imagetool/
   creating: imagetool/bin/
  inflating: imagetool/bin/setup.sh
  inflating: imagetool/bin/logging.properties
  inflating: imagetool/bin/imagetool.cmd
  inflating: imagetool/bin/imagetool.sh
   creating: imagetool/lib/
  inflating: imagetool/lib/imagetool_completion.sh
  inflating: imagetool/lib/imagetool.jar
  inflating: imagetool/lib/fluent-hc-4.5.6.jar
  inflating: imagetool/lib/httpclient-4.5.6.jar
  inflating: imagetool/lib/httpcore-4.4.10.jar
  inflating: imagetool/lib/commons-logging-1.2.jar
  inflating: imagetool/lib/commons-codec-1.10.jar
  inflating: imagetool/lib/httpmime-4.5.6.jar
  inflating: imagetool/lib/picocli-4.1.4.jar
  inflating: imagetool/lib/json-20180813.jar
  inflating: imagetool/lib/compiler-0.9.6.jar
$
```
c) Run the following commands to setup imagetool:

```
$ cd <work directory>/imagetool/bin
$ source setup.sh
```

d) Execute the following to validate the WebLogic Image Tool:

```
$ ./imagetool.sh --version
imagetool:1.9.3
```

On pressing tab after typing `imagetool` on the command line, it will display the subcommands available in the imagetool:

```
$ ./imagetool.sh <TAB>
cache   create  help    rebase  update
```

e) The Image Tool creates a temporary Docker context directory, prefixed by wlsimgbuilder_temp, every time the tool runs. Under normal circumstances, this context directory will be deleted. However, if the process is aborted or the tool is unable to remove the directory, it is safe for you to delete it manually. By default, the Image Tool creates the Docker context directory under the user's home directory. If you prefer to use a different directory for the temporary context, set the environment variable `WLSIMG_BLDDIR`.

```
$ export WLSIMG_BLDDIR="/path/to/dir"
```

f) The Image Tool maintains a local file cache store. This store is used to look up where the Java, WebLogic Server installers, and WebLogic Server patches reside in the local file system. By default, the cache store is located in the user's $HOME/cache directory. Under this directory, the lookup information is stored in the .metadata file. All automatically downloaded patches also reside in this directory. You can change the default cache store location by setting the environment variable `WLSIMG_CACHEDIR`.

```
$ export WLSIMG_CACHEDIR="/path/to/cachedir"
```



# 4. Download the required packages/installers&Patches

a) Download the required installers from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice e.g: \<work directory\>/stage:

* Oracle Identity and Access Management 12.2.1.4.0
* Oracle Fusion Middleware 12c Infrastructure 12.2.1.4.0
* Oracle JDK 


**Note** : the required list of packages/installers & patches for specific bundled patchsets can be found in the latest manifest file. For example, the list below displays the packages/installers & patches from manifest.oam.july2020.properties:

```
[JDK]
jdk-8u261-linux-x64.tar.gz

[INFRA]
fmw_12.2.1.4.0_infrastructure.jar

[INFRA_PATCH]
p28186730_139424_Generic.zip:Opatch
p31537019_122140_Generic.zip:WLS
p31544353_122140_Linux-x86-64.zip:WLS
p31470730_122140_Generic.zip:COH
p31488215_122140_Generic.zip:JDEV


[OAM]
fmw_12.2.1.4.0_idm.jar

[OAM_PATCH]
p31556630_122140_Generic.zip:OAM
```

b) Download any patches listed in the manifest file from [My Oracle Support](https://support.oracle.com) and copy to \<work directory\>/stage.



# 5. Required build files


a) The OAM image requires additional files for creating the OAM domain and starting the WebLogic Servers. Download the required files from the FMW [repository](https://github.com/oracle/docker-images/). For example:


```  
$ cd <work directory>
$ git clone https://github.com/oracle/docker-images
```

This will create the required directories and files under \<work directory\>/docker-images.


b) Edit the `<work directory>/docker-images/OracleAccessManagement/imagetool/12.2.1.4.0/buildArgs` file and change `%DOCKER_REPO%`, `%JDK_VERSION%` & `%BUILDTAG%` appropriately.


For example:

```
create
--jdkVersion=8u261
--type oam
--version=12.2.1.4.0
--tag=oam-with-patch:12.2.1.4.0
--pull
--installerResponseFile /scratch/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4.0/install.file,/scratch/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/install/iam.response
--additionalBuildCommands /scratch/docker-images/OracleAccessManagement/imagetool/12.2.1.4.0/addtionalBuildCmds.txt
--additionalBuildFiles /scratch/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/container-scripts
```

# 6. Steps to create image

Navigate to the `imagetool/bin` directory and run the following commands. In the below examples substitute `<work directory>/stage` for the directory where the approriate files reside.

### i) Add JDK package to Imagetool cache

```bash
$ ./imagetool.sh cache addInstaller --type jdk --version 8u261 --path <work directory>/stage/jdk-8u261-linux-x64.tar.gz
```

### ii) Add installers to Imagetool cache

```bash
$ ./imagetool.sh cache addInstaller --type fmw --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_infrastructure.jar
$ ./imagetool.sh cache addInstaller --type OAM --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_idm.jar
```

### iii) Add Patches to Imagetool cache

```bash
$ ./imagetool.sh cache addEntry --key 28186730_13.9.4.2.4 --value <work directory>/stage/p28186730_139424_Generic.zip
$ ./imagetool.sh cache addEntry --key 31556630_12.2.1.4.0 --value <work directory>/stage/p31556630_122140_Generic.zip
$ ./imagetool.sh cache addEntry --key 31537019_12.2.1.4.0 --value <work directory>/stage/p31537019_122140_Generic.zip
$ ./imagetool.sh cache addEntry --key 31544353_12.2.1.4.0 --value <work directory>/stage/p31544353_122140_Linux-x86-64.zip
$ ./imagetool.sh cache addEntry --key 31470730_12.2.1.4.0 --value <work directory>/stage/p31470730_122140_Generic.zip
$ ./imagetool.sh cache addEntry --key 31488215_12.2.1.4.0 --value <work directory>/stage/p31488215_122140_Generic.zip
```

### iv) Add patches to the buildArgs file:

Edit the `buildArgs` file and add the patches:

```
--patches 31556630_12.2.1.4.0,31488215_12.2.1.4.0,31470730_12.2.1.4.0,31537019_12.2.1.4.0,31544353_12.2.1.4.0
--opatchBugNumber=28186730_13.9.4.2.4
```

A sample `buildAgs` file is now as follows:

```
create
--jdkVersion=8u261
--type oam
--version=12.2.1.4.0
--tag=oam-with-patch
--pull
--installerResponseFile /scratch/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4.0/install.file,/scratch/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/install/iam.response
--additionalBuildCommands /scratch/docker-images/OracleAccessManagement/imagetool/12.2.1.4.0/addtionalBuildCmds.txt
--additionalBuildFiles /scratch/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/container-scripts
--patches 31556630_12.2.1.4.0,31488215_12.2.1.4.0,31470730_12.2.1.4.0,31537019_12.2.1.4.0,31544353_12.2.1.4.0
--opatchBugNumber=28186730_13.9.4.2.4
```

### v) Create the OAM image

Execute the `imagetool create` command to create the OAM image.

For example:

```bash
$ cd <work directory>/imagetool/bin
$ ./imagetool.sh @<work directory>/docker-images/OracleAccessManagement/imagetool/12.2.1.4.0/buildArgs
```

###  vi) View the docker image

Run the `docker images` command to ensure the new OAM image is loaded into the repository:

```
$ docker images
REPOSITORY                                                    TAG                 IMAGE ID            CREATED             SIZE
oam-with-patch                                                12.2.1.4.0          d4cccfcd67c4        3 minutes ago      3.38GB
oraclelinux                                                   7-slim              153f8d73287e        2 weeks ago         131MB
```

# 7. Sample Dockerfile generated with imagetool

Below is a sample dockerfile created with the imagetool. This can be viewed by issuing the `imagetool` command with the `--dryRun` option:

```
./imagetool.sh @<work directory/build/buildArgs --dryRun
```

```
########## BEGIN DOCKERFILE ##########
#
# Copyright (c) 2019, 2020, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
FROM oraclelinux:7-slim as OS_UPDATE
LABEL com.oracle.weblogic.imagetool.buildid="ab22c89a-bc4c-4729-b2b0-c052d22eb7fe"
USER root

RUN yum -y --downloaddir=/tmp/imagetool install gzip tar unzip libaio \
 && yum -y --downloaddir=/tmp/imagetool clean all \
 && rm -rf /var/cache/yum/* \
 && rm -rf /tmp/imagetool

## Create user and group
RUN if [ -z "$(getent group oracle)" ]; then hash groupadd &> /dev/null && groupadd oracle || exit -1 ; fi \
 && if [ -z "$(getent passwd oracle)" ]; then hash useradd &> /dev/null && useradd -g oracle oracle || exit -1; fi \
 && mkdir /u01 \
 && chown oracle:oracle /u01

# Install Java
FROM OS_UPDATE as JDK_BUILD
LABEL com.oracle.weblogic.imagetool.buildid="ab22c89a-bc4c-4729-b2b0-c052d22eb7fe"

ENV JAVA_HOME=/u01/jdk

COPY --chown=oracle:oracle jdk-8u261-linux-x64.tar.gz /tmp/imagetool/

USER oracle


RUN tar xzf /tmp/imagetool/jdk-8u261-linux-x64.tar.gz -C /u01 \
 && mv /u01/jdk* /u01/jdk \
 && rm -rf /tmp/imagetool \
 && rm -f /u01/jdk/javafx-src.zip /u01/jdk/src.zip


# Install Middleware
FROM OS_UPDATE as WLS_BUILD
LABEL com.oracle.weblogic.imagetool.buildid="ab22c89a-bc4c-4729-b2b0-c052d22eb7fe"

ENV JAVA_HOME=/u01/jdk \
    ORACLE_HOME=/u01/oracle \
    OPATCH_NO_FUSER=true

RUN mkdir -p /u01/oracle \
 && mkdir -p /u01/oracle/oraInventory \
 && chown oracle:oracle /u01/oracle/oraInventory \
 && chown oracle:oracle /u01/oracle

COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

COPY --chown=oracle:oracle fmw_12.2.1.4.0_infrastructure.jar install.file /tmp/imagetool/
COPY --chown=oracle:oracle fmw_12.2.1.4.0_idm.jar iam.response /tmp/imagetool/
COPY --chown=oracle:oracle oraInst.loc /u01/oracle/

    COPY --chown=oracle:oracle p28186730_139424_Generic.zip /tmp/imagetool/opatch/

    COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/

USER oracle


RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/install.file -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_idm.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/iam.response -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation

RUN cd /tmp/imagetool/opatch \
 && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139424_Generic.zip \
 && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle

RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
 && test $? -eq 0 \
 && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle \
 || (cat /u01/oracle/cfgtoollogs/opatch/opatch*.log && exit 1)



FROM OS_UPDATE as FINAL_BUILD

ARG ADMIN_NAME
ARG ADMIN_HOST
ARG ADMIN_PORT
ARG MANAGED_SERVER_PORT

ENV ORACLE_HOME=/u01/oracle \
    JAVA_HOME=/u01/jdk \
    LC_ALL=${DEFAULT_LOCALE:-en_US.UTF-8} \
    PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle

LABEL com.oracle.weblogic.imagetool.buildid="ab22c89a-bc4c-4729-b2b0-c052d22eb7fe"

    COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

COPY --from=WLS_BUILD --chown=oracle:oracle /u01/oracle /u01/oracle/



USER oracle
WORKDIR /u01/oracle

#ENTRYPOINT /bin/bash


    ENV FMW_IDM_JAR=fmw_12.2.1.4.0_idm.jar \
        BASE_DIR=/u01 \
        ORACLE_HOME=/u01/oracle \
        SCRIPT_DIR=/u01/oracle/dockertools \
        PROPS_DIR=/u01/oracle/properties \
        USER_PROJECTS_DIR=/u01/oracle/user_projects \
        DOMAIN_ROOT=/u01/oracle/user_projects/domains \
        DOMAIN_NAME="${DOMAIN_NAME:-oam_domain}" \
        DOMAIN_HOME="${DOMAIN_ROOT}"/"${DOMAIN_NAME}" \
        ADMIN_USER="${ADMIN_USER:-}" \
        ADMIN_PASSWORD="${ADMIN_PASSWORD:-}" \
        CONNECTION_STRING="${CONNECTION_STRING:-OamDB:1521/orclpdb1.localdomain}" \
        CONTAINER_DIR=/u01/oracle/user_projects/container \
        ADMIN_LISTEN_HOST="${ADMIN_LISTEN_HOST:-}" \
        ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
        ADMIN_LISTEN_PORT="${ADMIN_LISTEN_PORT:-7001}" \
        DOMAIN_TYPE="${DOMAIN_TYPE:-oam}" \
        RCUPREFIX=${RCUPREFIX:-OAM01} \
        DB_USER=${DB_USER:-} \
        DB_PASSWORD=${DB_PASSWORD:-} \
        DB_SCHEMA_PASSWORD=${DB_SCHEMA_PASSWORD:-} \
        USER_MEM_ARGS=${USER_MEM_ARGS:-"-Djava.security.egd=file:/dev/./urandom"} \
        JAVA_OPTIONS="${JAVA_OPTIONS} -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" \
        PATH=$PATH:/usr/java/default/bin:$ORACLE_HOME/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/dockertools

    USER root

    RUN mkdir -p ${USER_PROJECTS_DIR} && \
        chown -R oracle:oracle ${USER_PROJECTS_DIR} && chmod -R 775 ${USER_PROJECTS_DIR} && \
        mkdir -p ${CONTAINER_DIR} && \
        chown -R oracle:oracle ${CONTAINER_DIR} && chmod -R 775 ${CONTAINER_DIR} && \
        mkdir -p ${SCRIPT_DIR} && chown oracle:oracle ${SCRIPT_DIR} && \
        mkdir -p ${PROPS_DIR} && chown oracle:oracle ${PROPS_DIR} && \
        yum install -y hostname && \
        rm -rf /var/cache/yum


    COPY --chown=oracle:oracle files/container-scripts/ ${SCRIPT_DIR}/
    RUN chmod a+xr ${SCRIPT_DIR}/* && \
         chown -R oracle:oracle ${SCRIPT_DIR}

    USER oracle
    WORKDIR $ORACLE_HOME
    CMD ["sh", "-c", "${SCRIPT_DIR}/createDomainAndStart.sh"]


########## END DOCKERFILE ##########
```

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.