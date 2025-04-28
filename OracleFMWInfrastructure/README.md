# Oracle Fusion Middleware Infrastructure on Docker

This repository contains sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users.
This project includes quick start [Dockerfiles](https://github.com/oracle/docker-images/tree/main/OracleFMWInfrastructure/dockerfiles) and [samples](https://github.com/oracle/docker-images/tree/main/OracleFMWInfrastructure/samples) for Oracle Fusion Middleware Infrastructure (FMW Infrastructure) 12.2.1.4, and 14.1.2.0 based on Oracle Linux and Oracle JDK 8, 17, and 21.

**IMPORTANT**: We provide Dockerfiles as samples to build FMW Infrastructure images but this is _NOT_ a recommended practice. We recommend obtaining patched FMW Infrastructure images; patched images have the latest security patches. For more information, see [Obtaining, Creating, and Updating Oracle Fusion Middleware Images with Patches](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/opatc/obtaining-creating-and-updating-oracle-fusion-middleware-images-patches.html#GUID-4FB15429-C985-472F-BDC6-669CA1B678E8).

The samples in this repository are for development purposes only. We recommend for production to use alternative methods, we suggest obtaining base FMW Infrastructure images from the [Oracle Container Registry](https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/ocr-images/).

Consider using the open source [WebLogic Image Tool](https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/custom-images/) to create custom images, and using the open source WebLogic Kubernetes Operator to deploy and manage FMW Infrastructure domains in Kubernetes.

The certification of Fusion Middleware Infrastructure on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com/).

## FMW Infrastructure Samples

This project provides a sample to create a FMW Infrastructure domain. The sample provides two Dockerfiles one that creates a FMW Infrastructure domain and one that creates RCU schema. The FMW Infrastructure domain image extends the FMW Infrastructure binary image and builds a domain persisted to a host volume. The RCU image extends the FMW Infrastructure image and creates RCU schema in the database.

We also provide a sample to patch the FMW Infrastructure binary image.

## License
To download and run the FMW Infrastructure distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

To download and run the Oracle JDK, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker-images/OracleFMWInfrastructure`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](<https://oss.oracle.com/licenses/upl>/) license.

## Customer Support
We support WebLogic Server in certified Docker containers, please read our Support statement. For additional details on the most current WebLogic Server supported configurations, please refer to the [Oracle Fusion Middleware Certification Pages](http://www.oracle.com/technetwork/middleware/ias/oracleas-supported-virtualization-089265.html).


## Copyright
Copyright (c) 2014, 2025 Oracle and/or its affiliates.
