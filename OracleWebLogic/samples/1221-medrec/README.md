Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by installing the Supplemental package of WebLogic which includes extra samples of Java EE, Coherence applications, and Multitenant domains.

# How to build and run
First make sure you have built **oracle/weblogic:12.2.1-developer**. Now to build this sample, run:

        $ docker build -t 1221-medrec .

To start the Admin Server, run:

        $ docker run -d -p 7001:7001 1221-medrec

By default the image will run the 'single.server.sample' of the Supplemental package, which will create and start the MedRec domain. To access the MedRec application, go to:

        http://localhost:7001/medrec

To see other options, visit the [Supplemental Quick Installer README file](http://download.oracle.com/otn/nt/middleware/12c/1221/wls_1221_SupplementalQuickInstaller_README.txt). To run other samples, you may try the following:

        $ docker run d -p 7001:7001 1221-medrec mt.single.server.sample

# Copyright
Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
