Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image built under 12212-domain with tag name '12212-domain'

WLST Online script are used during Docker image build phase to deploy the

- JMS artifacts (JMS Server, Queue etc).

# How to build and run
First make sure you have built sample image inside **12212-domain**. Now to build this sample, run:

        $ docker build -t 12212-domain-online-config .

You should now be able to see the JMS components
To start the containerized Admin Server, run:

    $ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 1221-domain-online-config

To start a containerized Managed Server to self-register with the Admin Server above, run:

    $ docker run -d --link wlsadmin:wlsadmin -p 7002:7002 1221-domain-online-config createServer.sh



# Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
