Example of how to create a patched database image
=============================================
Once you have built your base Oracle RAC image image following the [README.md](../../../OracleRealApplicationClusters/README.md) you can create a patched version of it. In order to build such an image you will have to provide the patch zip file.
 
**Notes:** 
* Some patches require a newer version of `OPatch`, the Oracle Interim Patch Installer utility. It is highly recommended, you always update opatch with the new version. 
* You can only patch 19.3.0 and above using this script. 
* The scripts will automatically install a newer OPatch version, if provided.

# The patch structure
The scripts used in this example rely on following directory structure:

    21.3.0
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
* You need to change the base image to be patched with the RU in `latest/Dockerfile` based on your env. For example, if you want to build 19.3.0 patched images, change the image name in `latest/Dockerfile` as shown below and save the file:
  ```
  vi latest/Dockerfile
  FROM oracle/database-rac:21.3.0
  to
  FROM oracle/database-rac:19.3.0
  ```
* A utility script named `buildPatchedDockerImage.sh` has been provided to assist with building the patched image:
   ```
    [oracle@localhost applypatch]# ./buildPatchedDockerImage.sh -h
    
    Usage: ./buildPatchedDockerImage.sh -v [version] -p [patch label]
    Builds a patched Docker Image for Oracle Database.
    
    Parameters:
       -v: version to build
           Choose one of: 19.3.0
       -p: patch label to be used for the tag
    
    LICENSE UPL 1.0
    
    Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
   ```
**Important:** It is not supported to apply patches on already existing databases. You will have to create a new, patched database Docker image. You can use the PDB unplug/plug functionality to carry over your PDB into the patched container database!

# Copyright
Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
