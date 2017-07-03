

Tuxedo Jolt sample on Docker
===============

## How to run
1. Build Tuxedo 12.2.2 Docker image by following the [TuxedoCore](../TuxedoCore/dockerfiles) for 12.2.2.
2. Execute: `buildDockerImage.sh`

You can then start the image in a new container with:  
docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedojolt jolt_runme.sh

Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any directory outside the docker container.

which will put you into the container with a bash prompt. If you want to test Jolt in the container, execute the script `jolt_runme.sh` in an empty directory and the script will build and run the Tuxedo jolt sample application.
