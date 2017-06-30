

Tuxedo + TMA on Docker
===============

## How to run
Before run, download the Tuxedo rolling package, TMA SNA and TCP 12.2.2 Linux 64 bit installer from OTN
Execute:
buildDockerImage.sh -p <Tuxedo RP Name>

You can then start the image in a new container with:  
docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotma /bin/bash
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

which will put you into the container with a bash prompt. 
