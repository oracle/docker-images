# Oracle Java in Containers

This repository contains sample container configurations to facilitate installation and environment setup for DevOps users. This project provides container images based on Oracle Linux for JDK versions 24, 21, 17, 11 and 8 as well as Server JRE 8.

Oracle Java Server JRE provides the features from Oracle Java JDK commonly required for server-side applications (i.e. Running a Java EE application server). For more information about Server JRE, visit the [Understanding the Server JRE blog entry](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) from the Java Product Management team.

## Building the Oracle Java base image

For the most recent JDK Releases ( JDK 24 and 21), offered under the [Oracle No-Fee Terms and Conditions](https://www.java.com/freeuselicense) (NFTC),  the required JDK binaries will be downloaded from [Oracle](https://www.oracle.com/javadownload) as part of the build using curl.

e.g., To build the JDK 24 container image run:

```bash
cd ../OracleJava/24
docker build --file Dockerfile.ol9 --tag oracle/jdk:24 .
```

Updates to prior LTS releases: JDK 17, JDK 11, JDK 8, and Server JRE 8 are offered under the [Oracle Technology Network License Agreement for Oracle Java SE](https://www.java.com/otnlicense). Users must accept the license terms, generate a download token, and provide it as a build argument.  Token generation is documented on [https://docs.cloud.oracle.com/en-us/iaas/jms/doc/java-download.html](https://docs.cloud.oracle.com/en-us/iaas/jms/doc/java-download.html).

e.g., To build the JDK 17 container image generate a token for JDK 17 and run:

```bash
cd ../OracleJava/17
docker build --file Dockerfile.ol8 --tag oracle/jdk:17 --build-arg JDK17_TOKEN=<$token> .
```

e.g., To build the Server JRE 8 container image generate a token for JDK 8 and run:

```bash
cd ../OracleJava/8/serverjre
docker build --file Dockerfile.ol8 --tag oracle/serverjre:8 --build-arg JDK8_TOKEN=<$token> .
```

For the NFTC releases (JDK 24 and 21) the right command is already scripted in `build.sh` so you can alternatively run:

```bash
bash build.sh
```

### Parent image OS version

The Oracle Java image for JDK 24 uses `oraclelinux:9` as the parent image.

The Oracle Java image for JDK 21 and earlier use `oraclelinux:8` as the parent image.

JDK 21 allows for optionally building on `oraclelinux:9` by using `Dockerfile.ol9` rather than `Dockerfile.ol8`.

e.g. to build JDK 21 with Oracle Linux 9 rather than the default Oracle Linux 8 run

```bash
cd ../OracleJava/21
docker build --file Dockerfile.ol9 --tag oracle/jdk:11-oraclelinux9 .
```
Server JRE is offered only for x86-64 systems, all other images are offered for x86-64 as well as aarch64.

## Licenses

JDK 24 and 21 are downloaded, as part of the build process, from the [Oracle Website](https://www.oracle.com/javadownload) under the [Oracle No-Fee Terms and Conditions (NFTC)](https://java.com/freeuselicense).

The JDK 17, JDK 11, JDK 8, and Server JRE 8 dockerfiles use Java Runtimes under the  [Oracle Technology Network License Agreement for Oracle Java SE](https://www.java.com/otnlicense)

All scripts and files hosted in this project and GitHub [`docker/OracleJava`](./) repository, required to build the container images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support

Oracle offers support for JDK 24, JDK 21, JDK 17, JDK 11, and JDK 8 (JDK and Server JRE) when running on certified operating systems in a container. For additional details on the JDK Certified System Configurations, please refer to the [Oracle Java SE Certified System Configuration Pages](https://www.oracle.com/technetwork/java/javaseproducts/documentation/index.html#sysconfig).
