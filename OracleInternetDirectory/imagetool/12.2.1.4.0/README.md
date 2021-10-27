Building an Oracle Internet Directory image with WebLogic Image Tool
====================================================================

## Contents

1. [Introduction](#1-introduction)
2. [Prerequisites](#2-prerequisites)
3. [Setup WebLogic Image Tool](#3-setup-weblogic-image-tool)
4. [Download the required packages/installers](#4-download-the-required-packagesinstallers-patches)
5. [Required build files](#5-required-build-files)
6. [Additional build commands](#6-additional-build-commands)
7. [Steps to Create Oracle Internet Directory image](#7-steps-to-create-oracle-internet-directory-image)
8. [Generate Sample dockerfile with imagetool](#8-generate-sample-dockerfile-with-imagetool)

# 1. Introduction

This README describes the steps involved in building an Oracle Internet Directory image with the WebLogic Image Tool.

# 2. Prerequisites

The following prerequisites are necessary before building Oracle Internet Directory container images with WebLogic Image Tool:

* A working installation of Docker 18.03.1 or later
* Bash version 4.0 or later (commands should be run in a `bash` shell)
* `JAVA_HOME` environment variable set to the location of your JDK e.g:  `/scratch/export/oracle/product/jdk`

# 3. Setup WebLogic Image Tool

* Download the latest version of [WebLogic Image Tool](https://github.com/oracle/weblogic-image-tool/releases).
* Extract the release archive (zip, tar.gz) content into a desired \<work directory\>.

```
$ unzip imagetool.zip
Archive:  imagetool.zip
   creating: imagetool/
   creating: imagetool/lib/
  inflating: imagetool/lib/fluent-hc-4.5.12.jar
  inflating: imagetool/lib/httpclient-4.5.12.jar
  inflating: imagetool/lib/httpcore-4.4.13.jar
  inflating: imagetool/lib/commons-logging-1.2.jar
  inflating: imagetool/lib/commons-codec-1.11.jar
  inflating: imagetool/lib/httpmime-4.5.12.jar
  inflating: imagetool/lib/picocli-4.3.2.jar
  inflating: imagetool/lib/json-20200518.jar
  inflating: imagetool/lib/compiler-0.9.10.jar
   creating: imagetool/bin/
  inflating: imagetool/bin/setup.sh
  inflating: imagetool/bin/logging.properties
  inflating: imagetool/bin/imagetool.cmd
  inflating: imagetool/bin/imagetool.sh
  inflating: imagetool/LICENSE.txt
  inflating: imagetool/lib/imagetool_completion.sh
  inflating: imagetool/lib/imagetool.jar
  inflating: imagetool/VERSION.txt
$
```

* Run the following commands to setup imagetool

```
$ cd <work directory>/imagetool/bin
$ source setup.sh
```

* Execute the following to validate the WebLogic Image Tool:

```
$ imagetool --version
imagetool:1.9.16
$
```

The WebLogic Image Tool creates a temporary Docker context directory, prefixed by wlsimgbuilder_temp, every time the tool runs. Under normal circumstances, this context directory will be deleted. However, if the process is aborted or the tool is unable to remove the directory, it is safe for you to delete it manually. By default, the WebLogic Image Tool creates the Docker context directory under the user's home directory. If you prefer to use a different directory for the temporary context, set the environment variable `WLSIMG_BLDDIR`.

```
$ export WLSIMG_BLDDIR="/path/to/dir"
```

The WebLogic Image Tool maintains a local file cache store. This store is used to look up where the Java, WebLogic Server installers, and WebLogic Server patches reside in the local file system. By default, the cache store is located in the user's `$HOME/cache` directory. Under this directory, the lookup information is stored in the .metadata file. All automatically downloaded patches also reside in this directory. You can change the default cache store location by setting the environment variable `WLSIMG_CACHEDIR`.

```
$ export WLSIMG_CACHEDIR="/path/to/cachedir"
```

# 4. Download the required packages/installers & patches

Download the required installers from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice e.g: \<work directory\>/stage:

* Oracle Internet Directory 12.2.1.4.0
* Oracle JDK
* Oracle Fusion Middleware Infrastructure 12.2.1.4.0

**Note**: If the image is required to have patches included, download patches from [My Oracle Support](https://support.oracle.com) and copy to \<work directory\>/stage.

# 5. Required build files

The Oracle Internet Directory image requires additional files for creating and starting the Oracle Internet Directory instance in the container. Download the required files from the docker-images [repository](https://github.com/oracle/docker-images). For example:

```  
$ cd <work directory>
$ git clone https://github.com/oracle/docker-images
```

This will create the required directories and files under \<work directory\>/docker-images.

The files required for creation of the Oracle Internet Directory image can be located in the \<work directory\>/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/container-scripts directory:

# 6. Additional build commands

Oracle Internet Directory image requires additional build commands to set the required environment variables, install os packages and copy the additional build files to the image being built.

A sample additional build commands input file can be found at `<work directory>/docker-images/OracleInternetDirectory/imagetool/12.2.1.4.0/additionalBuildCmds.txt`.


# 7. Steps to Create Oracle Internet Directory image

Add the required installers, packages & patches to the imagetool cache by running the following commands. In the below examples substitute `<work directory>/stage` for the directory where the appropriate files reside.

### i) Add JDK package to Imagetool cache

```bash
$ imagetool cache addInstaller --type jdk --version 8u301 --path <work directory>/stage/jdk-8u301-linux-x64.tar.gz
```

For example:

```
$ imagetool cache addInstaller --type jdk --version 8u301 --path /scratch/stage/jdk-8u301-linux-x64.tar.gz
[INFO   ] Successfully added to cache. jdk_8u301=/scratch/stage/jdk-8u301-linux-x64.tar.gz
$
```

### ii) Add installers to Imagetool cache

```
$ imagetool cache addInstaller --type oid --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_oid_linux64.bin
$ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <work directory>/stage/fmw_12.2.1.4.0_infrastructure.jar
```

For example:

```
$ imagetool cache addInstaller --type oid --version 12.2.1.4.0 --path /scratch/stage/fmw_12.2.1.4.0_oid_linux64.bin
[INFO   ] Successfully added to cache. oid_12.2.1.4.0=/scratch/stage/fmw_12.2.1.4.0_oid_linux64.bin
imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path /scratch/stage/fmw_12.2.1.4.0_infrastructure.jar
[INFO   ] Successfully added to cache. fmw_12.2.1.4.0=/scratch/stage/fmw_12.2.1.4.0_infrastructure.jar
$
```

### iii) Add Patches to Imagetool cache
In case, patches are required to be included in image, downloaded patches should be added to Imagetool cache.

```bash
$ imagetool cache addEntry --key 28186730_13.9.4.2.2 --value <work directory>/stage/p28186730_139422_Generic.zip
$ imagetool cache addEntry --key 31400392_12.2.1.4.0 --value <work directory>/stage/p31400392_122140_Generic.zip
```

For example:

```
$ imagetool cache addEntry --key 28186730_13.9.4.2.2 --value /scratch/stage/p28186730_139422_Generic.zip
[INFO   ] Added entry 28186730_13.9.4.2.2=/scratch/stage/p28186730_139422_Generic.zip
$ imagetool cache addEntry --key 31400392_12.2.1.4.0 --value /scratch/stage/p31400392_122140_Generic.zip
[INFO   ] Added entry 31400392_12.2.1.4.0=/scratch/stage/p31400392_122140_Generic.zip
$
```

### iv) Create the Oracle Internet Directory image

Execute the `imagetool create` command to create the Oracle Internet Directory image.

The following parameters are provided as input to the create command,

* jdkVersion - JDK version to be used in the image.
* type - type of image to be built.
* version - version of the image.
* tag - tag name for the image.
* additionalBuildCommands - additional build commands provided as a text file.
* addtionalBuildFiles - path of additional build files as comma separated list.


Below is a sample command used to build an Oracle Internet Directory image.

```
$ imagetool create --jdkVersion=8u301 --type oid --version=12.2.1.4.0 \
    --tag=oracle/oid:12.2.1.4.0 \
    --chown=oracle:root \
    --additionalBuildCommands <work directory>/docker-images/OracleInternetDirectory/imagetool/12.2.1.4.0/additionalBuildCmds.txt \
    --additionalBuildFiles <work directory>/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/container-scripts \
    --patches <patch_a>,<patch_b>,...
```
> --patches option is required only when image is required to be generated with patches

For example:

```
$ imagetool create --jdkVersion=8u301 --type oid --version=12.2.1.4.0 \
--tag=oracle/oid:12.2.1.4.0 \
--chown=oracle:root \
--additionalBuildCommands /scratch/docker-images/OracleInternetDirectory/imagetool/12.2.1.4.0/additionalBuildCmds.txt \
--additionalBuildFiles /scratch/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/container-scripts \
--patches 28186730,31400392
```
> --patches option is required only when image is required to be generated with patches

### v) View the docker image

Run the `docker images` command to ensure the new Oracle Internet Directory image is loaded into the repository:

```
$ docker images
REPOSITORY                                                                   TAG                       IMAGE ID            CREATED             SIZE
oracle/oid                                                                   12.2.1.4.0                09294d0fd357        About an hour ago   5.09GB
...
```

# 8. Generate Sample dockerfile with imagetool

Edit the `buildArgs` file. Sample below:

create
--jdkVersion=8u281
--type oid
--version=12.2.1.4.0
--tag=oid_dry
--pull
--chown oracle:root
--installerResponseFile /scratch/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/install/oid.response
--additionalBuildCommands /scratch/docker-images/FMW-DockerImages/OracleInternetDirectory/imagetool/12.2.1.4.0/additionalBuildCmds.txt
--additionalBuildFiles /scratch/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/container-scripts

If you want to review a sample dockerfile created with the imagetool issue the `imagetool` command with the `--dryRun` option:


```
imagetool @<work directory>/docker-images/OracleInternetDirectory/imagetool/12.2.1.4.0/buildArgs --dryRun
```

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleInternetDirectory](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2021, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
