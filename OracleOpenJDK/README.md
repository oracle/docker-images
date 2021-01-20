Oracle Java OpenJDK on Docker
=====
This repository contains sample Docker configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles for Oracle OpenJDK based on Oracle Linux.

## Building the Oracle Java OpenJDK base image
Navigate to the folder containing the Dockerfile and run docker build, tagging the image with the version number:

e.g. for OpenJDK 16 run
```
$ cd ../OracleOpenJDK/16
$ docker build -t oracle/openjdk:16 .
```

This command is already scripted in build.sh so you can alternatively run:
```
$ bash build.sh
```

### Parent image OS version

The Oracle Java images for OpenJDK 16 uses `oraclelinux:8-slim` as the default parent image.

The Oracle Java images for OpenJDK 15 uses `oraclelinux:7-slim` as the default parent image but allow for optionally building on `oraclelinux:8-slim` by using  `Dockerfile.8-slim` rather than `Dockerfile`.

e.g. to build OpenJDK 15 with Oracle Linux 8 rather than the default Oracle Linux 7 run

```
$ cd ../OracleOpenJDK/15
$ docker build --file Dockerfile.8-slim --tag oracle/openjdk:15-oraclelinux8 .
```

The build script on `build.sh` can be used to build with either Oracle Linux 7 or Oracle Linux 8. To build on Oracle Linux 8 pass `8-slim` to the script: 

```
$ cd ../OracleOpenJDK/15
$ bash build.sh 8-slim
```


## License
The OpenJDK compressed archive used by this Dockerfile is available under the [GNU General Public License, version2, with the Classpath Exception](https://openjdk.java.net/legal/gplv2+ce.html), from the [Oracle OpenJDK website](https://jdk.java.net).
Oracle Linux is licensed under the [Oracle Linux End-User License Agreement](https://oss.oracle.com/ol/EULA).

All scripts and files hosted in this project and GitHub [`docker/OracleOpenJDK`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.
