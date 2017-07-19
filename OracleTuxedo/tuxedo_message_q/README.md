
##Dockerfile for Tuxedo Message Queue

Please note that the docker image is dependent on the image oracle/tuxedo:12.1.3. Please create the [Tuxedo docker image](../core) first. There are 2 installation type for Tuxedo Message Queue installer: 
1)Standalone installation - all Oracle Tuxedo Message Queue files, and minimal Tuxedo files.
2)Install on top of existing Oracle Tuxedo Installation (the default) - only Oracle Tuxedo Message Queue files.
In the dockerfiles/, it provides "Standalone installation", and in samples/, it provides the other one. 

## How to run
Before getting started, please download 
1. Tuxedo TMQ 12.1.3 Linux 64 bit GA installer from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
   - OTMQ: otmq121300_64_Linux_x86.zip

If you use "Install on top of existing Oracle Tuxedo Installation", you must download Tuxedo RP:
2. Tuxedo 12.1.3 Linux 64 bit RPXX, XX should be 11 or bigger, for example
   - RP97: p25885822_121300_Linux-x86-64.zip

Execute:
buildDockerImage.sh -v 12.1.3


You can then start the image in a new container with:  
docker run -d -v ${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotmq:12.1.3

    Note: ${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any existing dir.

