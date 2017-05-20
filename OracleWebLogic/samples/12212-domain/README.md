Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by creating a sample empty domain.

Util scripts are copied into the image enabling users to plug NodeManager automatically into the AdminServer running on another container.

# How to build and run
First make sure you have built **oracle/weblogic:12.2.1.2-developer**. Now to build this sample, run:

        $ docker build -t 12212-domain --build-arg ADMIN_PASSWORD=welcome1 .

To start the containerized Admin Server, run:

        $ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 12212-domain

To start a containerized Managed Server to self-register with the Admin Server above, run:

        $ docker run -d --link wlsadmin:wlsadmin -p 7002:7002 12212-domain createServer.sh

The above scenario from this sample will give you a WebLogic domain with a cluster setup, on a single host environment.

You may create more containerized Managed Servers by calling the `docker` command above for `createServer.sh` as long you link properly with the Admin Server. For an example of multihost enviornment, check the sample `1221-multihost`.

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
