Tuxedo Advanced Performance Pack on Docker
===============
The Docker image contains the necessary Tuxedo binares required by the performance pack and provides a sample for how to configure the feature in Tuxedo configuration file. It's an image for the pack and show you how to configure the OPTIONS option to enable or disable the features in Tuxedo configuration file. Please go through [OTN doc](http://docs.oracle.com/cd/E72452_01/tuxedo/docs1222/xpp/index.html) for more details.

To extend your image based on this image, you need to write your own perfpack_runme.sh and update Tuxedo Configuration file to enable the feature of the pack you want to employ. The Tuxedo application binaries should be installed in the docker or oracle/tuxedoperfpack. It depdents on how you will implement the shell script, perfpack_runme.sh.

##How to run
Before running buildDockerImage.sh, you need to set the environment variables, http_proxy, https_proxy, ftp_proxy, and no_proxy, to access internet if the docker environment is behind a corporate proxy.

Please note that the docker image is dependent on the image oracle/tuxedo:12.1.3 or oracle/tuxedo:12.2.2. Please create the [Tuxedo docker image](../core) first.

Once the message "If you see this message, perfpack ran OK" is printed out in docker logs, that means the sample works well and the configuration of the pack is correct. The log produced in runtime could be found in the folder perfpack.

Execute:
./buildDockerImage.sh

You can then start the image in a new container with:
docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoperfpack
Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir.

which will run the sample. You can check the logs from `docker logs <container_id>`, container_id can be checked by `docker ps -a`, the ULOG files can be check at \${LOCAL_DIR}/perfpack.

## How to use the Dockerfile
To extend your Tuxedo applications against the image, you need to update perfpack_runme.sh to initialize your Tuxedo applications. There are two approaches:
1. If all files are source, including UBBCONFIG, BDMCONFIG and C code, you need to build them in perfpack_runme.sh in order to generate the binaries for runtime
2. If they're already in binary format, you just need to put the binaries under a directory outside docker image, then map the directory to /u01/oracle/user_projects, like what the script buildDockerImage.sh does. Update perfpack_runme.sh to just set PATH and run 'tmboot -y' to boot your Tuxedo app.


## License
To download and run Oracle TSAM Plus, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 1996-2017 Oracle and/or its affiliates. All rights reserved.

