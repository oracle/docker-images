Example of Image with WLS Domain
================================
There are two  Dockerfiles which extend the Oracle WebLogic binary image and apply a necessary patch for the WebLogic Kubernetes Operator 2.0. `Dockerfile.patch-ontop-12213` patches the WebLogic binary image 12.2.1.3 with the patch necesary for WebLogic on the Kubernetes project. `Dockerfile.patch-ontop-12213-psu` applies the 2018 October PSU to WebLogic binary image 12.2.1.3, a required update to Opatch, and the patch necesary for WebLogic on the Kubernetes project.

1.) `Dockerfile.patch-ontop-12213`: applies two patches `p29135930` (on top of WLS 12.2.1.3) and `p27117282` (this patch is needed only if the WebLogic binary image is created manually from this GitHub project).

**Note**: Patch 27117282 only needs to be applied if the WebLogic 12.2.1.3 install image has been built locally from this GitHub project using the Dockerfile and scripts under `dockerfiles/12.2.1.3`.

2.) `Dockerfile.patch-ontop-12213-psu`: applies patch `p28298734` (WLS PATCH SET UPDATE 12.2.1.3.181016), patch `p29135930` (on top of WLS 12.2.1.3 October PSU), and `p28186730` (Opatch update). Before applying the WebLogic 12.2.1.3 October PSU PATCH 12.2.1.3.181016WLSPSU, Opatch needs to be updated with PATCH 28186730: OPATCH 13.9.4.0.0 FOR FMW/WLS 12.2.1.3.

**Note**: Historically, OPatch was updated by unzipping and replacing the `ORACLE_HOME/OPatch` directory. For versions greater than or equal to 13.6, now it uses the OUI installation tooling. This ensures that the installer both executes the file updates and logs the components and file changes to the OUI meta-data. A pure unzip install means the OUI tooling is not aware of these changes, which has on occasion, led to upgrade-related issues.

We are applying patch `p29135930` which is required for the WebLogic Kubernetes Operator to work.

## How to build
First make sure you have built **oracle/weblogic:12.2.1.3-developer**.
If you want to patch on top of WebLogic Server 12.2.1.3 download:

	file [p29135930_122130_Generic.zip](http://support.oracle.com) and place it in the same directory as this README.
	file [p27117282_122130_Generic.zip](http://support.oracle.com) and place it in the same directory as this README.

If you want to patch on top of WebLogic Server 12.2.1.3 October PSU download:

	file [p28186730_139400_Generic.zip](http://support.oracle.com) and place it in the same directory as this README.
	file [p28298734_122130_Generic.zip](http://support.oracle.com) and place it in the same directory as this README.
	file [p29135930_12213181016_Generic.zip](http://support.oracle.com) and place it in the same directory as this README.

To build, run:

        $ docker build -t oracle/weblogic:12213-patch-wls-for-k8s -f Dockerfile.patch-ontop-12213 .
        or
        $ docker build -t oracle/weblogic:12213-patch-wls-for-k8s -f Dockerfile.patch-ontop-12213-psu .

## Verify that the patch has been applied correctly
Run a container from the image:

        $ docker run --name verify_patch -it oracle/weblogic:12213-patch-wls-for-k8s /bin/bash

and run:

        $ cd OPatch
        $ ./opatch version
        $ ./opatch lspatches

	1) You will see one-off patches 29135930, and 27117282.
	2) You will see one-off patches 29135930, 28298734 WLS PATCH SET UPDATE 12.2.1.3.181016, and the OPatch version being 13.9.4.0.0.

## Run a single server domain
The WebLogic Server install image (patched in this sample) allows you to run a container with a single WebLogic Server domain. This makes it extremely simple to deploy applications and any resources the applications might need. The steps below describe how to run the single server domain container.

### Providing the Administration Server user name and password
The user name and password must be supplied in a `domain.properties` file located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server.

The format of the `domain.properties` file is `key=value` pair:

        username=myadminusername
        password=myadminpassword

**Note**: Oracle recommends that the `domain.properties` file be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

### Start the container
Start a container from the image created in step 1.
You can override the default values of the following parameters during runtime with the `-e` option:

* `ADMIN_NAME`                  (default: `AdminServer`)
* `ADMIN_LISTEN_PORT`           (default: `7001`)
* `DOMAIN_NAME`                 (default: `base_domain`)
* `DOMAIN_HOME`                 (default: `/u01/oracle/user_projects/domains/base_domain`)
* `ADMINISTRATION_PORT_ENABLED` (default: `true`)
* `ADMINISTRATION_PORT`         (default: `9002`)

**NOTE**: For security, the Administration port 9002 is enabled by default. If you would like to disable the Administration port, set `ADMINISTRTATION_PORT_ENABLED` to `false`. If you intend to run these images in production, then you must change the Production Mode to `production`. To set the `DOMAIN_NAME`, you must set both `DOMAIN_NAME` and `DOMAIN_HOME`.

```
        $docker run -d -p 7001:7001 -p 9002:9002  -v HOST PATH where the domain.properties file is :/u01/oracle/properties -e ADMINISTRATION_PORT_ENABLED=true -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain -e DOMAIN_NAME=abc_domain oracle/weblogic:12213-opatch-update
```

Run the WLS Administration Console:

        $ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>

In your browser, enter `https://xxx.xx.x.x:9002/console`. Your browser will request that you accept the Security Exception. To avoid the Security Exception, you must update the WebLogic Server SSL configuration with a custom identity certificate.

##  Samples for WebLogic multi-server domains and cluster
To give users an idea of how to create a WebLogic domain and cluster from a custom Dockerfile which extends the WebLogic Server install image, we provide a few samples for 12c versions of the developer distribution. For an example, look at the `12213-domain-home-in-image` sample.

# Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
