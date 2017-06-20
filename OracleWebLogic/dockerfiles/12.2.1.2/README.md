Oracle WebLogic Server on Docker
=================================
These  Docker configurations have been used to create the Oracle WebLogic Server image. Providing this WLS image facilitates the configuration, and environment setup for DevOps users. This project includes the installation and the creation of an empty WebLogic Server domain (only an Admin Server). These Oracle WebLogic Server 12.2.1.2 images are based on Oracle Linux and Oracle JRE 8 (Server).

The certification of Oracle WebLogic Server on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For more information on the certification, please check the [Oracle WebLogic Server on Docker Certification Whitepaper](http://www.oracle.com/technetwork/middleware/weblogic/overview/weblogic-server-docker-containers-2491959.pdf) and [WebLogic Server Blog](https://blogs.oracle.com/WebLogicServer/) for updates.

## How to build and run
This project offers sample Dockerfiles for Oracle WebLogic Server 12cR2 (12.2.1.2), and it provides at least one Dockerfile for the 'developer' distribution, a second Dockerfile for the 'generic' distribution, and a third Dockerfile for the 'infrastructure' distribution. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.


### Building Oracle WebLogic Server Docker Install Images
**IMPORTANT:** you have to download the binary of Oracle WebLogic Server and put it in place (see `.download` files inside dockerfiles/<version>). The WebLogic image extends the Oracle JRE 8 image, you must either build the imageing Dockerfile in [../../../OracleJava/java8](https://github.com/oracle/docker-images/tree/master/OracleJava/java-8) or pull the latest image from the [Oracle Cointainer Registry](https://container-registry.oracle.com) or the [Docker Store](https://store.docker.com).

Before you build, choose which version and distribution you want to build an image,then download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version] [-d | -g | -i] [-s]
        Builds a Docker Image for Oracle WebLogic Server.
          
        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.2
           -d: creates image based on 'developer' distribution
           -g: creates image based on 'generic' distribution
           -i: creates image based on 'infrastructure' distribution
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages
        
        * select one distribution only: -d, -g, or -i
        
        LICENSE CDDL 1.0 + GPL 2.0
        
        Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** the resulting images will have an empty domain (only Admin Server) by default. You must extend the image with your own Dockerfile, and create your domain using WLST. You might take a look at the use case samples.

## Samples for Oracle WebLogic Server Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the WebLogic Server image, we provide a few samples for 12c versions for the Developer distribution. For an example we provide samples to create a **12.2.1.2 medrec** domain.

### Sample Installation and Base Domain for Oracle WebLogic Server 12.2.1.2
The image **oracle/weblogic:12.2.1.2-developer** will configure a **base_domain** with the following settings:

 * Admin Username: `weblogic`
 * Admin Password: `Auto generated` 
 * Oracle Linux Username: `oracle`
 * Oracle Linux Password: `welcome1`
 * WebLogic Server Domain Name: `base_domain`
 * Admin Server on port: `7001`
 * Production Mode: `developer`
  
**IMPORTANT:** If you intend to run these images in production you must change the Production Mode to production.
 

###Admin Password

On the first startup of the container a random password will be generated for the Administration of the domain. You can find this password in the output line:

`Oracle WebLogic Server auto generated Admin password:`

If you need to find the password at a later time, grep for "password" in the Docker logs generated during the startup of the container.  To look at the Docker Container logs run:

        $ docker logs --details <Container-id>

### Write your own Oracle WebLogic Server domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](https://docs.oracle.com/middleware/1221/cross/wlsttasks.htm). You can find an example of a WLST script to create domains at [create-wls-domain.py](dockerfiles/12.2.1.2/container-scripts/create-wls-domain.py). You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override an existing domain, or create a new one with WLST.

## Building the Oracle WebLogic Server Docker Image
To try a sample of a WebLogic Server image with a base domain configured, follow the steps below:

  1. Build the **12.2.1.2** image, go into  **dockerfiles** and call 

        $ sh buildDockerImage.sh -v 12.2.1.2-d

  2. Verify you now have this image in place with

        $ docker images

  3. Start a container from the image created in step 1: 
     You can override the default values of the following parameters during runtime with the -e option:
      * ADMIN_NAME     (default: AdminServer) 
      * ADMIN_PORT     (default: 7001) 
      * ADMIN_USERNAME (default: weblogic)
      * ADMIN_PASSWORD (default: Auto Generated)
      * DOMAIN_NAME    (default: base_domain)
      * DOMAIN_HOME    (default: /u01/oracle/user_projects/domains/base_domain)

**NOTE** To set the DOMAIN_NAME, you must set both DOMAIN_NAME and DOMAIN_HOME.

        $ docker run -d -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=welcome1 -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain -e DOMAIN_NAME=abc_domain oracle/weblogic:12.2.1.2-developer

  4. Run the administration console

        $ docker inspect --format '{{.NewworkSettings.IPAddress}}' <container-name>
        This returns the IPAddress (example xxx.xx.x.x) of the container.  Got to your browser and enter http://xxx.xx.x.x:8001/console
        

## Choose your Oracle WebLogic Server Distribution
This project hosts two to three configurations (depending on Oracle WebLogic Server version) for building Docker images with WebLogic Server 12c.

 * Quick Install Developer Distribution

   - For more information on the Oracle WebLogic Server 12cR2 Quick Install Developer Distribution, visit [WLS Quick Install Distribution for Oracle WebLogic Server 12.2.1.2.0](http://download.oracle.com/otn/nt/middleware/12c/wls/12212/README.txt).

 * Generic Distribution

   - For more information on the Oracle WebLogic Server 12cR2 Generic Full Distribution, visit [WebLogic Server 12.2.1.2 Documentation](http://docs.oracle.com/middleware/12212/wls/index.html).

 * Fusion Middleware Infrastructure Distribution

   - For more information on the Oracle WebLogic Server 12cR2 Infrastructure Full Distribution, visit [WebLogic Server 12.2.1.2 Infrastructure Documentation](https://docs.oracle.com/middleware/12212/core/INFIN/).

## License
To download and run Oracle WebLogic Server 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleWebLogic](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
