Oracle Java on Docker
=====
This repository contains sample Docker configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux with JDK images of currently supported versions 11 and later and for Server JRE 8.

Oracle Java Server JRE provides the features from Oracle Java JDK commonly required for server-side applications (i.e. Running a Java EE application server). For more information about Server JRE, visit the [Understanding the Server JRE blog entry](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) from the Java Product Management team.

## Building the Oracle Java base image
Download the linux x-64 compressed archive (tar.gz) [JDK or Server JRE](https://www.oracle.com/javadownload) for the version you want to create an image of and place it in the same directory as the corresponding Dockerfile.

e.g. for JDK 15 download jdk-15[X]_linux-x64_bin.tar.gz into OracleJava/15, 
for ServerJRE 8 download server-jre-8uXXX-linux-x64.tar.gz into OracleJava/8

Navigate to the folder containing the download and run docker build. Tag it with the correct version number.

e.g. For JDK 15 run
```
$ cd ../OracleJava/15
$ docker build --tag oracle/jdk:15 .
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

The Oracle Java images for JDK 15 and earlier use `oraclelinux:7-slim` as the default parent image.

It is possible to use `oraclelinux:8-slim` as the parent image by using  `Dockerfile.8-slim` rather than `Dockerfile` with docker build.

e.g. to build JDK 15 with Oracle Linux 8 rather than the default Oracle Linux 7 run

```
$ cd ../OracleJava/15
$ docker build --file Dockerfile.8-slim --tag oracle/jdk:15-oraclelinux8 .
```

The build script on `build.sh` can be used to build with either Oracle Linux 7 or Oracle Linux 8. To build on Oracle Linux 8 pass `8-slim` to the script: 

```
$ bash build.sh 8-slim
```

In the build script, and on the example above, the image on Oracle Linux 8 has been tagged with `15-oraclelinux8`. 

The Dockerfile for creating JDK 16 images, planned to be released in March 2021, will use Oracle Linux 8, rather than Oracle Linux 7 by default.

## License
To download and run the Oracle JDK or Server JRE, regardless of inside or outside a Docker container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleJava`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
Oracle offers support for JDK 8 (Server JRE), JDK 11 and JDK 15 when running on certified operating systems in a Docker container. For additional details on the JDK Certified System Configurations, please refer to the [Oracle Java SE Certified System Configuration Pages](https://www.oracle.com/technetwork/java/javaseproducts/documentation/index.html#sysconfig).
