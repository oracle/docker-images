Example of Patching an Oracle Coherence Image
=============================================
This Dockerfile extends the Oracle Coherence standalone image by applying a patch.

# How to build and run
First make sure you have built **oracle/coherence:12.2.1.3.0-standalone**.

Then download file [p28173552_122130_Generic.zip](https://updates.oracle.com/Orion/PatchDetails/process_form?patch_num=28173552),
Coherence 12.2.1.3.1 Cumulative Patch using OPatch, and place it next to this README.

To build, run:

        $ docker build -t oracle/coherence:12.2.1.3.1 .

## Verify that the Patch has been applied correctly
Run a container from the image

        $ docker run -d --name verify_patch oracle/coherence:12.2.1.3.1

Go into the image

        $ docker exec -it verify_patch /bin/bash

cd OPatch and run:

        ./opatch lsinventory 

The patch will show in the inventory of applied patches.

# Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
