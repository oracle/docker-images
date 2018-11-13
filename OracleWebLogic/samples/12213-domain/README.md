Example Image with a  WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by creating a sample WLS 12.2.1.3 domain and cluster.

Utility scripts are copied into the image, enabling users to plug Node Manager automatically into the Administration Server running on another container.

### Admin Password

On the first startup of the container, a random password will be generated for the administration of the domain. You can find this password in the output line:

`Oracle WebLogic Server auto generated Admin password:`

If you need to find the password at a later time, grep for `password` in the Docker logs generated during the startup of the container. To look at the Docker container logs, run:

    $ docker logs --details <Container-id>

**NOTE:** The administration password can be passed in at runtime by using the `-e` option, and override the generated password.  If using the auto-generated password, please make sure to pass the password into the Managed Server container at runtime.

### How to Build and Run

**NOTE:** First make sure you have built `oracle/weblogic:12.2.1.3-developer`.  If you want to set your own Domain Home and Domain Name they are ARG and must be set at build time. 

* Domain Name:     `PRE_DOMAIN_NAME`      (default: `base_domain`)  
* Domain Home:     `PRE_DOMAIN_HOME`      (default: `/u01/oracle/user_projects/domains/$PRE_DOMAIN_NAME`)  
 
To build this sample, run:

        $ docker build --build-arg PRE_DOMAIN_NAME=myDomain --build-arg PRE_DOMAIN_HOME= `/u01/oracle/myDomHome` -t 12213-domain .

You can define the following environment variables at Docker runtime using the `-e` option  on the command line or in the `domain.properties` file. These environmental variables need to be set for the Administration Server as well as for the Managed Servers.

* Admin Password:  `ADMIN_PASSWORD`  Auto Generated
* Admin Username:  `ADMIN_USERNAME`  `weblogic`      
* Admin Name:      `ADMIN_NAME`       `AdminServer`  
* Admin Port:      `ADMIN_PORT`       `7001`          
* Admin Host:      `ADMIN_HOST`       `wlsadmin`    
* Cluster Name:    `CLUSTER_NAME`   `DockerCluster`
* Debug Flag:       `DEBUG_FLAG`      `false`         
* Production Mode:  `PRODUCTION_MODE` `dev`            
* Managed Server Name:  `MS_NAME`      Generated    
* Managed Server Port: `MS_PORT`       `8001`          
* Node Manager Name:  `NM_NAME`        Generated      



**Important**: The domain directory needs to be externalized by using data volumes (`-v` option). The Administration Server as well as the Managed Servers need to read/write to the same `DOMAIN_HOME`.

To start the containerized Administration Server, run:

	$ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -v <host directory>:/u01/oracle/user_projects 12213-domain

To start a containerized Managed Server (MS1) to self-register with the Administration Server above, run:

 	$ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS1 --volumes-from wlsadmin 12213-domain createServer.sh

To start a second Managed Server (MS2), run:

 	$ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS2 --volumes-from wlsadmin 12213-domain createServer.sh

The above scenario from this sample will give you a WebLogic domain with a cluster set up on a single host environment.

You may create more containerized Managed Servers by calling the `docker` command above for `createServer.sh` as long you link properly with the Administration Server. For an example of a multihost environment, see the sample `1221-multihost`.

# Copyright
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
