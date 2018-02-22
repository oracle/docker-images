
Tuxedo + SALT + TSAM Plus agent on Docker
===============

## How to run
#Before running buildDockerImage.sh, you need to set the environment variables, http_proxy, https_proxy, ftp_proxy, and no_proxy, to access internet if the docker environment is behind a corporate proxy.

The base image oracle/tuxedo:12.2.2 should be built before you run buildDockerImage.sh.
   - For how to build the base image oracle/tuxedo:12.2.2, visit [Tuxedo on Docker](https://github.com/oracle/docker-images/tree/master/OracleTuxedo/core).
Before getting started, download the Tuxedo 12.2.2 Linux 64 bit installer tuxedo122200_64_Linux_01_x86.zip from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
Execute:
    $ ./buildDockerImage.sh
Or:
    $ docker build -t oracle/tuxedoall 12.2.2/

You can then start the image in a new container with:  
    $ docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoall
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir in host machine, permission of this dir should be set like this:
    $ docker run -ti --rm --entrypoint="/bin/bash" oracle/tuxedoall -c "whoami && id" tuxedoall
      oracle
      uid=1000(oracle) gid=1000(oracle) groups=1000(oracle)
    $ sudo chown -R 1000 \${LOCAL_DIR}
