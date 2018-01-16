
Tuxedo + SALT + TSAM Plus agent on Docker
===============

## How to run
#Before running buildDockerImage.sh, you need to set the environment variables, http_proxy, https_proxy, ftp_proxy, and no_proxy, to access internet if the docker environment is behind a corporate proxy.

The base image oracle/tuxedo:12.2.2 should be built before you run buildDockerImage.sh.
Before getting started, download the Tuxedo 12.2.2 Linux 64 bit installer from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
Execute:
buildDockerImage.sh

You can then start the image in a new container with:  
docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoall
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

