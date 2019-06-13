Oracle WebLogic domain in volume on Docker
========================================================
This project creates a Docker image which contains an Oracle WebLogic domain image. The image extends the WebLogic install image and builds an WebLogic domain persisted to a host volume.

## How to build and run
This project offers a sample Dockerfile and scripts to build an Oracle WebLogic 12.2.1.3 domain in volume. 

### Building the Oracle WebLogic 12.2.1.3 developer install image
A prerequisite to building the 12213-weblogic-domain-in-volume image is having an Oracle WebLogic 12.2.1.3 install image. The Dockerfile and scripts to build the image are under the folder, `../../OracleWebLogic/dockerfile/12.2.1.3`. For more information, see the [README](../../OracleWebLogic/dockerfile/12.2.1.3/README.md) file.

**IMPORTANT**: If you are building the Oracle WebLogic image, you must first download the Oracle WebLogic 12.2.1.3 binary and place it in the folder, `../OracleWebLogic/dockerfiles/12.2.1.3`.

        $ cd ../../OracleWebLogic/dockerfiles
        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version] [-d | -g ] [-s]
        Builds a Docker Image for Oracle WebLogic Server.

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.3
           -d: creates image based on 'developer' distribution
           -g: creates image based on 'generic' distribution
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        * select one distribution only: -d, or -g

        LICENSE UPL 1.0

        Copyright (c) 2014,2019 Oracle and/or its affiliates. All rights reserved.

#### Providing the Administration Server user name and password and Database username and password
The administration server user name and password must be supplied in a `domain_security.properties` file. This file should be located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server.

The format of the `domain_security.properties` file is key=value pair:

        username=myadminusername
        password=myadminpassword

**Note**: Oracle recommends that the `domain_securtity.properties` file be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

### Build the WebLogic Domain Image

  1. To build the `12.2.1.3` WebLogic domain image, run:

        `$ docker build -f Dockerfile -t 12213-weblogic-domain-in-volume .`

  2. Verify you now have this image in place with:

	`$ docker images`

#### Start the container
Start a container from the image created in step 1.
You can override the default values of the following parameters during runtime in the `./properties/domain.properties` file. The script `./container-scripts/setEnv.sh` sets the environment variables to configure the domain. The properties set as environment variables are:

      * `DOMAIN_NAME`
      * `ADMIN_PORT`
      * `ADMIN_NAME`
      * `ADMIN_HOST`
      * `MANAGED_SERVER_PORT`
      * `MANAGED_SERVER_NAME_BASE`
      * `CONFIGURED_MANAGED_SERVER_COUNT`
      * `CLUSTER_NAME`
      * `CLUSTER_TYPE`
      * `PRODUCTION_MODE_ENABLED`
      * `DOMAIN_HOST_VOLUME`

**NOTE**: When you set the `DOMAIN_NAME`, the `DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME`. 

**IMPORTANT**: The domain directory needs to be externalized by using data volumes (-v option). The Administration Server as well as the Managed Servers need to read/write to the same DOMAIN_HOME.

We are supplying scripts `run_admin_server.sh` and `run_managed_server.sh` to facilitate setting the environment variables defined in the property files and running the admin server and managed server containers.

  Start a container to launch the Administration and Managed Servers from the image created in step 1.

  To run an Administration Server container, call:

        `$ sh run_admin_server.sh`

  To run Managed Server with base name `MS` pass in to the scrtipt `run_managed_server.sh` the name of the managed server you want to run and the host port that will be mapped to the managed server port defined in `MANAGED_SERVER_PORT`. 

  To run managed server one with name `MS1` and mapped to host port 98001 call:

        `$ sh run_managed_server.sh MS1 98001`

  To run managed server two with name `MS2` and mapped to host port 98002 call:

        `$ sh run_managed_server.sh MS2 98002`

  Access the Administration Console:

	`$ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>`
        This returns the IP address of the container (for example, `xxx.xx.x.x`).  Go to your browser and enter `http://xxx.xx.x.x:9001/console`

        Because the container ports are mapped to the host port, you can access it using the `hostname` as well.


## Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
