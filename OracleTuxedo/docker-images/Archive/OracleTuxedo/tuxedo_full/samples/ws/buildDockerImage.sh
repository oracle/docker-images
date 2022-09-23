#!/bin/sh
docker build -t oracle/tuxedows .

echo "To run the sample, use:"
echo "docker run -d -h tuxhost --name tuxedows -v \${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedows"
