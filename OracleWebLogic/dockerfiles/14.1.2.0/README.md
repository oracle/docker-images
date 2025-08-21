# Oracle WebLogic Server on Docker

These Docker configurations have been used to create the Oracle WebLogic Server (WLS) image. Providing this WLS image facilitates the configuration and environment setup for DevOps users. This project includes the installation and creation of an empty WebLogic Server domain (an Administration Server only). These WLS 14.1.2.0 images are based on Oracle Linux and Oracle JDK 17 or Oracle JDK 21.

**IMPORTANT**: We provide Dockerfiles as samples to build WebLogic images but this is _NOT_ a recommended practice. We recommend obtaining patched WebLogic Server images; patched images have the latest security patches. For more information, see [Obtaining, Creating, and Updating Oracle Fusion Middleware Images with Patches] (<https://docs.oracle.com/en/middleware/fusion-middleware/14.1.2/opatc/obtaining-creating-and-updating-oracle-fusion-middleware-images-patches.html>).

The samples in this repository are for development purposes only. We recommend for production to use alternative methods, we suggest obtaining base WebLogic Server images from the [Oracle Container Registry](<https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/ocr-images/>).

Consider using the open source [WebLogic Image Tool](<https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/custom-images/>) to create custom images, and using the open source [WebLogic Kubernetes Operator](<https://oracle.github.io/weblogic-kubernetes-operator/>) to deploy and manage WebLogic domains.

The certification of Oracle WebLogic Server on Docker does not require the use of any file presented in this repository. The sample files in this repository are for development purposes, customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.


## How to build and run
This project offers sample Dockerfiles for Oracle WebLogic Server 14.1.2.0. It provides a Dockerfile for the distribution of WebLogic Server 14.1.2.0 with JDK 17, and a second Dockerfile for the distribution of WebLogic Server 14.1.2.0 with JDK 21.

To assist in building the images, you can use the [`buildDockerImage.sh`](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle WebLogic Server Docker install images
**IMPORTANT:** You must download the binary of Oracle WebLogic Server and put it in place (see `.download` files inside `dockerfiles/<version>`).  WebLogic Server 14.1.2.0 supports both Java SE 17 or 21.

If you want to run WebLogic Server on Oracle JDK 17, you must build the image by using the Dockerfile in [`../../../OracleJava/17`](<https://github.com/oracle/docker-images/tree/master/OracleJava/17>). If you want to run images of WebLogic based on the Oracle JDK 21 image, you must build the image by using the Dockerfile in [`../../../OracleJava/21`](<https://github.com/oracle/docker-images/tree/master/OracleJava/21>).

Before you build, select the version and distribution for which you want to build an image, then download the required packages (see `.download` files) and locate them in the folder of your distribution version of choice. Then, from the `dockerfiles` folder, run the `buildDockerImage.sh` script as root.

       `$ sh buildDockerImage.sh`
        Usage: buildDockerImage.sh -v [version] [-d | -g | -m ] [-j] [-s] [-c]
        Builds a Docker Image for Oracle WebLogic.

        Parameters:
            -v: version to build. Required.
            Choose one of: 12.2.1.4  14.1.1.0  14.1.2.0  
            -d: creates image based on 'developer' distribution
            -g: creates image based on 'generic' distribution
            -j: choose the JDK to create a 12.2.1.4 (JDK '8'), 14.1.1.0 (JDK '8' or '11'), or 14.1.2.0 (JDK '17' or '21') image
            -m: creates image based on 'slim' distribution
            -c: enables Docker image layer cache during build
            -s: skips the MD5 check of packages

        * select one distribution only: -d, -g, or -m

        LICENSE UPL 1.0

        Copyright (c) 2014, 2025, Oracle and/or its affiliates.


**IMPORTANT:** The resulting images will have a single server domain (Administration Server only), by default.


  1. To build the `14.1.2.0`image, from `dockerfiles`, call:

        `$ sh buildDockerImage.sh -v 14.1.2.0 -d -j 17`

  2. Verify that you now have this image in place with:

        `$ docker images`

     If the WebLogic image is built extending Oracle JDK 17, then the built image will be called oracle/weblogic:14.1.2.0-17
     If the WebLogic image is built extending Oracle JDK 21, then the built image will be called oracle/weblogic:14.1.2.0-21

### Running a single server domain from the image
The WebLogic Server install image (built above) allows you to run a container with a single WebLogic Server domain.  This makes it extremely simple to deploy applications and any resource the application might need.

#### Providing the Administration Server user name and password
The user name and password must be supplied in a `domain.properties` file located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Server Administration Server.

The format of the `domain.properties` file is key=value pair:

     username=myadminusername
     password=myadminpassword

**Note**: Oracle recommends that the `domain.properties` file be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

#### Start the container
Start a container from the image created in step 1.
You can override the default values of the following parameters during runtime with the `-e` option:

      * `ADMIN_NAME`                  (default: `AdminServer`)
      * `ADMIN_LISTEN_PORT`           (default: `7001`)
      * `DOMAIN_NAME`                 (default: `base_domain`)
      * 'PRODUCTION_MODE              (default: `dev`)
      * `ADMINISTRATION_PORT_ENABLED` (default: `false`)
      * `ADMINISTRATION_PORT`         (default: `9002`)

**NOTE**: For security, you want to set the domain mode to `production mode`. In WebLogic Server 14.1.2.0 a new `production mode` domain becomes by default a `secured production` mode domain. Secured production mode domains have more secure default configuration settings, for example the Administration port is enabled, all non-ssl listen ports are disabled, and all ssl ports are enabled.

In this image we create a Development Mode domain by default, you can create a Production Mode domain (with Secured Production Mode disabled) by setting in the `docker run` command `PRODUCTION_MODE` to `prod` and set `ADMINISTRATION_PORT_ENABLED` to true.
If you intend to run these images in production, then you should change the Production Mode to `production`. When you set the `DOMAIN_NAME`, the `DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME`. Please see the documentation [Administering Security for Oracle WebLogic Server](<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/14.1.2/secmg/using-secured-production-mode.html#GUID-9ED2EF38-F763-4999-80ED-27A3FBCB9D7D>).


Run a Development Mode domain:

      `$ docker run -d -p 7001:7001 -v `HOST PATH where the domain.properties file is`:/u01/oracle/properties -e DOMAIN_NAME=docker_domain -e ADMIN_NAME=docker-AdminServer oracle/weblogic:14.1.2.0-17`

Run a Production Mode domain with Secured Mode disabled:

      `$ docker run -d -p 7001:7001 -p 9002:9002  -v `HOST PATH where the domain.properties file is`:/u01/oracle/properties -e PRODUCTION_MODE=prod -e ADMINISTRATION_PORT_ENABLED=true -e DOMAIN_NAME=docker_domain -e ADMIN_NAME=docker-AdminServer oracle/weblogic:14.1.2.0-17`

**NOTE**: WebLogic Server 14.1.2.0 provides the WebLogic Remote Console, a lightweight, open source console that you can use to manage domain configurations of WebLogic Server Administration Servers or WebLogic Deploy Tooling (WDT).
For details related to WDT metadata models, please see [documentation `About WebLogic Remote Console`] (<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-remote-console/administer/introduction.html#WLSRC-GUID-C52DA76D-A7F2-4E7F-ABDA-499EB41372E5>).  The WebLogic Remote Console replaces the retired WebLogic Administration Console.

Run the WLS Remote Console :

WebLogic Remote Console is available in two formats:

    * Desktop WebLogic Remote Console, a desktop application installed on your computer.
    * Hosted WebLogic Remote Console, a web application deployed to an Administration Server and accessed through a browser.

Generally, the two formats have similar functionality, though the desktop application offers certain conveniences that are not possible when using a browser. The Desktop WebLogic Remote Console is best suited for monitoring WebLogic domains running in containers.

1. Download the latest version of Desktop WebLogic Remote Console from the [WebLogic Remote Console GitHub Repository] (<https://github.com/oracle/weblogic-remote-console/releases>). Choose the appropriate installer for your operating system.
2. Follow the typical process for installing applications on your operating system.
3. Launch WebLogic Remote Console.

You will need the ip.address of the Admin server container to later use to connect from the Remote Console

        `$ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>`

4. Open the Providers drawer and click More ︙.
5. Choose a provider type from the list:
     `Add Admin Server Connection Provider`
6. Fill in any required connection details for the selected provider.  In the URL filed enter `http://xxx.xx.x.x:7001` if in Production Mode `https://xxx.xx.x.x:9002`.
7. Click OK to establish the connection.

## Copyright
Copyright (c) 2025, Oracle and/or its affiliates.
