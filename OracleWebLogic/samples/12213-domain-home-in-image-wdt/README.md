Example Image with a WLS Domain
===============================
This Dockerfile extends the Oracle WebLogic Server image by creating a sample WLS 12.2.1.3 domain and cluster. Utility scripts are copied into the image, enabling users to plug Node Manager automatically into the Administration Server running on another container.

The Dockerfile uses the `createDomain` script from the Oracle WebLogic Deploy Tooling (WDT) to create the domain from a text-based model file. More information about WDT is available in the README file for the WDT project in GitHub:

`https://github.com/oracle/weblogic-deploy-tooling`

### WDT Model File and Archive

This sample includes a basic WDT model, `simple-topology.yaml`, that describes the intended configuration of the domain within the Docker image. WDT models can be created and modified using a text editor, following the format and rules described in the README file for the WDT project in GitHub.

Another option is to use the WDT `discoverDomain` tool to create a model. This process is also described in the WDT project README file. A user can use the tool to analyze an existing domain, and create a model based on its configuration. The user may choose to customize the model before using it to create a new Docker image.

The sample model is accompanied by a properties file whose values can be changed to customize a domain. The model's variable tokens are replaced with values from 'simple-topology.properties' when building the Docker image. The properties files can be created and modified using a text editor. Select variables in the properties file are used by the Dockerfile during the build to persist ENV variables and expose ports in the image.

Care should be taken to secure the credentials that are present in the model. The ADMIN credential attributes in the sample model have a file token referencing a special property file. Each special property file must only contain a single property and can be created and modified using a text editor. The sample includes the files `adminuser.properties` and the `adminpass.properties` in the `properties/docker_build` directory.

See the README file for more information on using property and file tokens in the WDT model.

The ADMIN credentials are necessary to start the Administration or Managed Server in a Docker container. The sample provides `security.properties` in the `properties/docker-run` directory. This file contains the admin credentials and additional properties used to customize the WebLogic Server start.

**Note**: Oracle recommends that the `adminpass.properties`, `adminuser.properties`, and `security.properties` files be deleted or secured after the image is built and the WebLogic Server is started so that the user name and password are not inadvertently exposed.

Domain creation may require the deployment of applications and libraries. This is accomplished by creating a ZIP archive with a specific structure, then referencing those items in the model. This sample creates and deploys a simple ZIP archive containing a small application WAR. That archive is built in the sample directory prior to creating the Docker image.

When the WDT `discoverDomain` tool is used on an existing domain, a ZIP archive is created containing any necessary applications and libraries. The corresponding configuration for those applications and libraries is added to the model.

## How to Build and Run


**NOTE:** The image is based on a WebLogic Server image in the docker-images project: `oracle/weblogic:12.2.1.3-developer`. Build that image to your local repository before building this sample.

The WebLogic Deploy Tool installer is required to build this image. Add `weblogic-deploy.zip` to the sample directory. The Docker sample requires a minimum release of weblogic-deploy-tooling-0.14. This release uses the new command argument `-domain_home` on the `createDomain` step.  This argument allows a domain home path with a domain folder name that can be different from the domain name in the model file.


    $ wget https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.14/weblogic-deploy.zip
    
 The sample build.sh demonstrates how to use a curl to download the weblogic-deploy.zip before running the docker build:
 
     curl -Lo ${scriptDir}/weblogic-deploy.zip https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.14/weblogic-deploy.zip   

This sample deploys a simple, one-page web application contained in a ZIP archive. This archive needs to be built (one time only) before building the Docker image.

    $ ./build-archive.sh

The sample requires the Admin Host, Admin Port and Admin Name. It also requires the Managed Server port and the domain debug port. The ports will be EXPOSED through Docker. The other arguments are persisted in the image to be used when running a container. If an attribute is not provided as a `--build-arg` on the `build` command, the following defaults are set.

```
CUSTOM_ADMIN_NAME = admin-server
 The value is persisted to the image as ADMIN_NAME

CUSTOM_ADMIN_HOST = wlsadmin
 The value is persisted to the image as ADMIN_HOST

CUSTOM_ADMIN_PORT = 7001
 The value is persisted to the image as ADMIN_PORT

CUSTOM_MANAGED_SERVER_PORT = 8001
 The value is persisted to the image as MANAGED_SERVER_PORT

CUSTOM_DEBUG_PORT = 8453
 The value is persisted to the image as DEBUG_PORT

CUSTOM_DOMAIN_NAME = base_domain
 The value is persisted to the image as DOMAIN_NAME
```

To build this sample keeping the defaults, run:

    $ docker build \
          --build-arg WDT_MODEL=simple-topology.yaml \
          --build-arg WDT_ARCHIVE=archive.zip \
          --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
          --force-rm=true \
          -t 12213-domain-home-in-image-wdt .

This will use the model, variable, and archive files in the sample directory.

This sample provides a script which will read the model variable file and parse the domain, Administration and Managed Server information
  into a string of `--build-arg` statements. This build `arg` string is exported as the environment variable `BUILD_ARG`.
  The sample script specifically parses the sample variable file. Use it as an example to parse a custom variable file.
  This will insure that the values Docker exposes and persists in the image are the same values configured in the domain.

To parse the sample variable file and build the sample, run:

     $ container-scripts/setEnv.sh properties/docker-build/domain.properties

     $ docker build \
          $BUILD_ARG \
          --build-arg WDT_MODEL=simple-topology.yaml \
          --build-arg WDT_ARCHIVE=archive.zip \
          --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
          --force-rm=true \
          -t 12213-domain-home-in-image-wdt .

The Admin Server and each Managed Server are run in containers from this build image. In the sample, the securities.properties file
  is provided on the docker run command. This file contains both the Admin server credentials and the JAVA_OPTS to use for the        
  start of the Admin or Managed server. Mount the properties/docker-run directory to the container so that file can be accessed by the
  server start script. It is the responsibility of the user to manage this volume, and the security.properties, in the container.

To start the containerized Administration Server, run:

    $ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 -v <sample-directory>/properties/docker-run:/u01/oracle/properties 12213-domain-home-in-image-wdt

To start a containerized Managed Server (managed-server-1) to self-register with the Administration Server above, run:

    $ docker run -d --name managed-server-1 --link wlsadmin:wlsadmin -p 8001:8001 -v <sample-directory>/properties/docker-run:/u01/oracle/properties -e MANAGED_SERVER_NAME=managed-server-1 12213-domain-home-in-image-wdt startManagedServer.sh

To start a/n additional Managed Server (in this example managed-server-2), run:

    $ docker run -d --name managed-server-2 --link wlsadmin:wlsadmin -p 8002:8001 -v <sample-directory>/properties/docker-run/:/u01/oracle/properties -e MANAGED_SERVER_NAME=managed-server-2 12213-domain-home-in-image-wdt startManagedServer.sh

The above scenario from this sample will give you a WebLogic domain with a dynamic cluster set up on a single host environment.

You may create more containerized Managed Servers by calling the `docker` command above for `startManagedServer.sh` as long you change the dynamic server count attributes in the sample variable properties file before you build, and you link properly with the Administration Server. For an example of a multihost environment, see the sample `1221-multihost`.

# Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
