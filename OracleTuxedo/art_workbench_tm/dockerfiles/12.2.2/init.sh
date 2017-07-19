#!/bin/bash

cat <<EOF
This sample Docker image is provided by Oracle and is designed to be used as a base image from which you can build TuxedoARTRuntime-based applications.

For more information on this image, please visit the Oracle Docker Images GitHub repository at https://github.com/oracle/docker-images.

For more information on Tuxedo ART Runtime, please read the Oracle Tuxedo ART Runtime documentation at http://docs.oracle.com/cd/E72452_01/artrt/docs1222/index.html.
EOF

/u01/oracle/tuxHome/art_tm12.2.2.0.0/bin/startup.sh
