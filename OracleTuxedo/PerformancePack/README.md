

Tuxedo SHM Advanced Performance Pack sample on Docker
===============

## How to run

#Before running buildDockerImage.sh, you need to set the environment variables, http_proxy, https_proxy, ftp_proxy, and no_proxy, to access internet if the docker environment is behind a corporate proxy.

Execute:
buildDockerImage.sh

You can then start the image in a new container with:  
docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoperfpack perfpack_runme.sh
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

which will put you into the container with a bash prompt.  If you want to test the new container, simply execute the `perfpack_runme.sh` in an empty directory and the script will build and run the Tuxedo perfpack application.
