Oracle Java OpenJDK
=====
This repository contains a sample Docker configuration to facilitate installation and environment setup for DevOps users. This project includes a Dockerfile for Oracle OpenJDK 14 based on Oracle Linux.

## Building the Java 14 (OpenJDK) base image
[Download OpenJDK 14](https://jdk.java.net/14/) `.tar.gz` file and drop it inside the folder `../OracleOpenJDK/14`.

Build it using:

```
$ cd ../OracleOpenJDK/14
$ docker build -t oracle/openjdk:14 .
```

## License
To download and run Oracle OpenJDK you must download the binary, available under the [GNU General Public License, version2, with the Classpath Exception](https://openjdk.java.net/legal/gplv2+ce.html), from the Oracle OpenJDK website.

All scripts and files hosted in this project and GitHub [`docker/OracleOpenJDK`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.
