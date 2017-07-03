# Introduction
This folder contains the information and examples of how to use [Tuxedo](http://oracle.com/tuxedo) with [Docker](https://www.docker.com/).

## Contents
It is based on the WebLogic Server dockerization (is that even a word?) done by Bruno Borges.

## To use
1. Into an empty directory:
  1. Download the Tuxedo TMA 12.2.2 Linux 64 bit installer from OTN
  2. Download OracleTuxedoTMA.zip from this github directory
  3. Download the latest Tuxedo rolling patch from My Oracle Support, not less than RP003
2. Unzip OracleTuxedoTMA.zip
3. Execute buildDockerImage.sh -p <RP Name>

You can then start the image in a new container with:
docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotma:12.2.2 /bin/bash
Note: ${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

which will put you into the container with a bash prompt.
