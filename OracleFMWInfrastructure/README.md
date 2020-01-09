Oracle Fusion Middleware Infrastructure on Docker
=================================================
This Docker configuration has been used to create the Oracle Fusion Middleware Infrastructure binary image. Providing this FMW image facilitates the configuration and environment set up for DevOps users. This project includes the creation of an  FMW Infrastructure domain.

The certification of the Oracle FMW Infrastructure on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

# Samples
## FMW Infrastructure domain in volume
This project creates a Docker image which contains an Oracle Fusion Middleware Infrastructure domain image. The image extends the FMW Infrastructure binary image and builds an FMW Infrastructure domain persisted to a host volume.
There are two images in this sample, one to create the RCU schema and one to create the FMW Infrastructure domain.

## 12.2.1.3 Patch
This Dockerfile extends the Oracle FMW Infrastructure image and applies a patch.


## Copyright
Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
