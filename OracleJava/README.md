Oracle Java on Containers
=====
This repository contains sample container configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux with JDK images of JDK 16, 15, and 11 and for Server JRE 8.

Oracle Java Server JRE provides the features from Oracle Java JDK commonly required for server-side applications (i.e. Running a Java EE application server). For more information about Server JRE, visit the [Understanding the Server JRE blog entry](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) from the Java Product Management team.

## Building the Oracle Java base image
Download the linux x-64 compressed archive (tar.gz) [JDK or Server JRE](https://www.oracle.com/javadownload) for the version you want to create an image of and place it in the same directory as the corresponding Dockerfile.

e.g. for JDK 16 download jdk-16[X]_linux-x64_bin.tar.gz into OracleJava/16, 
for ServerJRE 8 download server-jre-8uXXX-linux-x64.tar.gz into OracleJava/8

Navigate to the folder containing the download and run `docker build`. Tag it with the correct version number.

e.g. For JDK 16 run
```
$ cd ../OracleJava/16
$ docker build --tag oracle/jdk:16 .
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

The Oracle Java image for JDK 16 uses `oraclelinux:8-slim` as the parent image.

The build script `build.sh` will tag the JDK 16 image as `16` and also as `16-oraclelinux8`.

JDK 15, JDK 11, and ServerJRE 8 use `oraclelinux:7-slim` as the default parent image but allow for optionally building on `oraclelinux:8-slim` by using `Dockerfile.8-slim` rather than `Dockerfile`.

e.g. to build JDK 11 with Oracle Linux 8 rather than the default Oracle Linux 7 run

```
$ cd ../OracleJava/11
$ docker build --file Dockerfile.8-slim --tag oracle/jdk:11-oraclelinux8 .
```
On releases prior to JDK 16 `build.sh` can be used to build on Oracle Linux 7 or on Oracle Linux 8, by passing `8-slim`.

e.g. 

```
$ cd ../OracleJava/11
$ bash build.sh 8-slim
```

## License
To download and run the Oracle JDK or Server JRE, regardless of inside or outside a container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleJava`](./) repository, required to build the container images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
Oracle offers support for JDK 8 (Server JRE), JDK 11, JDK 15, and JDK 16 when running on certified operating systems in a container. For additional details on the JDK Certified System Configurations, please refer to the [Oracle Java SE Certified System Configuration Pages](https://www.oracle.com/technetwork/java/javaseproducts/documentation/index.html#sysconfig).
