
Tuxedo SHM sample on Docker
===============

## How to run
docker build -t oracle/tuxedoshm .
or
build.sh

You can then start the image in a new container with:  
docker run -ti -v ${Local_volumes_dir}/TuxedoVolumes/${VERSION}:/u01/oracle/user_projects oracle/tuxedoshm simpapp_runme.sh

which will put you into the container with a bash prompt.  If you want to test the new container, simply execute the `simpapp_runme.sh` in an empty directory and the script will build and run the Tuxedo simpapp application.
