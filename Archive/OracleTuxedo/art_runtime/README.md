Tuxedo Application Runtime on Docker
===============
This folder contains the information of how to use [Tuxedo ART Runtime](http://docs.oracle.com/cd/E72452_01/artrt/docs1222/index.html) with [Docker](https://www.docker.com/). Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## Contents
This folder contains dockerfile based on the Oracle Tuxedo image, in which it has installation of Tuxedo Application Runtime installation, Cobol-IT, and Oracle instance client. 

##Prerequisite
1. Use btrfs with docker:
   With big image size, it is better to use btrfs with docker, please follow the link below to set Docker using btrfs.
   https://docs.docker.com/engine/userguide/storagedriver/btrfs-driver/#configure-btrfs-on-sles

How to build and run
Pre-installation:
1. Download the binaries and copy them to `pwd`/bin
   1. Download all the files from this GitHub repository
   2. Download the binary of ART Runtime
   3. Download Oracle instance client rpm from http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
      oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
      oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm
      oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm
      oracle-instantclient12.2-precomp-12.2.0.1.0-1.x86_64.rpm
   4. Download Cobol-IT installer
      For Cobol-IT license, after container started, copy the licnese file to /opt/cobol-it-64.
   5. Optionally download Tuxedo and Tuxedo ART Runtime patches

## To use
Before you run buildDockerImage.sh, if proxy is needed to access network, you need to set environment variables at first: http_proxy, https_proxy, ftp_proxy, no_proxy
     $ ./buildDockerImage.sh -v 12.2.2
Or 
     $ docker build -t oracle/tuxedoartrt:12.2.2 .
Note, before you run buildDockerImage.sh, if your Tuxedo ART was other than 12.2.2, you need change above command according to version.

You should end up with a docker image tagged oracle/tuxedoartrt:<version>, version is Tuxedo ART version number you may modify in buildDockerImage.sh.

## To run
You can then start the image in a new container with: ``docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoartrt:12.2.2``.
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir in host machine, permission of this dir should be set like this:
    $ docker run -ti --rm --entrypoint="/bin/bash" oracle/tuxedoartrt -c "whoami && id" tuxedoartrt
      oracle
      uid=1000(oracle) gid=1000(oracle) groups=1000(oracle)
    $ sudo chown -R 1000 \${LOCAL_DIR}


