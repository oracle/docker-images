#!/bin/sh
docker build -t oracle/tuxedoshm .

echo "To run the sample, use:"
echo "docker run -ti -v \${Local_volumes_dir}/TuxedoVolumes/\${VERSION}:/u01/oracle/user_projects oracle/tuxedoshm /bin/bash"
