

##Dockerfile for Tuxedo Message Queue

Please note that the docker image is dependent on the image oracle/tuxedo:12.1.3. Please create the [Tuxedo docker image](../TuxedoCore) first.

## How to run
Before getting started, please download the Tuxedo TMQ 12.1.3 Linux 64 bit GA installer from [Oracle OTN](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html)
- OTMQ: otmq121300_64_Linux_x86.zip

Execute:
buildDockerImage.sh -v 12.1.3 -i otmq121300_64_Linux_x86.zip -m 5c0e76295c3e6a6e719f36b3b65e5a94
or,
buildDockerImage.sh -v 12.1.3 -s -i otmq121300_64_Linux_x86.zip to skip the md5 verification


You can then start the image in a new container with:  
docker run -ti -v ${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotmq:12.1.3 /bin/bash

    Note: ${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any existing dir.

which will put you into the container with a bash prompt. 
  
