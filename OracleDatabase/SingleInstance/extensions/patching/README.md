# PATCH APPLICATION

Applies patches on oracle home. Multiple one-offs can be applied in a single build but only 1 RU can be applied.

Download the release update and one-offs and place them under extensions/patching/patches directory inside subfolders release_update and one_offs respectively.

Once the patches have been placed in the correct directories, use the buildExtensions.sh script to build the extended image with patch support.

**NOTE**: For patching to work successfully, one should build the base container image by passing one additional build argument `--build-arg SLIMMING=false`. By default, SLIMMING is true to remove some components from the image with the intention of making the image slimmer. These removed components cause problems while patching and  result in unsuccessful patching operation.

Example build command to build the container image:

    ./buildContainerImage.sh -i -e -v 19.3.0 -o '--build-arg SLIMMING=false'
