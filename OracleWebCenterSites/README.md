# Oracle WebCenter Sites on Docker

To create web content management solutions, developers need a lightweight environment. Docker images need minimum resources, thereby allowing developers to quickly create development environments.

This project offers scripts to build an Oracle WebCenter Sites image based on 12c R2 (12.2.1.4, 12.2.1.3). Use this Docker configuration to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle WebCenter Sites, see the [Oracle WebCenter Sites Online Documentation](https://docs.oracle.com/en/middleware/webcenter/sites/12.2.1.4/index.html).

This project creates Oracle WebCenter Sites Docker image with a single node targeted for development and testing, and excludes components such as SatelliteServer, SiteCapture, and VisitorServices. This image is supported as per Oracle Support Note 2017945.1.

## For Building the WebCenter Sites Docker images and Using

**IMPORTANT**
- Refer [Oracle WebCenter Sites 12.2.1.4.0](dockerfiles/12.2.1.4) for detail set up.
- Refer [Oracle WebCenter Sites 12.2.1.3.0](dockerfiles/12.2.1.3) for detail set up.

## License
To download and run the WebCenter Sites distribution, regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleWebCenterSites`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
