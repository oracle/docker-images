Oracle Java on Docker
=====
This repository contains sample Docker configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux with JDK images of currently supportes versions 11 and later and for Server JRE 8.

Oracle Java Server JRE provides the features from Oracle Java JDK commonly required for server-side applications (i.e. Running a Java EE application server). For more information about Server JRE, visit the [Understanding the Server JRE blog entry](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) from the Java Product Management team.

## Building the Oracle Java base image
Download the linux x-64 compressed archive (tar.gz) [JDK or Server JRE] (https://www.oracle.com/in/java/technologies/javase-downloads.html) for the version you want to create an image of and place it in the same directory as the corresponding Dockerfile.

e.g. for JDK 14 download jdk-14[X]_linux-x64_bin.tar.gz into OracleJava/14, 
for ServerJRE 8 download server-jre-8uXXX-linux-x64.tar.gz into OracleJava/8

Navigate to the folder containing the downloads and run docker build.  Tag it with the correct version number.

e.g. For JDK 14 run
```
$ docker build -t oracle/jdk:14 .
```

for Server JRE run
```
$ docker build -t oracle/serverjre:8 .
```

The right command with the correct tag is already scripted in build.sh so you can alternatively run:
```
$ bash build.sh
```

## License
To download and run the Oracle JDK or Server JRE, regardless of inside or outside a Docker container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleJava`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
Oracle offers support for JDK 8 (Server JRE), JDK 11, JDK 14 and JDK 15 when running on certified operating systems in a Docker container. For additional details on the JDK Certified System Configurations, please refer to the [Oracle Java SE Certified System Configuration Pages](https://www.oracle.com/technetwork/java/javaseproducts/documentation/index.html#sysconfig).
