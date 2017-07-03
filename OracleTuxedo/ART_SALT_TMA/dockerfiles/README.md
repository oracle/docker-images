# Introduction
This folder contains the information and examples of how to use [Tuxedo](http://oracle.com/tuxedo) with [Docker](https://www.docker.com/).

## Contents
It is based on the WebLogic Server dockerization (is that even a word?) done by Bruno Borges.

## To use
1. Into an empty directory:
  1. Download the Tuxedo TMA 12.2.2 Linux 64 bit installer from OTN
  2. Download TuxedoARTTMA.zip from this github directory
  3. Download the latest Tuxedo rolling patch from My Oracle Support, not less than RP003
2. Unzip TuxedoARTTMA.zip
3. Execute buildDockerImage.sh -p <RP Name>

You can then start the image in a new container with:

docker run --privileged -d -p 11122:22 -p 18080:8080 -e DISPLAY=bej301699.cn.oracle.com:1.0 -v /tmp/.X11-unix:/tmp/.X11-unix -h arthost --name tuxedoartrttma oracle/tuxedoartrttma:12.2.2 /sbin/init

docker exec -ti tuxedoartrttma /bin/bash

which will put you into the container with a bash prompt.
