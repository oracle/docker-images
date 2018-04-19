
TuxedoSALT + TMA on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. This project includes Dockerfiles for Tuxedo TMA 12.2.2 based on Oracle Tuxedo SALT 12.2.2. For more information about Oracle Tuxedo Mainframe Adapter (TMA) please see the Oracle TMA Online Documentation.

This project offers Dockerfile for building:

    Oracle Tuxedo 12c Release 2 Rolling Patch (RP003)
    Oracle Tuxedo TMA SNA 12c Release 2 (12.2.2)
    Oracle Tuxedo TMA TCP 12c Release 2 (12.2.2)

Dependencies

This project depends on the Tuxedo SALT. So, before you proceed to build this image, make sure the image oracle/tuxedoall:latest has been built locally or is accessible in a remote Docker registry.

IMPORTANT: You will have to provide the required installation binaries and put them into the Dockerfile folder.

For this image following installation media / binaries are required:

    Oracle Tuxedo 12c Release 2 Rolling Patch (RP003): p24444780_122200_Linux-x86-64.zip
    Oracle Tuxedo Mainframe Adapter for SNA 12cR2 (12.2.2) GA Installer: tmasna122200_64_linux_x86_64.zip
    Oracle Tuxedo Mainframe Adapter for TCP 12cR2 (12.2.2) GA Installer: tmatcp122200_64_linux_x86_64.zip

The download links and md5sum of downloaded binaries could also be found in the .download files inside the Dockerfile folder. Note that the downloaded file names must NOT be changed, they should remain the same with the file names mentioned in the .download files.

Applying Tuxedo Rolling Patch to the Base Image

Before installing Oracle TMA, you have to apply Tuxedo Rolling Patch at first. Please refer to README under `samples/apply-patch` for more details.

Building Oracle TMA Docker Install Image
## To use
Once you have applied Tuxedo Rolling Patch and provided the installation binaries and put them into the correct folder, go into it and run:

docker build -t oracle/tuxedoalltma:12.2.2.1 .

## How to run
Oracle Tuxedo SALT+TMA Image

You can then start the image in a new container with: ``docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoalltma:12.2.2.1``.
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

 * Tuxedo TMA Distribution and Documentation
   - For more information on the Tuxedo TMA 12cR2 Distribution, visit [Tuxedo TMA 12.2.2 Installer](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html).

   - For more information on the Tuxedo TMA 12cR2 Documentation, visit [Tuxedo TMA 12.2.2](http://docs.oracle.com/cd/E72452_01/tuxedo/docs1222/interm/mainfrm.html).

## License
To download and run Tuxedo TMA 12cR2 regardless of inside or outside a Docker container, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
