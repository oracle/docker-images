Oracle Fusion Middleware Infrastructure on Docker
=================================================
This Docker configuration has been used to create the Oracle Fusion Middleware Infrastructure binary image. Providing this FMW image facilitates the configuration and environment set up for DevOps users. This project includes the creation of an  FMW Infrastructure domain.

**IMPORTANT**: We provide Dockerfiles as samples to build WebLogic images but this is _NOT_ a recommended practice. We recommend obtaining patched WebLogic Server images; patched images have the latest security patches. For more information, see [Obtaining, Creating, and Updating Oracle Fusion Middleware Images with Patches](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/opatc/obtaining-creating-and-updating-oracle-fusion-middleware-images-patches.html#GUID-4FB15429-C985-472F-BDC6-669CA1B678E8).

The samples in this repository are for advanced use cases only. For alternative methods, we suggest obtaining base WebLogic Server images from the [Oracle Container Registry](https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/ocr-images/), using the open source [WebLogic Image Tool](https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/custom-images/) to create custom images, and using the open source [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/) to deploy and manage WebLogic domains.

The certification of the Oracle FMW Infrastructure on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

# Samples
## FMW Infrastructure domain in volume
This project creates a Docker image which contains an Oracle Fusion Middleware Infrastructure domain image. The image extends the FMW Infrastructure binary image and builds an FMW Infrastructure domain persisted to a host volume.
There are two images in this sample, one to create the RCU schema and one to create the FMW Infrastructure domain.

## 12.2.1.3 Patch
This Dockerfile extends the Oracle FMW Infrastructure image and applies a patch.


## Copyright
Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
