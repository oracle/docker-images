# Introduction
This folder contains the information and examples of how to use [Tuxedo ART Runtime](http://docs.oracle.com/cd/E72452_01/artrt/docs1222/index.html) with [Docker](https://www.docker.com/).

## Contents
It is based on the Oracle Tuxedo image.

##Prerequisite
1. Use btrfs with docker:
   With big image size, it's better to use btrfs with docker, please follow the link below to set Docker using btrfs.
   https://docs.docker.com/engine/userguide/storagedriver/btrfs-driver/#configure-btrfs-on-sles


## To use
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
   
Installation:
Before you run buildDockerImage.sh, if proxy is needed to access network, you need to set environment variables at first: http_proxy, https_proxy, ftp_proxy, no_proxy
     ./buildDockerImage.sh -v 12.2.2   
Note, before you run buildDockerImage.sh, if your Tuxedo ART was other than 12.2.2, you need change above command according to version.

You should end up with a docker image tagged oracle/tuxedoartrt:<version>, version is Tuxedo ART version number you may modify in buildDockerImage.sh.



