Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic domain built under 12212-domain with tag name '12212-domain'

It will enable the domain-wide administration port on 9002 by default.

# How to build and run
First make sure you have built sample domain inside **12212-domain**. Now to build this sample, run:

        $ docker build -t 12212-admin-port .

To start the containerized Admin Server, run:

        $ docker run -d --network foo --name=wlsadmin -p 8001:8001 -p 9002:9002 12212-admin-port

To start a containerized Managed Server to self-register with the Admin Server above, run:

        $ docker run -d --network foo -p 7001:7001 12212-admin-port createServer.sh --env MS_NAME=ms1 t3s://wlsadmin:9002 weblogic welcome1
        

# Copyright
Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
