# Example of how to create a patched GSM Image

## Pre-requisites

After you build your base Oracle GSM image following the [README.md](../../README.md#option-2-build-a-gsm-image-from-local-binaries) you can create a patched version of it. To build a patched image, you must provide the patch zip files.

**Notes:**

- Some patches require a newer version of `OPatch`, the Oracle Interim Patch Installer utility. Oracle highly recommends that you always update opatch with the new version.
- You can only patch releases 19.3.0 or later using this script.
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
     -t: user-defined image name and tag
     -o: passes on container build option
     -p: patch label to be used for the tag

  LICENSE UPL 1.0

  Copyright (c) 2014,2022 Oracle and/or its affiliates.
   ```

- The following is an example of building a patched image from 19.3.0 GSM Image created earlier. Note that `localhost/oracle/gsm:19.3.0-base` is created before using [README.md](../../README.md#building-gsm-base-image).

 ```bash
 ./buildPatchedContainerImage.sh -v 19.3.0 -p 19.32.0
 ```

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates. All rights reserved.
