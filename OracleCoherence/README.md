<!--
    Copyright (c) 2015, 2022, Oracle and/or its affiliates.
    Licensed under the Universal Permissive License v 1.0 as shown at
    https://oss.oracle.com/licenses/upl.
-->
Oracle Coherence Docker Images
===============

Instructions for building [Oracle Coherence](https://www.oracle.com/technetwork/middleware/coherence/overview/index.html) images are no longer 
included in this repository. The old instructions in this repository used the Coherence commercial installer to install Coherence into an image - 
this is not a recommended way to build Coherence images. 
In almost every Oracle Coherence use case, Coherence is used as one or more libraries that are included as application 
dependencies, it is not run from the files installed by the commercial Coherence installer. Moreover, since the relase of Coherence Community Edition, 
which is published on Maven Central, CE customers do not use the commercial installer to obtain Coherence. 

Pre-built images for the OSS [Coherence Community Edition](https://github.com/oracle/coherence) can be found in the
[GitHub packages](https://github.com/oracle/coherence/pkgs/container/coherence-ce) section of the Coherence CE repository.
These are publicly availabe images that can be pulled from ghcr.io

Pre-built images containing the commercial Coherence releases can be found in the Middleware section of
the [Oracle Container Registry](https://container-registry.oracle.com)

Documentation on approaches for building Coherence application images can also be found in the 
[Coherence Kubernetes Operator](https://oracle.github.io/coherence-operator/docs/latest/#/docs/applications/020_build_application) documentation.
