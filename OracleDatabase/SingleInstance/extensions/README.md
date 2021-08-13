# Build Extensions

After creating the base image using buildDockerImage.sh, use buildExtensions.sh to build an extended image that will include all features present under the extensions folder.

Once you have created the base image, go into the **extensions** folder and run the **buildExtensions.sh** script:

    [oracle@localhost dockerfiles]$ ./buildExtensions.sh -h

    Usage: buildExtensions.sh -a -x [extensions] -b [base image]  -t [image name] [-o] [Docker build option]
    Builds one of more Docker Image Extensions.

    Parameters:
       -a: Build all extensions
       -x: Space separated extensions to build. Defaults to all
           Choose from : patching
       -b: Base image to use
       -t: name:tag for the extended image
       -o: passes on Docker build option

LICENSE UPL 1.0

Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.

The resulting image can be used in the same fashion as the base image.