# Example of how to create an Oracle RAC Database Container Patched Image
=============================================
## Pre-requisites
After you build your base Oracle RAC image following the [README.md](../../../OracleRealApplicationClusters/README.md#building-oracle-rac-database-container-image), it is mandatory to create **Oracle RAC Base image** following [README.md](../../../OracleRealApplicationClusters/README.md#building-oracle-rac-database-container-base-image), then  you can create a patched version of it.
To build a patched image, you must provide the patch zip file.

**Notes:**

* Some patches require a newer version of `OPatch`, the Oracle Interim Patch Installer utility. Oracle highly recommends that you always update opatch with the new version.
* You can only patch releases 19.3.0 or later using this script.
* The scripts automatically install a newer OPatch version, if provided.

## The patch structure

The scripts used in this example rely on following directory structure:

```text
    latest 
       patches
         grid
           001 (patch directory)
              pNNNNNN_RRRRRR.zip  (patch zip file)
           002 (optional)
           00N (optional, Nth patch directory)
         oracle 
           001 (patch directory)
              pNNNNNN_RRRRRR.zip  (patch zip file)
           002 (optional)
           00N (optional, Nth patch directory)
         opatch
           p6880880*.zip (optional, OPatch zip file)
```

**patches:** The working directory for patch installation.
**grid:**: The directory containing patches (Release Update) for Oracle Grid Infrastructure.
**oracle**: The directory containing patches (Release Update) for Oracle Real Application Clusters (Oracle RAC) and Oracle Database
**001**: The directory containing the patch (Release Update) zip file.
**00N**: The second, third, ... directory containing the second, third, ... patch zip file.
These directories are useful if you want to install multiple patches at once. The script will go into each of these directories in the numbered order and apply the patches.
**Important**: It is up to you to guarantee the patch order, if any order is required.

## Installing the patch

* If you have multiple patches that you want to apply at once, then add more subdirectories following the numbering scheme of 002, 003, 004, 005, 00_N_.
* If you have a new version of OPatch, then put the OPatch zip file directly into the patches directory. **Do not change the name of the OPatch zip file**.
* A utility script named `buildPatchedContainerImage.sh` is provided to assist with building the patched image:

   ```bash
     [oracle@localhost applypatch]# ./buildPatchedContainerImage.sh -h
      Usage: buildPatchedContainerImage.sh -v [version] -t [image_name:tag] -p [patch version] [-o] [container build option]
      It builds a container image for RAC patched image

      Parameters:
       -v: version to build
        Choose one of: latest
       -o: passes on container build option
       -p: patch label to be used for the tag
   ```
* The following is an example of building a patched image using 21.3.0. Note that `localhost/oracle/database-rac:21.3.0-base` is created before using [README.md](../../../OracleRealApplicationClusters/README.md#building-oracle-rac-database-container-base-image).

 ```bash
 ./buildPatchedContainerImage.sh -v 21.3.0 -p 21.16.0
 ```

Logs-
```bash
 Oracle Database container image for Real Application Clusters (RAC) version 21.3.0 is ready to be extended:
 
    --> oracle/database-rac:21.3.0-21.16.0
 
  Build completed in 1419 seconds.
```
Once Oracle RAC Patch image is built, lets retag it and it is referenced as 21c in this [README](../../docs/rac-container/racimage/README.md) documentation.
```bash
podman tag localhost/oracle/database-rac:21.3.0-21.16.0 localhost/oracle/database-rac:21c
```

**Important:** It is not supported to apply patches on already existing databases. You must create a new, patched database container image. You can use the PDB unplug/plug functionality to carry over your PDB into the patched container database.

**Notes**: If you are trying to patch the image on Oracle Linux 8 (OL8) on the PODMAN host, then you must have the  `podman-docker` package installed on your PODMAN host.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates. All rights reserved.