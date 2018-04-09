Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by creating a sample WLS domain and cluster.

Util scripts are copied into the image enabling users to plug NodeManager automatically into the AdminServer running on another container.

### Admin Password

On the first startup of the container a random password will be generated for the Administration of the domain. You can find this password in the output line:

Oracle WebLogic Server auto generated Admin password:

If you need to find the password at a later time, grep for "password" in the Docker logs generated during the startup of the container. To look at the Docker Container logs run:

    $ docker logs --details <Container-id>

**NOTE:** The administration password can be passed in at runtime by using the -e option and override the generated password.  If using the auto-generated password please make sure to pass the password into the Managed Server container at runtime.

### How to Build and Run

**NOTE:** First make sure you have built **oracle/weblogic:12.2.1.2-developer**. 

You can define the following environment variables at docker runtime using the -e option  in the command line or defining them in the domain.properties file. These enviromental variables need to be set for the Admin Server as well as for the Managed Servers.

Admin Password:      ADMIN_PASSWORD  Auto Generated (default)

Admin Username:      ADMIN_USERNAME  weblogic       (default)

Admin Name:          ADMIN_NAME      AdminServer    (default)

Domain Name:         DOMAIN_NAME     base_domain    (default)

Admin Port:          ADMIN_PORT      7001           (default)

Admin Host:          ADMIN_HOST      wlsadmin       (default)

Cluster Name:        CLUSTER_NAME    DockerCluster  (default)

Debug Flag:          DEBUG_FLAG      false          (default)

Production Mode:     PRODUCTION_MODE dev           (default)

Managed Server Name: MS_NAME         Generated      (default)

Managed Server Port: MS_PORT         8001           (default)

NodeManager Name :   NM_NAME         Generated      (default)

To build this sample, run:

        $ docker build -t 12212-domain .

**Important** The domain directory needs to be externalized by using Data Volumes (-v option). The Admin Server as well as the Managed Servers need to read/write to the same DOMAIN_HOME. 

To start the containerized Admin Server, run

        $ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 --env-file ./domain.properties -e ADMIN_PASSWORD=<admin_password> -v <host directory>:/u01/oracle/user_projects 12212-domain

To start a containerized Managed Server (MS1) to self-register with the Admin Server above, run:

        $ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS1 --volumes-from wlsadmin 12212-domain createServer.sh

To start a second Managed Server (MS2), run the following command:

        $ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS2 --volumes-from wlsadmin 12212-domain createServer.sh

The above scenario from this sample will give you a WebLogic domain with a cluster setup, on a single host environment.

You may create more containerized Managed Servers by calling the `docker` command above for `createServer.sh` as long you link properly with the Admin Server. For an example of multihost enviornment, check the sample `1221-multihost`.

# Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
