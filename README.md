# Introduction
This folder contains the information and examples of how to use [Tuxedo](http://oracle.com/tuxedo) with [Docker](https://www.docker.com/).

## Contents
It is based on the WebLogic Server dockerization (is that even a word?) done by Bruno Borges.

## To use
1. Into an empty directory:
  1. Download the Tuxedo 12.1.3 Linux 64 bit installer from OTN
  2. Download tuxedo_docker.zip from this github directory
  3. Optionally download the latest Tuxedo rolling patch from My Oracle Support
2. Unzip tuxedo_docker.zip
3. Execute build.sh

You should end up with a docker image tagged oracle/tuxedo

You can then start the image in a new container with:  `docker run -i -t oracle/tuxedo /bin/bash`
which will put you into the container with a bash prompt.  If you want to test the new container, simply execute the `simpapp_runme.sh` in an empty
directory and the script will build and run the Tuxedo simpapp application.

Have fun!



