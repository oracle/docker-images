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

Download the required installers from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice e.g: \<work directory\>/stage:

* Oracle Identity and Access Management 12.2.1.4.0
* Oracle Fusion Middleware 12c Infrastructure 12.2.1.4.0
* Oracle JDK 

**Note**: If the image is required to have patches included, download patches from [My Oracle Support](https://support.oracle.com) and copy to \<work directory\>/stage.

# 5. Required build files


a) The OAM image requires additional files for creating the OAM domain and starting the WebLogic Servers. Download the required files from the docker-images [repository](https://github.com/oracle/docker-images/). For example:


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

c) Edit the `<work_directory>/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4.0/install.file` and under the `GENERIC` section add the line `INSTALL_TYPE="Weblogic Server"`. For example:

```
[GENERIC]
INSTALL_TYPE="WebLogic Server"
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
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

### iii) In case, patches are required to be included in image, downloaded patches should be added to Imagetool cache.

```bash
$ ./imagetool.sh cache addEntry --key 28186730_13.9.4.2.4 --value <work directory>/stage/p28186730_139424_Generic.zip
$ ./imagetool.sh cache addEntry --key 31556630_12.2.1.4.0 --value <work directory>/stage/p31556630_122140_Generic.zip
$ ./imagetool.sh cache addEntry --key 31537019_12.2.1.4.0 --value <work directory>/stage/p31537019_122140_Generic.zip
$ ./imagetool.sh cache addEntry --key 31544353_12.2.1.4.0 --value <work directory>/stage/p31544353_122140_Linux-x86-64.zip
$ ./imagetool.sh cache addEntry --key 31470730_12.2.1.4.0 --value <work directory>/stage/p31470730_122140_Generic.zip
$ ./imagetool.sh cache addEntry --key 31488215_12.2.1.4.0 --value <work directory>/stage/p31488215_122140_Generic.zip
```

### iv) In case, patches are required to be included in image, add patches to the buildArgs file:

Edit the `buildArgs` file and add the patches if required:

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

If you want to review a sample dockerfile created with the imagetool issue the `imagetool` command with the `--dryRun` option

```
./imagetool.sh @<work directory/build/buildArgs --dryRun
```

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleAccessManagement](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020, 2021 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
