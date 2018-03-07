#!/bin/bash

cat <<EOF
This sample Docker image is provided by Oracle and is designed to be used as a base image from which you can build TuxedoARTRuntime-based applications.

For more information on this image, please visit the Oracle Docker Images GitHub repository at https://github.com/oracle/docker-images.

For more information on Tuxedo ART Runtime, please read the Oracle Tuxedo ART Workbench and Test Manager documentation at 
http://docs.oracle.com/cd/E72452_01/artwb/docs1222/index.html
http://docs.oracle.com/cd/E72452_01/arttm/docs1222/index.html

To expand this Dockerfile with Tuxedo ART Rehosting Workbench and Test Manager applications, you can upload the applications, source codes, configuration files, compiling scripts, and all the needed files, to \${LOCAL_DIR} which mounted to /u01/oracle/user_projects inside the container, then, add commands in Dockerfile to compile the source codes, compile the Tuxedo configuration file, boot the domain, and run the applications, and shutdown the domain in the end.
EOF

/u01/oracle/tuxHome/art_tm12.2.2.0.0/bin/startup.sh
