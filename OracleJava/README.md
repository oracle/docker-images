Oracle Java on Docker
=====
This repository contains sample Docker configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux for all the currently available Oracle JDK's and Server JRE 8.

Oracle Java Server JRE provides the features from Oracle Java JDK commonly required for server-side applications (i.e. Running a Java EE application server). For more information about Server JRE, visit the [Understanding the Server JRE blog entry](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) from the Java Product Management team.

## Building the Oracle Java base image
[Download JDK or Server JRE](https://www.oracle.com/in/java/technologies/javase-downloads.html) file as per your requirement from [Oracle Technical Resources](https://www.oracle.com/in/technical-resources/) and place it in the same directory as the Dockerfile.

Navigate to the folder containing the downloads and run:
```
$ docker build -t oracle/jdk:xx .
```
for JDK's and
```
$ docker build -t oracle/serverjre:8 .
```
for Server JRE.

This command is already scripted in build.sh so you can alternatively run:
```
$ bash build.sh
```

## License
To download and run the Oracle JDK or Server JRE, regardless of inside or outside a Docker container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleJava`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
We support JDK 8 (Server JRE), JDK 11, JDK 14 and JDK 15 when running on certified operating systems in a Docker container. For additional details on the JDK Certified System Configurations, please refer to the [Oracle Java SE Certified System Configuration Pages](https://www.oracle.com/technetwork/java/javaseproducts/documentation/index.html#sysconfig).
