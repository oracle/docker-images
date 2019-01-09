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


If you want to start the OHS container without specifying any configuration for mod_weblogic:
1. To start the OHS container with oracle/ohs:12.2.1.3.0 image, run the following command:

         docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -it --name ohs -p 7777:7777 oracle/ohs:12.2.1.3.0


If you want to start the OHS container with some pre-specified mod_weblogic configuration:
1. Depending on your weblogic environment , create a **custom_mod_wl_ohs.conf** file by referring to container-scripts/mod_wl_ohs.conf.sample and section 2.4 @ [OHS 12c Documentation](http://docs.oracle.com/middleware/12213/webtier/develop-plugin/oracle.htm#PLGWL553)

2. Place the custom_mod_wl_ohs.conf file in a directory in the host say,"/scratch/DockerVolume/OHSVolume" and then mount this directory into the container at the location "/config".
   By doing so, the contents of host directory /scratch/DockerVolume/OHSVolume(and hence custom_mod_wl_ohs.conf) will become available in the container at the mount point.  
   This mounting can be done by using the -v option with the 'docker run' command as shown below. The following command will start the OHS container with oracle/ohs:12.2.1.2.0-sa image and the host   directory "/scratch/DockerVolume/OHSVolume" will get mounted at the location "/config" in the container:

         $ docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -v /scratch/DockerVolume/OHSVolume:/config -w /config -d --name ohs -p 7777:7777  oracle/ohs:12.2.1.3.0

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
