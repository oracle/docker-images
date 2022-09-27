# Introduction
This folder contains the information on how to create a Tuxedo container image based and two examples for how to use [Tuxedo](http://oracle.com/tuxedo) with it.

## To use
1. Into an empty directory:
  1. Download the latest Tuxedo (say 12.1.3  or 22.1.0.0.0) Linux 64 bit installer from [OTN](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html)
  2. Download all the files from this GitHub repository to a local directory
  3. Drop the downloaded Tuxedo installer to the corresponding version directory
  4. Optionally download the latest Tuxedo rolling patch from My Oracle Support
2. Into the local directory
3. Execute ``./buildContainerImage.sh -v 12.1.3 -i tuxedo121300_64_Linux_01_x86.zip -s`` to create an image for Tuxedo 12.1.3.
     or 
   Execute ``./buildContainerImage.sh -v 22.1.0.0.0 -i tuxedo221000_64_Linux_01_x86.zip -s`` to create an image for Tuxedo 22.1.0.

Notes:
   1. Before you run buildContainerImage.sh, depending on your Tuxedo version, you need to change the above command and installer name. For instance, tuxedo122200_64_Linux_01_x86.zip as the installer name for version 12.2.2 or tuxedo221000_64_Linux_01_x86.zip as the installer name for version 22.1.0.0.0.
   2. Before you run buildContainerImage.sh, if proxy is needed to access network, you need to set environment variables at first: http_proxy, https_proxy, ftp_proxy, no_proxy
   3. The base image oracle/serverjre:8 should be built before you run buildContainerImage.sh. To build the base image, you must first download the Oracle Server JRE binary and drop in folder ../OracleJava/java-8 and build that image. For more information, visit the [OracleJava](https://github.com/oracle/docker-images/blob/master/OracleJava) folder's [README](https://github.com/oracle/docker-images/blob/master/OracleJava/README.md) file.

    $ cd ../OracleJava/java-8
    $ sh build.sh


You should end up with a Container image tagged oracle/tuxedo:<version>, version is Tuxedo version number you may modify in buildContainerImage.sh.
Have fun!



