Tuxedo Application Rehosting Workbench and Test manager on Docker
===============
# Introduction
This folder contains the information of how to use [Tuxedo ART Workbench and Test Manager](http://docs.oracle.com/cd/E72452_01/artwb/docs1222/index.html, http://docs.oracle.com/cd/E72452_01/arttm/docs1222/index.html) with [Docker](https://www.docker.com/).

## Contents
This folder contains dockerfile based on the Oracle Tuxedo image, in which it has installation of Eclipse, Tuxedo Application Rehosting Workbench and Test manager.

##Prerequisite
1. Use btrfs with docker:
   With big image size, it is better to use btrfs with docker, please follow the link below to set Docker using btrfs.
   https://docs.docker.com/engine/userguide/storagedriver/btrfs-driver/#configure-btrfs-on-sles


How to build and run
Pre-installation:
1. Download the binaries and copy them to `pwd`/bin
   1. Download all the files from this GitHub repository
   2. Download the binary of ART Workbench and Test Manager
   3. Download Eclipse
   4. Optionally download Tuxedo, Tuxedo ART Workbench and Tuxedo ART Test Manager patches

## To use
Before you run buildDockerImage.sh, if proxy is needed to access network, you need to set environment variables at first: http_proxy, https_proxy, ftp_proxy, no_proxy
     $ ./buildDockerImage.sh -v 12.2.2
Or 
     $ docker build -t oracle/tuxedoartwkbtm:12.2.2 .
Note, before you run buildDockerImage.sh, if your Tuxedo ART was other than 12.2.2, you need change above command according to version.

You should end up with a docker image tagged oracle/tuxedoartwkbtm:<version>, version is Tuxedo ART version number you may modify in buildDockerImage.sh.

## To run
You can then start the image in a new container with: ``docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoartwkbtm:12.2.2``.
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir in host machine, permission of this dir should be set like this:
    $ docker run -ti --rm --entrypoint="/bin/bash" oracle/tuxedoartwkbtm -c "whoami && id" tuxedoartwkbtm
      oracle
      uid=1000(oracle) gid=1000(oracle) groups=1000(oracle)
    $ sudo chown -R 1000 \${LOCAL_DIR}

