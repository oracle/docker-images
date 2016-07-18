
Tuxedo SHM sample on Docker
===============

## How to run
docker build -t oracle/tuxedoshm .

You can then start the image in a new container with:  `docker run -i -t oracle/tuxedoshm /bin/bash`
which will put you into the container with a bash prompt.  If you want to test the new container, simply execute the `simpapp_runme.sh` in an empty
directory and the script will build and run the Tuxedo simpapp application.
