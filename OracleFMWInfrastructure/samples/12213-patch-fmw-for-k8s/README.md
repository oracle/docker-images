Example how to patch a FMW Infrastructure Image
===============================================
This image extends the Oracle Fusion Middleware Infrastructure binary image and applies the necessary patch for the WebLogic Kubernetes Operator 2.2.  We are applying patch `p29135930` which is required for the WebLogic Kubernetes Operator to work.

## How to build
First make sure you have built **oracle/fmw-infrastructure:12.2.1.3** in `OracleFMWInfrastructure/dockerfile/12.2.1.3`.
If you want to patch on top of FMW Infrastructure 12.2.1.3 download:

	file [p29135930_122130_Generic.zip](http://support.oracle.com) and place it in the same directory as this README.

To build, run:

        $ docker build -t oracle/fmw-infrastructure:12213-update-k8s .

## Verify that the patch has been applied correctly
Run a container from the image:

        $ docker run --name verify_patch -it oracle/fmw-infrastructure:12213-update-k8s /bin/bash

and run:

        $ cd OPatch
        $ ./opatch version
        $ ./opatch lspatches

        You will see one-off patches 29135930.

##  Samples for FMW Infastructure multi-server domains and cluster
Reference the sample in `OracleFMWInfrastructure/samples/12213-domain-in-volume` to build a FMW Infrastructure domain with a domain which has an Admin Server, a WebLogic cluster, and a configurable number of managed servers. 

# Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
