Example of how to create a patched database image
=============================================

Once you have built your base Oracle RAC image image following the [README.md](../../../OracleRealApplicationClusters/README.md) you can create a patched version of it. In order to build such an image you will have to provide the patch zip file.

**Notes:**

* Some patches require a newer version of `OPatch`, the Oracle Interim Patch Installer utility. It is highly recommended, you always update opatch with the new version.
* You can only patch 19.3.0 and above using this script.
* The scripts will automatically install a newer OPatch version, if provided.

# The patch structure

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
**grid:**: The directory containing patches(Release Update) for Oracle Grid Infrastructure.  
**oracle**: The directory containing patches(Release Update) for Oracle RAC Home and Database  
**001**: The directory containing the patch(Release Update) zip file.  
**00N**: The second, third, ... directory containing the second, third, ... patch zip file.
This is useful if you want to install multiple patches at once. The script will go into each of these directories in the numbered order and apply the patches.  
**Important**: It is up to the user to guarantee the patch order, if any.

# Installing the patch

* If you have multiple patches to be applied at once, add more sub directories following the numbering scheme of 002, 003, 004, 005, 00N.
* If you have a new version of OPatch, put the OPatch zip file directly into the patches directory. Do not change the name of the zip file!
* A utility script named `buildPatchedContainerImage.sh` has been provided to assist with building the patched image:

   ```bash
     [oracle@localhost applypatch]# ./buildPatchedContainerImage.sh -h
      Usage: buildContainerImage.sh -v [version] -t [image_name:tag] -p [patch version] [-o] [container build option]
      It builds a container image for RAC patched image

      Parameters:
       -v: version to build
        Choose one of: latest
       -o: passes on container build option
       -p: patch label to be used for the tag
   ```
* Following is the example of build patched image using 21.3.0. Note that `BASE_RAC_IMAGE=oracle/database-rac:21.3.0` set to 21.30. You need to set BASE_RAC_IMAGE based on your enviornment.

 ```bash
 # ./buildPatchedContainerImage.sh -v 21.3.0 -p 21.7.0 -o '--build-arg BASE_RAC_IMAGE=oracle/database-rac:21.3.0'
 ```

**Important:** It is not supported to apply patches on already existing databases. You will have to create a new, patched database container image. You can use the PDB unplug/plug functionality to carry over your PDB into the patched container database!

**Notes**: If you are trying to patch the image on OL8 on PODMAN host, you must have `podman-docker` package instaled on your PODMAN host.

# Copyright

Copyright (c) 2014-2022 Oracle and/or its affiliates. All rights reserved.
