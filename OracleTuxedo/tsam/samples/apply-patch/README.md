Applying Rolling Patch to the Base Image
===============
This sample offers Dockerfile for building Docker image with the Oracle TSAM 12.2.2 rolling patch applied.

## Dependencies
This sample is based on the [oracle/tsam:12.2.2](../../dockerfiles/12.2.2/Dockerfile) base image. So, before you proceed to build this image, make sure the image `oracle/tsam:12.2.2` has been built locally or is accessible in a remote Docker registry.

To build this image, the rolling patch package should be downloaded from [My Oracle Support](https://support.oracle.com) and put into the same directory as the Dockerfile.

The latest rolling patch is always recommended, while you can actually use any patch level. The downloaded file name should be in the format of `p*_12220_Linux-x86-64.zip`, for example, the TSAM 12.2.2 [RP004](https://updates.oracle.com/Orion/Services/download/p25530287_12220_Linux-x86-64.zip?aru=21140450&patch_file=p25530287_12220_Linux-x86-64.zip) file is `p25530287_12220_Linux-x86-64.zip`.

## Building the Image
Once you have put the patch package in place, run below command to build:

```bash
docker build -t oracle/tsam:12.2.2.1 .
```

> It is recommended to give read permission to all users on the downloaded binary files before building the image. Otherwise the resulting image will most probably get 50M larger.

## Running Oracle TSAM Plus in a Docker container
Nothing has changed to use this image from running the base image. Please refer to the [README](../../README.md) file in the root directory for detail.

## Copyright
Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.

