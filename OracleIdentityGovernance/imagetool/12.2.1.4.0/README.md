Building an OIG image with WebLogic Image Tool
==============================================

## Contents

1. [Introduction](#1-introduction)
1. [Prerequisites](#2-prerequisites)
1. [Download and setup the WebLogic Image Tool](#3-download-and-setup-the-weblogic-image-tool)
1. [Download the required packages/installers&Patches](#4-download-the-required-packagesinstallerspatches)
1. [Required build files](#5-required-build-files)
1. [Steps to create image](#6-steps-to-create-image)
1. [Generate Sample dockerfile with imagetool](#7-generate-sample-dockerfile-with-imagetool)

# 1. Introduction

This README describes the steps involved in building an OIG image with the WebLogic Image Tool. 

# 2. Prerequisites

The following prerequisites are necessary before building OIG images with Image Tool:

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
* Oracle SOA Suite 12.2.1.4.0
* Oracle Service Bus 12.2.1.4.0
* Oracle JDK 

**Note**: If the image is required to have patches included, download patches from [My Oracle Support](https://support.oracle.com) and copy to \<work directory\>/stage.

# 5. Required build files

a) The OIG image requires additional files for creating the OIG domain and starting the WebLogic Servers. Download the required files from the FMW [repository](https://github.com/oracle/docker-images). For example:


```  
$ cd <work directory>
$ git clone https://github.com/oracle/docker-images
```

This will create the required directories and files under \<work directory\>/docker-images.


b) Edit the `<work directory>/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/buildArgs` file and change `%DOCKER_REPO%`, `%JDK_VERSION%` & `%BUILDTAG%` appropriately.

For example:

```
create
--jdkVersion=8u261
--type oig
--chown oracle:root
--version=12.2.1.4.0
--tag=oig-with-patch:12.2.1.4.0
--pull
--installerResponseFile /scratch/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4.0/install.file,/scratch/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/soasuite.response,/scratch/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/osb.response,/scratch/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/idmqs.response
--additionalBuildCommands /scratch/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt
--additionalBuildFiles /scratch/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts
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

```
$ imagetool cache addInstaller --type jdk --version 8u241 --path <work directory>/stage/jdk-8u241-linux-x64.tar.gz
```

### ii) Add installers to Imagetool cache
In the event that patches are required to be included in the image, downloaded patches should be added to Imagetool cache.

```
$ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_infrastructure.jar
$ imagetool cache addInstaller --type soa --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_soa.jar
$ imagetool cache addInstaller --type osb --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_osb.jar
$ imagetool cache addInstaller --type idm --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_idm.jar  
```
### iii) Add Patches to Imagetool cache

```
$ imagetool cache addEntry --key 28186730_13.9.4.2.2 --value <work directory>/stage/p28186730_139422_Generic.zip
$ imagetool cache addEntry --key 31537019_12.2.1.4.0 --value <work directory>/stage/p31537019_122140_Generic.zip
$ imagetool cache addEntry --key 31544353_12.2.1.4.0 --value <work directory>/stage/p31544353_122140_Linux-x86-64.zip
$ imagetool cache addEntry --key 31470730_12.2.1.4.0 --value <work directory>/stage/p31470730_122140_Generic.zip
$ imagetool cache addEntry --key 31488215_12.2.1.4.0 --value <work directory>/stage/p31488215_122140_Generic.zip
$ imagetool cache addEntry --key 31403376_12.2.1.4.0 --value <work directory>/stage/p31403376_122140_Generic.zip
$ imagetool cache addEntry --key 31396632_12.2.1.4.0 --value <work directory>/stage/p31396632_122140_Generic.zip
$ imagetool cache addEntry --key 31287540_12.2.1.4.0 --value <work directory>/stage/p31287540_122140_Generic.zip
$ imagetool cache addEntry --key 30779352_12.2.1.4.0 --value <work directory>/stage/p30779352_122140_Generic.zip
$ imagetool cache addEntry --key 30680769_12.2.1.4.0 --value <work directory>/stage/p30680769_122140_Generic.zip
$ imagetool cache addEntry --key 31537918_12.2.1.4.0 --value <work directory>/stage/p31537918_122140_Generic.zip
$ imagetool cache addEntry --key 31497461_12.2.1.4.20.06.24 --value <work directory>/stage/p31497461_12214200624_Generic.zip
```


### iv) Add patches to the buildArgs file:

Edit the `buildArgs` file and add the patches:

```
--patches 31537019_12.2.1.4.0,31544353_12.2.1.4.0,31470730_12.2.1.4.0,31488215_12.2.1.4.0,31403376_12.2.1.4.0,31396632_12.2.1.4.0,31287540_12.2.1.4.0,30779352_12.2.1.4.0,30680769_12.2.1.4.0,31537918_12.2.1.4.0,31497461_12.2.1.4.20.06.24
--opatchBugNumber=28186730_13.9.4.2.2
```

A sample `buildAgs` file is now as follows:

```
create
--jdkVersion=8u261
--type oig
--chown oracle:root
--version=12.2.1.4.0
--tag=oig-with-patch:12.2.1.4.0
--pull
--installerResponseFile /scratch/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4.0/install.file,/scratch/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/soasuite.response,/scratch/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/osb.response,/scratch/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/idmqs.response
--additionalBuildCommands /scratch/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt
--additionalBuildFiles /scratch/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts
--patches 31537019_12.2.1.4.0,31544353_12.2.1.4.0,31470730_12.2.1.4.0,31488215_12.2.1.4.0,31403376_12.2.1.4.0,31396632_12.2.1.4.0,31287540_12.2.1.4.0,30779352_12.2.1.4.0,30680769_12.2.1.4.0,31537918_12.2.1.4.0,31497461_12.2.1.4.20.06.24
--opatchBugNumber=28186730_13.9.4.2.2
```

### v) Create the OIG image

For example:

```
$ cd <work directory>/imagetool/bin
$ ./imagetool.sh @<work directory>/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/buildArgs
```

###  vi) View the image

Run the `docker images` command to ensure the new OIG image is loaded into the repository:

```
$ docker images
REPOSITORY                                                    TAG                 IMAGE ID            CREATED             SIZE
oig-with-patch                                                12.2.1.4.0          d4cccfcd67c4        3 minutes ago      5.01GB
oraclelinux                                                   7-slim              153f8d73287e        2 weeks ago         131MB
```

# 7. Generate Sample dockerfile with imagetool

If you want to review a sample dockerfile created with the imagetool issue the `imagetool` command with the `--dryRun` option:

```
./imagetool.sh @<work directory/build/buildArgs --dryRun
```

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleIdentityGovernance](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

