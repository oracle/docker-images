Oracle Java in Containers
=====
This repository contains sample container configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux with JDK images of JDK 17, 11, and for Server JRE 8.

Oracle Java Server JRE provides the features from Oracle Java JDK commonly required for server-side applications (i.e. Running a Java EE application server). For more information about Server JRE, visit the [Understanding the Server JRE blog entry](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) from the Java Product Management team.

## Building the Oracle Java base image
For JDK 17 the required JDK binaries will be downloaded from [Oracle](https://www.oracle.com/javadownload) as part of the build using curl.

For JDK 11 and SererJRE8 you must download the linux x-64 compressed archive (tar.gz) of the [JDK or Server JRE](https://www.oracle.com/javadownload) for the version you want to create an image of and place it in the same directory as the corresponding Dockerfile.

e.g. for JDK 11 download jdk-11[X]_linux-x64_bin.tar.gz into OracleJava/11, 
for ServerJRE 8 download server-jre-8uXXX-linux-x64.tar.gz into OracleJava/8

To build the container image run `docker build`. Tag it with the correct version number.

e.g. For JDK 17 run
```
$ cd ../OracleJava/17
$ docker build --tag oracle/jdk:17 .
```

for Server JRE 8 run
```
$ cd ../OracleJava/8
$ docker build --tag oracle/serverjre:8 .
```

The right command with the correct tag is already scripted in `build.sh` so you can alternatively run:
```
$ bash build.sh
```
### Parent image OS version

The Oracle Java image for JDK 17 uses `oraclelinux:8` as the parent image.
The Oracle Java image for JDK 11 and Server JRE 8 use `oraclelinux:7-slim` as the parent image.

JDK 11 and Server JRE 8 allow for optionally building on `ghcr.io/oracle/oraclelinux8-compat:8-slim` by using `Dockerfile.8` rather than `Dockerfile`.

e.g. to build JDK 11 with Oracle Linux 8 rather than the default Oracle Linux 7 run

```
$ cd ../OracleJava/11
$ docker build --file Dockerfile.8 --tag oracle/jdk:11-oraclelinux8 .
```

On JDK 11 and ServerJRE 8 `build.sh` can be used to build on Oracle Linux 8, by passing `8`.
e.g. 

```
$ cd ../OracleJava/11
$ bash build.sh 8
```
Build scripts `build.sh`will tag the images with the JDK version e.g., '17' and as the version and the operating system version e.g., '17-oraclelinux8'.

## Licenses
JDK 17 is downloaded, as part of the build process, from [Oracle Website](https://www.oracle.com/javadownload) under the [Oracle No-Fee Terms and Conditions (NFTC)](https://java.com/freeuselicense).

For building JDK 11 and Server JRE 8 you must first download the corresponding Java Runtime from the [Oracle Website](https://www.oracle.com/javadownload) and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleJava`](./) repository, required to build the container images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
Oracle offers support for JDK 17, JDK 11, and JDK 8 (Server JRE) when running on certified operating systems in a container. For additional details on the JDK Certified System Configurations, please refer to the [Oracle Java SE Certified System Configuration Pages](https://www.oracle.com/technetwork/java/javaseproducts/documentation/index.html#sysconfig).
