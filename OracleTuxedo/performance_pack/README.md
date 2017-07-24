Tuxedo Advanced Performance Pack on Docker
===============
With Tuxedo Performance Pack, Tuxedo applications can achieve significantly better application performance and improve application availability, especially when running with Oracle Database/RAC. Features in this pack can be run on all Oracle Tuxedo supported platforms since Tuxedo 12.1.3, except for Oracle Tuxedo 32-bit on Microsoft Windows platforms. See [OTN doc](http://docs.oracle.com/cd/E72452_01/tuxedo/docs1222/xpp/index.html) for more details.


## Contents
The Docker image contains all the Tuxedo binares required by the pack and provides a sample for how to configure the feature in Tuxedo configuration file. It's just a base image for the pack and show you how to configure the OPTIONS option to enable or disable the features in Tuxedo configuration file.

How to run
Before running buildDockerImage.sh, you need to set the environment variables, http_proxy, https_proxy, ftp_proxy, and no_proxy, to access internet if the docker environment is behind a corporate proxy.
Please note that the docker image is dependent on the image oracle/tuxedo:12.1.3 or oracle/tuxedo:12.2.2. Please create the [Tuxedo docker image](../core) first.

Once the message "If you see this message, perfpack ran OK" is printed out in docker logs, that means the sample works well and the configuration of the pack is correct. The log produced in runtime could be found in the folder perfpack.

Execute:
./buildDockerImage.sh

You can then start the image in a new container with:
docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoperfpack
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

which will run the sample. You can check the logs from `docker logs <container_id>`, container_id can be checked by `docker ps -a`, the ULOG files can be check at \${LOCAL_DIR}/perfpack.

