Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by applying a patch.

# How to build and run
First make sure you have built **oracle/weblogic:12.2.1.3-developer**.

Then download file [p27117282_122130_Generic.zip](http://support.oracle.com) and place it next to this README.

To build, run:

        $ docker build -t oracle/weblogic:12213-p27117282 .

## Run Single Server Domain
#### Providing the Administration Server user name and password
The user name and password must be supplied in a `domain.properties` file located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server.

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
      * `DOMAIN_HOME`                 (default: `/u01/oracle/user_projects/domains/base_domain`)
      * `ADMINISTRATION_PORT_ENABLED` (default: `true`)
      * `ADMINISTRATION_PORT`         (default: `9002`)

**NOTE**: For security, the Administration port 9002 is enabled by default. If you would like to disable the Administration port, set `ADMINISTRTATION_PORT_ENABLED` to false. If you intend to run these images in production, then you must change the Production Mode to `production`. To set the `DOMAIN_NAME`, you must set both `DOMAIN_NAME` and `DOMAIN_HOME`.

        $docker run -d -p 7001:7001 -p 9002:9002  -v `HOST PATH where the domain.properties file is`:/u01/oracle/properties -e ADMINISTRATION_PORT_ENABLED=true -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain -e DOMAIN_NAME=abc_domain oracle/weblogic:12213-p27117282 

Run the WLS Administration Console:

        $ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>

In your browser, enter `https://xxx.xx.x.x:9002/console`. Your browser will request that you accept the Security Exception. To avoid the Security Exception, you must update the WebLogic Server SSL configuration with a custom identity certificate.

## Verify that the Patch has been applied correctly
Run a container from the image

        $ docker run --name verify_patch oracle/weblogic:12213-p27117282

Go into the image

        $ docker exec -it verify_patch /bin/bash

cd OPatch and run:

        ./opatch lsinventory 

The patch will show in the inventory of applied patches.

# Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
