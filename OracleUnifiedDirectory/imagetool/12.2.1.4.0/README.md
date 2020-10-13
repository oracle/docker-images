Building OUD image with WebLogic Image Tool
===========================================

## Contents

1. [Introduction](#1-introduction-1)
2. [Prerequisites](#2-prerequisites)
3. [Setup WebLogic Image Tool](#3-setup-weblogic-image-tool)
4. [Download the required packages/installers](#4-download-the-required-packagesinstallers)
5. [Add installers/packages to the cache](#5-add-installerspackages-to-the-cache)
6. [Additional build files](#6-additional-build-files)
7. [Additional build commands](#7-additional-build-commands)
8. [Create OUD image](#8-create-oud-image)
9. [Sample Dockerfile genered with imagetool](#9-sample-dockerfile-genered-with-imagetool)

# 1. Introduction
This README describes the steps involved in building OUD image with the WebLogic Image Tool.

# 2. Prerequisites

* Docker client and daemon on the build machine, with minimum Docker version 18.03.1.ce.
* Bash version 4.0 or later, to enable the <tab> command complete feature.
* Set JAVA_HOME environment variable to the appropriate JDK location.

# 3. Setup WebLogic Image Tool


* Download WebLogic Image Tool version 1.8.0 from the release [page](https://github.com/oracle/weblogic-image-tool/releases/download/release-1.8.0/imagetool.zip).
* Unzip the release ZIP file to a desired location.
* Run the following commands to setup imagetool

        $ cd your_unzipped_location/bin
        $ source setup.sh


# 4. Download the required packages/installers

Download the required installers from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. Below the list of packages/installers required for OUD image.

* JDK - jdk-8u241-linux-x64.tar.gz
* OUD - fmw_12.2.1.4.0_oud.jar

Also download the required patches to be applied on the OUD image.

# 5. Add installers/packages to the cache

Add the required installers, packages & patches to the imagetool cache. In the command, type, version and the location of the package/installer have to be provided.

For adding the JDK to cache using sample command mentioned below...

    $ imagetool cache addInstaller --type jdk --version 8u241 --path /scratch/software/jdk-8u241-linux-x64.tar.gz

For adding OUD installer to cache using sample command mentioned below...

    $ imagetool cache addInstaller --type oud --version 12.2.1.4.0 --path /scratch/software/fmw_12.2.1.4.0_oud.jar

Add the required patch zip files to the cache. The patchId is the patch number followed by the version of the product. Below sample usage,

    $ imagetool cache addEntry --key 30851280_12.2.1.4.0 --value /scratch/software/OUDPatches/p30851280_122140_Generic.zip

# 6. Additional build files

OUD image requires additional files that are needed for creating and starting OUD Instance inside container.
These files can be downloaded from the [github location](https://orahub.oraclecorp.com/paascicd/FMW-DockerImages/tree/master/OracleUnifiedDirectory/dockerfiles/12.2.1.4.0/container-scripts). 

The list of files required for OUD image are,
* checkOUDInstance.sh
* common_functions.sh
* createAndStartOUDInstance.sh
* generate-start-ds_debug.sh
* setEnvVars.sh
* startOUDInstance.sh

# 7. Additional build commands

OUD image requires additional build commands to set the required environment variables, install os packages and copy the additional build files to the image being built. 

Below a sample additional build commands input file,

    [before-jdk-install]
    # Before JDK install
    
    [after-jdk-install]
    # After JDK install
    
    [final-build-commands]
    # Final build commands

    ENV BASE_DIR=/u01 \
        ORACLE_HOME=/u01/oracle \
        SCRIPT_DIR=/u01/oracle/container-scripts \
        USER_PROJECTS_DIR=/u01/oracle/user_projects \
        OUD_INSTANCE_NAME=${OUD_INSTANCE_NAME:-asinst_1} \	
        PATH=$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts
    
    USER root
    
    RUN mkdir -p ${USER_PROJECTS_DIR} && \
        chown -R oracle:oracle ${USER_PROJECTS_DIR} && chmod -R 770 ${USER_PROJECTS_DIR} && \
        mkdir -p ${SCRIPT_DIR} && chown oracle:oracle ${SCRIPT_DIR} && \
        yum install -y libaio hostname vi && \
        rm -rf /var/cache/yum
    
    COPY --chown=oracle:oracle \
        files/checkOUDInstance.sh \
        files/common_functions.sh \
        files/createAndStartOUDInstance.sh \
        files/generate-start-ds_debug.sh \
        files/setEnvVars.sh \
        files/startOUDInstance.sh \
        ${SCRIPT_DIR}/
    RUN chmod a+xr ${SCRIPT_DIR}/* && \
        chown -R oracle:oracle ${SCRIPT_DIR}
    
    USER oracle
    # Disabling Enpoint Identification for selected CLIs to allow connecting to OUD Instance with any hostname \
    RUN echo "" >> ${ORACLE_HOME}/oud/config/java.properties && \
        echo "dsconfig.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
        echo "dsreplication.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
        echo "uninstall.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
        echo "status.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
        ${ORACLE_HOME}/oud/bin/dsjavaproperties
    # run container health check
    HEALTHCHECK --interval=1m --start-period=5m \
        CMD "${SCRIPT_DIR}/checkOUDInstance.sh" > /dev/null || exit 1
    
    # Create and Start OUD Instance
    # ENTRYPOINT ["sh", "-c", "${SCRIPT_DIR}/createAndStartOUDInstance.sh"]
    CMD ["sh", "-c", "${SCRIPT_DIR}/createAndStartOUDInstance.sh"]
    
# 8. Create OUD image

Now we can build the OUD image with the imagetool. 

The following parameters are provided as input to the create command,

* jdkVersion - JDK version to be used in the image.
* type - type of image to be built.
* version - version of the image.
* tag - tag name for the image.
* additionalBuildCommands - additional build commands provided as a text file.
* addtionalBuildFiles - path of additional build files as comma separated list.


Below a sample command used to build OUD image,

    $ imagetool create --jdkVersion=8u241 --type oud --version=12.2.1.4.0 \
        --tag=oud-with-patch:12.2.1.4.0 \
        --additionalBuildCommands <Path to Repo directory OracleUnifiedDirectory>/imagetool/12.2.1.4.0/additionalBuildCmds.txt \
        --additionalBuildFiles \
            <Path to Repo directory OracleUnifiedDirectory>/dockerfiles/12.2.1.4.0/container-scripts \
        --patches 30851280

# 9. Sample Dockerfile genered with imagetool
Below is the content of sample Dockerfile generated by imagetool in dryrun for OUD image,

	########## BEGIN DOCKERFILE ##########
	#
	# Copyright (c) 2019, 2020, Oracle and/or its affiliates.  All rights reserved.
	#
	# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
	#
	#
	FROM oraclelinux:7-slim as OS_UPDATE
	LABEL com.oracle.weblogic.imagetool.buildid="f3557b16-8e34-4bf0-be6a-baa06fd8c137"
	USER root
	
	RUN yum -y --downloaddir= install gzip tar unzip \
	 && yum -y --downloaddir= clean all \
	 && rm -rf /var/cache/yum/* \
	 && rm -rf
	
	## Create user and group
	RUN if [ -z "$(getent group oracle)" ]; then hash groupadd &> /dev/null && groupadd oracle || exit -1 ; fi \
	 && if [ -z "$(getent passwd oracle)" ]; then hash useradd &> /dev/null && useradd -g oracle oracle || exit -1; fi \
	 && mkdir /u01 \
	 && chown oracle:oracle /u01
	
	# Install Java
	FROM OS_UPDATE as JDK_BUILD
	LABEL com.oracle.weblogic.imagetool.buildid="f3557b16-8e34-4bf0-be6a-baa06fd8c137"
	
	ENV JAVA_HOME=/u01/jdk
	
	COPY --chown=oracle:oracle jdk-8u241-linux-x64.tar.gz /tmp/imagetool/
	
	USER oracle
	
	    # Instructions/Commands to be executed Before JDK install
	
	
	RUN tar xzf /tmp/imagetool/jdk-8u241-linux-x64.tar.gz -C /u01 \
	 && mv /u01/jdk* /u01/jdk \
	 && rm -rf /tmp/imagetool
	
	    # Instructions/Commands to be executed After JDK install
	
	
	# Install Middleware
	FROM OS_UPDATE as WLS_BUILD
	LABEL com.oracle.weblogic.imagetool.buildid="f3557b16-8e34-4bf0-be6a-baa06fd8c137"
	
	ENV JAVA_HOME=/u01/jdk \
	    ORACLE_HOME=/u01/oracle \
	    OPATCH_NO_FUSER=true
	
	RUN mkdir -p /u01/oracle \
	 && mkdir -p /u01/oracle/oraInventory \
	 && chown oracle:oracle /u01/oracle/oraInventory \
	 && chown oracle:oracle /u01/oracle
	
	COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/
	
	COPY --chown=oracle:oracle fmw_12.2.1.4.0_oud.jar oud.rsp /tmp/imagetool/
	COPY --chown=oracle:oracle oraInst.loc /u01/oracle/
	
	    COPY --chown=oracle:oracle p28186730_139421_Generic.zip /tmp/imagetool/opatch/
	
	    COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
	
	USER oracle
	
	
	RUN  \
	 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_oud.jar -silent ORACLE_HOME=/u01/oracle \
	    -responseFile /tmp/imagetool/oud.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
	
	RUN cd /tmp/imagetool/opatch \
	 && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139421_Generic.zip \
	 && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle
	
	RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
	 && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle
	
	
	
	FROM OS_UPDATE as FINAL_BUILD
	
	ARG ADMIN_NAME
	ARG ADMIN_HOST
	ARG ADMIN_PORT
	ARG MANAGED_SERVER_PORT
	
	ENV ORACLE_HOME=/u01/oracle \
	    JAVA_HOME=/u01/jdk \
	    LC_ALL=${DEFAULT_LOCALE:-en_US.UTF-8} \
	    PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle
	
	LABEL com.oracle.weblogic.imagetool.buildid="f3557b16-8e34-4bf0-be6a-baa06fd8c137"
	
	    COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/
	
	COPY --from=WLS_BUILD --chown=oracle:oracle /u01/oracle /u01/oracle/
	
	
	
	USER oracle
	WORKDIR /u01/oracle
	
	#ENTRYPOINT /bin/bash
	
	
	    ENV BASE_DIR=/u01 \
	        ORACLE_HOME=/u01/oracle \
	        SCRIPT_DIR=/u01/oracle/container-scripts \
	        USER_PROJECTS_DIR=/u01/oracle/user_projects \
	    	OUD_INSTANCE_NAME=${OUD_INSTANCE_NAME:-asinst_1} \
	        PATH=$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts
	
	    USER root
	
	    RUN mkdir -p ${USER_PROJECTS_DIR} && \
	        chown -R oracle:oracle ${USER_PROJECTS_DIR} && chmod -R 770 ${USER_PROJECTS_DIR} && \
	        mkdir -p ${SCRIPT_DIR} && chown oracle:oracle ${SCRIPT_DIR} && \
	        yum install -y libaio hostname vi && \
	        rm -rf /var/cache/yum
	
	    COPY --chown=oracle:oracle \
	        files/checkOUDInstance.sh \
	        files/common_functions.sh \
	        files/createAndStartOUDInstance.sh \
	        files/generate-start-ds_debug.sh \
	        files/setEnvVars.sh \
	        files/startOUDInstance.sh \
	        ${SCRIPT_DIR}/
	    RUN chmod a+xr ${SCRIPT_DIR}/* && \
	         chown -R oracle:oracle ${SCRIPT_DIR}
	
	    USER oracle
	    # Disabling Enpoint Identification for selected CLIs to allow connecting to OUD Instance with any hostname \
	    RUN echo "" >> ${ORACLE_HOME}/oud/config/java.properties && \
	        echo "dsconfig.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
	        echo "dsreplication.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
	        echo "uninstall.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
	        echo "status.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
	        ${ORACLE_HOME}/oud/bin/dsjavaproperties
	
	    # run container health check
	    HEALTHCHECK --interval=1m --start-period=5m \
	       CMD "${SCRIPT_DIR}/checkOUDInstance.sh" > /dev/null || exit 1
	
	    # Create and Start OUD Instance
	    # ENTRYPOINT ["sh", "-c", "${SCRIPT_DIR}/createAndStartOUDInstance.sh"]
	    CMD ["sh", "-c", "${SCRIPT_DIR}/createAndStartOUDInstance.sh"]
	
	########## END DOCKERFILE ##########
