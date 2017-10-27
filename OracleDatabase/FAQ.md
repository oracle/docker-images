# FAQ: Docker and Oracle Database

## How do I change the timezone of my container
As of Docker 17.06-ce, Docker does not yet provide a way to pass down the TZ Unix environment variable from the host to the container. Because of that all containers run in the UTC timezone. If you would like to have your database run in a different timezone you can pass on the `TZ` environment variable within the `docker run` command via the `-e` option. An example would be: `docker run ... -e TZ="Europe/Vienna" oracle/database:12.2.0.1-ee"

## checkSpace.sh: ERROR - There is not enough space available in the docker container.
This error is thrown when there is no sufficient space available within the Docker container to unzip the install binaries and run the installation of the Oracle database. The Docker container runs the `df` Unix command, meaning that even if you think there should be enough space, there certainly isn't within the container.
