Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image built under 1221-domain with tag name '1221-domain'

It will deploy during Docker image build phase, using a WLST Offline script, any package defined in APP_PKG_FILE located in APP_PKG_LOCATION into the DOMAIN_HOME with name defined in APP_NAME 

# How to build and run
First make sure you have built sample image inside **1221-domain**. Now to build this sample, run:

        $ docker build -t 1221-appdeploy .

To start the Admin Server with the application automatically deployed, run:

        $ docker run -d -p 8001:8001 1221-appdeploy

To access the sample application, go to **http://localhost:8001/sample**.

# Copyright
Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
