# Example of how to create a patched gsm image

## Pre-requisites

After you build your base Oracle GSM image following the [README.md](../../../container-based-sharding-deployment/README.md?ref_type=heads#building-oracle-globally-distributed-database-container-images) you can create a patched version of it. To build a patched image, you must provide the patch zip files.

**Notes:**

- Some patches require a newer version of `OPatch`, the Oracle Interim Patch Installer utility. Oracle highly recommends that you always update opatch with the new version.
- You can only patch releases 18.10.0 or later using this script.
- The scripts automatically install a newer OPatch version, if provided.

## The patch structure

The scripts used in this example rely on following directory structure:

```text
latest 
   patches
     oracle 
       001 (patch directory)
          pNNNNNN_RRRRRR.zip  (patch zip file)
       002 (optional)
       00N (optional, Nth patch directory)
     opatch
       p6880880*.zip (optional, OPatch zip file)
```

**patches:** The working directory for patch installation.  
**oracle**: The directory containing patches (Release Update) for Oracle Service Manager (Oracle GSM) and Oracle Database  
**001**: The directory containing the patch (Release Update) zip file.  
**00N**: The second, third, ... directory containing the second, third, ... patch zip file.
These directories are useful if you want to install multiple patches at once. The script will go into each of these directories in the numbered order and apply the patches.  
**Important**: It is up to you to guarantee the patch order, if any order is required.

## Installing the patch

- If you have multiple patches that you want to apply at once, then add more subdirectories following the numbering scheme of 002, 003, 004, 005, 00_N_.
- If you have a new version of OPatch, then put the OPatch zip file directly into the patches directory. **Do not change the name of the OPatch zip file**.
- A utility script named `buildPatchedContainerImage.sh` is provided to assist with building the patched image:

  ```bash
  ./buildPatchedContainerImage.sh

  Usage: buildPatchedContainerImage.sh -v [version] -t [image_name:tag] -p [patch version] [-o] [container build option]
  It builds a patched GSM container image

  Parameters:
     -v: version to build
         Choose one of: latest
     -o: passes on container build option
     -p: patch label to be used for the tag

  LICENSE UPL 1.0

  Copyright (c) 2014,2022 Oracle and/or its affiliates.
   ```

- The following is an example of building a patched image using 19.3.0. Note that `BASE_GSM_IMAGE=localhost/oracle/gsm:19.3.0` is set to 19.3.0. You must set BASE_GSM_IMAGE based on your enviornment.

 ```bash
 # ./buildPatchedContainerImage.sh -v 19.3.0 -p 19.25.0  -o '--build-arg BASE_GSM_IMAGE=localhost/oracle/database-rac:19.3.0'
 ```

**Notes**: If you are trying to patch the image on Oracle Linux 8 (OL8) on the PODMAN host, then you must have the  `podman-docker` package installed on your PODMAN host.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates. All rights reserved.
