Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image built under 12213-domain-home-in-image and deploy the sample application to the cluster.

This sample deploys a simple, one-page web application contained in a ZIP archive. This archive needs to be built (one time only) before building the Docker image.

    $ ./build-archive.sh

# How to build and run
To deploy an application to a domain where the domain home is inside the image you extend the image `12213-domain-home-in-image` and using WLST offline you deploy the sample application.  First make sure you have built sample WebLogic domain image inside **12213-domain-home-in-image**. Now to build this sample, run:

        $ docker build --build-arg APPLICATION_NAME=sample --build-arg APPLICATION_PKG=archive.zip -t 12213-domain-with-app .

# How to run the domain
Follow the instructions in the sample `OracleWebLogic/samples/12213-domain-home-in-image` to define your domain properties in the domain.properties and domain-security.properties files.

To start the containerized Administration Server, run:

        $ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 \
          -v <HOST DIRECTORY TO PROPERTIES FILE>/properties/docker-run:/u01/oracle/properties \
         12213-domain-with-app 

To start a containerized Managed Server (MS1) to self-register with the Administration Server above, run:

        $ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 \
          -v <HOST DIRECTORY TO PROPERTIES FILE>/properties/docker-run:/u01/oracle/properties \
          -e MANAGED_SERV_NAME=managed-server1 12213-domain-with-app startManagedServer.sh

To start a second Managed Server (MS2), run:

        $ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 \
          -v <HOST DIRECTORY TO PROPERTIES FILE>/properties/docker-run:/u01/oracle/properties \
          -e MANAGED_SERV_NAME=managed-server2 12213-domain-with-app startManagedServer.sh


Run the WLS Administration Console:

In your browser, enter `https://localhost:7001/console`.

Run the sample application:

To access the sample application, in your browser enter `http://localhost:7001/sample`.

# Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
