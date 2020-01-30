# Oracle WebCenter Sites on Docker

To create web content management solutions, developers need a lightweight environment. Docker images need minimum resources, thereby allowing developers to quickly create development environments.

This project offers scripts to build an Oracle WebCenter Sites image based on 12c R2 (12.2.1.3, 12.2.1.4). Use this Docker configuration to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle WebCenter Sites, see the [Oracle WebCenter Sites Online Documentation](https://docs.oracle.com/middleware/12213/wcs/index.html).

This project creates Oracle WebCenter Sites Docker image with a single node targeted for development and testing, and excludes components such as SatelliteServer, SiteCapture, and VisitorServices. This image is supported as per Oracle Support Note 2017945.1.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## Prerequisites
You must download the WebCenter Sites binary and put it in its correct location (see `.download` files inside `dockerfiles/<version>`).

Before you build, select the version and distribution for which you want to build an image, then download the required packages (see `.download` files) and place them in the folder of your distribution version of choice. Then, from the `dockerfiles` folder, run the `buildDockerImage.sh` script.

		-bash-4.2$ sh buildDockerImage.sh -h
		
		Usage: buildDockerImage.sh -v [version] [-s] [-c]
		Builds a Docker Image for Oracle WebCenter Sites.
		
		Parameters:
				-v: version to build. Required.
						Choose one of: 12.2.1.3  12.2.1.4
				-c: enables Docker image layer cache during build
				-s: skips the MD5 check of packages
		
		Copyright (c) 2019, 2020 Oracle and/or its affiliates.
		
		Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## Building the WebCenter Sites Docker images

**IMPORTANT**
- Refer [Oracle WebCenter Sites 12.2.1.4.0](dockerfiles/12.2.1.4) for detail set up.
- Refer [Oracle WebCenter Sites 12.2.1.3.0](dockerfiles/12.2.1.3) for detail set up.

## License
To download and run the WebCenter Sites distribution, regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleWebCenterSites`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
