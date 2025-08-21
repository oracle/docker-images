# Applying patch on Oracle HTTP Server
===============
This Dockerfile extends the Oracle HTTP Server image by applying a patch. This is a sample which shows how to patch an OHS image.
The name of patch file will need to be modified accordingly in the Dockerfile before using it for actual cases.

## How to Build and Run
First make sure you have built oracle/ohs:12.2.1.4.0.

Then download the patch and place it next to this README.

To build, run:

        "$ docker build  -t oracle/ohs:12214-patch ."

### Providing the Node Manager password
The user name and password must be supplied in a domain.properties file located in a HOST directory that you will map at container runtime with the -v option to the image directory /u01/oracle/bootdir. The properties file enables the scripts to configure the correct authentication for the Node Manager.

The format of the domain.properties file is key=value pair:
username=mynodemanagerusername
password=mynodemanagerpassword

### How to run container
To start the OHS container with the patched image, run the following command:

         "$ docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -it --name ohs -p 7777:7777 oracle/ohs:12214-patch"

### Stopping the  OHS instance
To stop the OHS instance, execute the following command:

         "$ docker stop <Container name>"

To look at the Container logs run:

         "$ docker logs --details <Container id>"

## Support
Oracle HTTP Server is supported in containers by Oracle.

## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a container, you must download the binary from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2025 Oracle and/or its affiliates. All rights reserved.
