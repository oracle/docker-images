#!/bin/sh
docker build -t oracle/tuxedoshm .

echo "To run the sample, use:"
echo "docker run -d --name tuxedoshm -v \${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedoshm"
