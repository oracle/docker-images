
Tuxedo SHM Advanced Performance Pack sample on Docker
===============

## How to run
Before running buildDockerImage.sh, you need to set the environment variables, http_proxy, https_proxy, ftp_proxy, and no_proxy, to access internet if the docker environment is behind a corporate proxy.
Please note that the docker image is dependent on the image oracle/tuxedo:12.2.2. Please create the [Tuxedo docker image](../core) first.

Execute:
./buildDockerImage.sh

You can then start the image in a new container with:  
docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoperfpack
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

which will run the sample. You can check the logs from `docker logs <container_id>`, container_id can be checked by `docker ps -a`, the ULOG files can be check at \${LOCAL_DIR}/perfpack.
