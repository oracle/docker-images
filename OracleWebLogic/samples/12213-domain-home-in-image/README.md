Example Image with a  WebLogic Server Domain
=============================================
This Dockerfile extends the Oracle WebLogic image by creating a sample WebLogic Server  12.2.1.3 domain and cluster into a Docker image.

A domain is created inside the image and Utility scripts are copied into the image, enabling users to start an Administration Server and a Managed Servers each running in separate containers.

### Providing the Administration Server user name and password

**During Docker Build:** The user name, password must be supplied in domain_security.properties file, and domain configuration parameters must be supplied in the domain.properties file.  Both files are located in the directory `docker-images/OracleWebLogic/samples/12213-domain-home-in-image/properties` in the HOST. These properties files get copied into the image directory `/u01/oracle/properties`.

**During Docker Run:** The user name and password must be supplied in a security.properties file, and runtime parameters must be supplied in the runtime.properties file located in a `docker-images/OracleWebLogic/samples/12213-domain-home-in-image/properties` in the HOST. In the Docker run command line add the -v option maps the properties file into the image directory /u01/oracle/properties. 

The security properties files enables the scripts to configure the correct authentication for the WebLogic Administration Server and Managed Servers. The format of the security.properties and domain_security.properties files are key=value pairs, for example:

username=myadminusername
password=myadminpassword

The domain properties file enables you to customize the parameter to configure the WebLogic domain. The format of the domain.properties are key=value pairs, for example:

ADMIN_NAME=admin-server
ADMIN_HOST=wlsadmin
MANAGED_SERVER_NAME_BASE=managed-server
CONFIGURED_MANAGED_SERVER_COUNT=2
CLUSTER_NAME=cluster-1
DEBUG_FLAG=true
PRODUCTION_MODE_ENABLED=true
CLUSTER_TYPE=DYNAMIC

**Note:** Oracle recommends that the domain_security.properties and security.properties files be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

### How to Build and Run

**NOTE:** First make sure you have built `oracle/weblogic:12.2.1.3-developer`. 

You can define the following environment variables at Docker build time  using the `--build-arg` option  on the command line. These environmental variables need to be set for the domain. 

* Domain Name:           `DOMAIN_NAME`                (default: `base_domain`)  
* Admin Port:            `CUSTOM_ADMIN_PORT`          (default: `7001`)          
* Managed Server Port:   `CUSTOM_MANAGED_SERVER_PORT` (default: `8001`)          

**NOTE:** The DOMAIN_HOME will be persisted in the image directory `/u01/oracle/user-projects/domains/$DOMAIN_NAME`.

To build this sample, run:

	$ docker build --build-arg DOMAIN_NAME=myDomain -t 12213-domain-home-in-image .


To start the containerized Administration Server, run:

	$ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 -v <HOST DIRECTORY TO PROPERTIES FILE>/properties:/u01/oracle/properties 12213-domain-home-in-image

To start a containerized Managed Server (MS1) to self-register with the Administration Server above, run:

	$ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 -v <HOST DIRECTORY TO PROPERTIES FILE>/properties:/u01/oracle/properties -e MANAGE_S_NAME=managed-server1 12213-domain-home-in-image startManagedServer.sh


To start a second Managed Server (MS2), run:

	$ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 -v <HOST DIRECTORY TO PROPERTIES FILE>/properties:/u01/oracle/properties -e MANAGE_S_NAME=managed-server2 12213-domain-home-in-image startManagedServer.sh

The above scenario from this sample will give you a WebLogic domain with a cluster set up on a single host environment.

You may create more containerized Managed Servers by calling the `docker` command above

# Copyright
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
