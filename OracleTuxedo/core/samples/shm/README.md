
Tuxedo SHM sample on Docker
===============

## Dependencies

This sample is based on one of [oracle/tuxedo:12.2.2](../../dockerfiles/12.2.2/Dockerfile) and [oracle/tuxedo:12.1.3](../../dockerfiles/12.1.3/Dockerfile) base image. So, before you proceed to build this image, make sure the image oracle/tuxedo:12.2.2 has been built locally or is accessible in a remote Docker registry.

## How to run
docker build -t oracle/tuxedoshm .
or
build.sh

You can then start the image in a new container with:  
docker run -ti -v ${Local_volumes_dir}/TuxedoVolumes/${VERSION}:/u01/oracle/user_projects oracle/tuxedoshm simpapp_runme.sh

which will put you into the container with a bash prompt.  If you want to test the new container, simply execute the `simpapp_runme.sh` in an empty directory and the script will build and run the Tuxedo simpapp application.

Note: 
  1. ${Local_volumes_dir} is a local dir which used in docker image as external storage, it can be any directory outside the docker container
  2. ${VERSION} could be either 12.2.2 or 12.1.3
