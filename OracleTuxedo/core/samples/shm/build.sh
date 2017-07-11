#!/bin/sh
docker build -t oracle/tuxedoshm .

echo "To run the sample, use:"
echo "docker run -d --name tuxedoshm -v \${Local_volumes_dir}/TuxedoVolumes/\${VERSION}:/u01/oracle/user_projects oracle/tuxedoshm /bin/bash"
echo "docker start tuxedoshm; docker attach tuxedoshm"
