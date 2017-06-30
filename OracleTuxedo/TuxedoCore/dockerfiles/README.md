# Introduction
This folder contains the information and examples of how to use [Tuxedo](http://oracle.com/tuxedo) with [Docker](https://www.docker.com/).

## Contents
It is based on the WebLogic Server dockerization (is that even a word?) done by Bruno Borges.

## To use
1. Into an empty directory:
  1. Download the Tuxedo 12.1.3 Linux 64 bit installer from OTN
  2. Download OracleTuxedo.zip from this github directory
  3. Optionally download the latest Tuxedo rolling patch from My Oracle Support
2. Unzip OracleTuxedo.zip
3. Execute buildDockerImage.sh -v 12.1.3 -i tuxedo121300_64_Linux_01_x86.zip -m 7194e8711a257951211185b2280bedd6
   Note1, before you run buildDockerImage.sh, if your Tuxedo was other than 12.1.3, you need change above command according to version, installer name related MD5 value.
   Note2, before you run buildDockerImage.sh, if proxy is needed to access network, you need to set environment variables at first: http_proxy, https_proxy, ftp_proxy, no_proxy

You should end up with a docker image tagged oracle/tuxedo:version, version is Tuxedo version number you may modify in buildDockerImage.sh.
Have fun!



