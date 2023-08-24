# Build Extensions

After creating the base image using buildContainerImage.sh, use buildExtensions.sh to build an extended image that will include all features present under the extensions folder.

Once you have created the base image, go into the **extensions** folder and run the **buildExtensions.sh** script:

    [oracle@localhost dockerfiles]$ ./buildExtensions.sh -h

    Usage: buildExtensions.sh -a -x [extensions] -b [base image]  -t [image name] -v [version] [-o] [Docker build option]
    Builds one of more Docker Image Extensions.

    Parameters:
       -a: Build all extensions
       -x: Space separated extensions to build. Defaults to all
           Choose from : patching
       -b: Base image to use
       -v: Base version to extend (example 21.3.0)
       -t: name:tag for the extended image
       -o: passes on Docker build option

## Customizing Prebuilt DB extension

Prebuilt DB container images can be custom built with user provided setup scripts. Currently `sh` and `sql` extensions are supported. Place the custom setup scripts in `/extensions/prebuiltdb/setup` directory before running the `prebuiltdb` extension.
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user. To ensure proper order it is recommended to prefix your scripts with a number. For example `01_users.sql`, `02_permissions.sql`, etc.

LICENSE UPL 1.0

Copyright (c) 2023 Oracle and/or its affiliates. All rights reserved.

The resulting image can be used in the same fashion as the base image.

