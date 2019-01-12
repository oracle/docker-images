Applying patch on Oracle HTTP Server 
===============
This Dockerfile extends the Oracle HTTP Server image by applying a patch. This is a sample which shows how to patch an OHS image.
The name of patch file will need to be modified accordingly in the Dockerfile before using it for actual cases.

## How to Build and Run

First make sure you have built oracle/ohs:12.2.1.3.0.

Then download the patch and place it next to this README.

To build, run:
      
   $ docker build  -t oracle/ohs:12213-patch .


### Providing the Node Manager password
The user name and password must be supplied in a domain.properties file located in a HOST directory that you will map at Docker runtime with the -v option to the image directory /u01/oracle/bootdir. The properties file enables the scripts to configure the correct authentication for the Node Manager.

The format of the domain.properties file is key=value pair:
username=mynodemanagerusername
password=mynodemanagerpassword

### How to run container


To start the OHS container with the patched image, run the following command:

         docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -it --name ohs -p 7777:7777 oracle/ohs:12213-patch


### Stopping the  OHS instance
To stop the OHS instance, execute the following command:

      docker stop ohs (Assuming the name of conatiner is 'ohs')


To look at the Docker Container logs run:

        $ docker logs --details <Container-id>


## Support
Oracle HTTP Server on Docker is supported by Oracle.


## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
