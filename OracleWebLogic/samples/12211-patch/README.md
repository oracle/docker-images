Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by applying a PSU patch.

# How to build and run
First make sure you have built **oracle/weblogic:12.2.1.1-developer**.

Then download file [p24286152_122110_Generic.zip](http://support.oracle.com) and place it next to this README.

To build, run:

        $ docker build -t 12211-psu24286152 .

To start the Admin Server, run:

        $ docker run -p 7001:7001 12211-psu24286152

When you run the container a patched WebLogic Server 12.2.1.1 empty domain is created. At startup of the container a random password will be generated for the Administration of the domain. You can find this password in the output line:

`Oracle WebLogic Server auto generated Admin password:`

Go to your browser and start the Adminsitration console by running:
        http://localhost:7001/console

Extend this patched image to create a domain image and start WebLogic Servers running in containers.
# Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
