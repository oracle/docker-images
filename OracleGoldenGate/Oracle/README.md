Oracle GoldenGate for Oracle on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. 

For more information about Oracle GoldenGate 12c please see the Oracle GoldenGate Online Documentation at http://docs.oracle.com/goldengate/c1221/gg-winux/index.html.

For more information about Oracle Database 12c, please see the Oracle Database Online Documentaion at http://docs.oracle.com/en/database/index.html.

## How to build Oracle GoldenGate for Oracle on Docker
This project offers sample Dockerfile and other associated file for this build:
 * fbo_ggs_Linux_x64_shiphome.zip (Oracle GoldenGate 12c for Oracle (12.2.0.1))
 * runSQL.sql - SQL file to run required steps
 * Dockerfile - Build file for Docker image
 * entrypoint.sh - steps required to install Oracle Database 12c and Oracle GoldenGate 12c
 * db_install.rsp - file to install Oracle Database 12c silently

To rebuild the Oracle GoldenGate for Oracle Docker image, use the following command:

    docker build -t oggora:12.2.0.1.1 -f Dockerfile .
 
## Running Oracle GoldenGate for Oracle in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

    docker run -d --name oggora \
    -p 1521:1521 \
    -p 5500:5500 \
    -p 9500:9500 \
    oggora:12.2.0.1.1
    
    Parameters:
       --name:        The name of the container (default: auto generated)
       -p:            The port mapping of the host port to the container port. 
                      Three ports are exposed: 
                          - 1521 (Oracle Listener) 
                          - 5500 (OEM Express)
                          - 9500 (OGG Manager Port (non-default))

Once the container has been started and the database created you can connect to it just like to any other database:

    sqlplus sys/<your password>@//localhost:1521/<your SID> as sysdba
    sqlplus system/<your password>@//localhost:1521/<your SID>

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

    https://localhost:5500/em/

To access Oracle GoldenGate 12c, run the following from the command line:

    $OGG_HOME/ggsci

### Running SQL*Plus in a Docker container
You may use the same Docker image you used to start the database, to run `sqlplus` to connect to it, for example:

    docker exec -ti <container name> sqlplus system@<db instance>

## Known issues
* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

*PATH environment variable is not set correctly after being built.  

## Support
Oracle Database in single instance configuration is supported for Oracle Linux 7 and Red Hat Enterprise Linux (RHEL) 7.
For more details please see My Oracle Support note: **Oracle Support for Database Running on Docker (Doc ID 2216342.1)**

## License
To download and run Oracle Database or Oracle GoldenGate, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleiGoldenGate/Oracle](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
