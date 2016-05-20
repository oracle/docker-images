Oracle Database on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users.

## How to build and run
This project offers sample Dockerfiles for both Oracle Database 12c (12.1.0.2) Enterprise Edition and Standard Edition. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle Database Docker Install Images
**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install.

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root or with `sudo` privileges:

	[oracle@localhost docker]$ ./buildDockerImage.sh -h
	
	Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-i]
	Builds a Docker Image for Oracle Database.
	
	Parameters:
	   -v: version to build
	       Choose one of: 12.1.0.2
	   -e: creates image based on 'Enterprise Edition'
	   -s: creates image based on 'Standard Edition 2'
	   -x: creates image based on 'Express Edition'
	   -i: Ignores the MD5 checksums
	
	* select one edition only: -e, -s, or -x
	
	LICENSE CDDL 1.0 + GPL 2.0
	
	Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will be an newly installed Oracle Database. You must extend the image with your own Dockerfile and create the users and tablespaces that you may need.

## License
To download and run Oracle Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
