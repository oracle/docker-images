Tuxedo on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes  [samples](samples/) for Tuxedo 12.1.3 based on Oracle Linux.

The certification of Tuxedo on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## Contents
This folder contains the information and examples of how to use [Tuxedo](http://oracle.com/tuxedo) with [Docker](https://www.docker.com/).

## To use
1. Into an empty directory:
  1. Download the Tuxedo 12.1.3 or 12.2.2 Linux 64bit installer from [OTN](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html)
  2. Download all the files from this github directory
  3. Optionally download the latest Tuxedo rolling patch from My Oracle Support
2. cd dockerfiles
3. Execute 'bash buildDockerImage.sh' to show the usage of the command. Follow [the guide](./dockerfiles/README.md) to create a docker image.

You should end up with a docker image tagged oracle/tuxedo:version, for instance, oracle/tuxedo:12.2.2.

You can then start the image in a new container with:  `docker run -i -t oracle/tuxedo:version /bin/bash`, for instance, `docker run -i -t oracle/tuxedo:12.2.2 /bin/bash`
which will put you into the container with a bash prompt.  If you want to test the new container, simply execute the `simpapp_runme.sh` in an empty
directory and the script will build and run the Tuxedo simpapp application.


 * Tuxedo Distribution and Documentation
   - For more information on the Tuxedo 12cR2 Distribution, visit [Tuxedo 12.1.3/12.2.2 Installer](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html).

   - For more information on the Tuxedo 12cR2 Documentation, visit [Tuxedo 12.1.3](http://docs.oracle.com/cd/E53645_01/tuxedo/index.html), [Tuxedo 12.2.2](http://docs.oracle.com/cd/E72452_01/tuxedo/index.html).


## License
To download and run Tuxedo 12cR2 regardless of inside or outside a Docker container, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker/OracleTuxedo](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2016-2016 Oracle and/or its affiliates. All rights reserved.

