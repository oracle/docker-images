Example Image with a  WebLogic Server Domain
=============================================
This Dockerfile extends the Oracle WebLogic image by creating a sample WebLogic Server  12.2.1.3 domain and cluster into a Docker image.

A domain is created inside the image and Utility scripts are copied into the image, enabling users to start an Administration Server and a Managed Servers each running in separate containers.

### Providing the Administration Server user name and password

**During Docker Build:** The user name, password, and data source parameters must be supplied in the domain.properties file located in a `docker-images/OracleWebLogic/samples/12213-domain-home-in-image/properties` in the HOST. This properties file gets copied into the image directory `/u01/oracle/properties`.

**During Docker Run:** The user name and password must be supplied in a security.properties file located in a `docker-images/OracleWebLogic/samples/12213-domain-home-in-image/properties` in the HOST. In the Docker run command line add the -v option maps the properties file into the image directory /u01/oracle/properties. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server and Managed Servers.

The format of the domain.properties and security.properties files are key=value pairs, for example:

username=myadminusername
password=myadminpassword

Note: Oracle recommends that the domain.properties and security.properties files be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

### How to Build and Run

**NOTE:** First make sure you have built `oracle/weblogic:12.2.1.3-developer`.  If you want to set your own Domain Name it is an ARG parameter and must be set at build timei with the --build-arg deirective. 

* Domain Name:     `DOMAIN_NAME`      (default: `base_domain`)  

To build this sample, run:

	$ docker build --build-arg DOMAIN_NAME=myDomain -t 12213-domain-home-in-image .

**NOTE:** The DOMAIN_HOME will be persisted in the image directory `/u01/oracle/user-projects/domains/$DOMAIN_NAME`.

You can define the following environment variables at Docker build time  using the `--build-arg` option  on the command line. These environmental variables need to be set for the domain. 

* Admin Name:                               `ADMIN_NAME`                      (default: `AdminServer`)  
* Admin Port:                               `DOM_ADMIN_PORT`                  (default: `7001`)          
* Managed Server Name Prefix:               `MANAGED_SERVER_NAME_BASE`        (default: `MS`)    
* Number of Managed Servers in the Cluster: `CONFIGURED_MANAGED_SERVER_COUNT` (default: `2`)
* Managed Server Port:                      `MANAGED_SERVER_PORT`             (default: `8001`)          
* Cluster Name:                             `DOM_CLUSTER_NAME`                (default: `DockerCluster`)
* Debug Flag:                               `DOM_DEBUG_FLAG`                  (default: `true`)         
* Production Mode:                          `PRODUCTION_MODE_ENABLED`         (default: `false`)            
* Cluster Type:                             `CLUSTER_TYPE`                    (default: `DYNAMIC`)


To start the containerized Administration Server, run:

	$ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 -v <HOST DIRECTORY TO PROPERTIES FILE>/properties:/u01/oracle/properties 12213-domain-home-in-image

To start a containerized Managed Server (MS1) to self-register with the Administration Server above, run:

	$ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 -v <HOST DIRECTORY TO PROPERTIES FILE>/properties:/u01/oracle/properties -e MANAGE_S_NAME=MS1 12213-domain-home-in-image startManagedServer.sh


To start a second Managed Server (MS2), run:

	$ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 -v <HOST DIRECTORY TO PROPERTIES FILE>/properties:/u01/oracle/properties -e MANAGE_S_NAME=MS2 12213-domain-home-in-image startManagedServer.sh

The above scenario from this sample will give you a WebLogic domain with a cluster set up on a single host environment.

You may create more containerized Managed Servers by calling the `docker` command above

# Copyright
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
