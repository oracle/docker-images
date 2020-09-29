# PATCH APPLICATION

Applies patches on oracle home. Multiple one-offs can be applied in a single build but only 1 RU can be applied.

Download the release update and one-offs and place them under extensions/patching/patches directory inside subfolders release_update and one_offs respectively.

Once the patches have been placed in the correct directories, use the buildExtensions.sh script to build the extended image with patch support.
