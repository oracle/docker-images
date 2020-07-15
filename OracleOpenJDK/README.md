Oracle Java OpenJDK
=====
This repository contains a sample Docker configuration to facilitate installation and environment setup for DevOps users. This project includes a Dockerfile for Oracle OpenJDK 14 based on Oracle Linux.

## Building the Java 14 (OpenJDK) base image

Build it using:

```
$ cd ../OracleOpenJDK/14
$ docker build -t oracle/openjdk:14 .
```

## License
The OpenJDK compressed archive used by this Dockerfile is available under the [GNU General Public License, version2, with the Classpath Exception](https://openjdk.java.net/legal/gplv2+ce.html), from the [Oracle OpenJDK website](https://jdk.java.net).

All scripts and files hosted in this project and GitHub [`docker/OracleOpenJDK`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.
