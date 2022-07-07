# OCI Comand Line Interface

This image contains the [Oracle Cloud Infrastrcure Comand Line Interface (CLI)](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm).

##  Building the image

This image has no external deppendencies.   It can be built using the standard `docker build` command, as follows:

```
$ docker build -t oracle/oci-cli:latest .
```

## Using the CLI

In order to use the OCI CLI you must first create the OCI Configuration file as documented by https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm.  Once this file exists the user will want to create a container and mount the directory containing this configuration file as follows:

```
$ docker run -it --rm -v $HOME/.oci:/home/oracle/.oci docker.io/oracle/oci-cli:latest
```

Once the container has started the user can run any of the supported OCI CLI commands. 
```
$ oci os ns get
```

## Create an alias

To simplify working with the OCI CLI inside a container, create an alias (or a shell script) so that yoou can access the OCI CLI  as if it were running locally on your machine:

```
$ alias cli="docker run -it -v $HOME/.oci:/home/oracle/.oci docker.io/oracle/oci-cli:latest oci"
$ oci os ns get
```

## Public Domain Dedication
 
This Dockerfile was created by Oracle and has been dedicated to the public domain by Oracle.  The scope of Oracle's public domain dedication is limited to the content of the Dockerfile itself and does not extend to any other content in Docker images that may be created using the Dockerfile. Such Docker images, including any automated builds that are created and made available by Oracle, may contain material that is subject to copyright and other intellectual property rights of Oracle and/or third parties, which is licensed under terms specified in the applicable material and/or in the source code for that material.
