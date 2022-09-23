#!/bin/sh
docker build -t oracle/tuxedows_svr .

echo "To run the sample, use:"
echo "docker run -d -h tuxhost --name tuxedows_svr -v \${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedows_svr"
