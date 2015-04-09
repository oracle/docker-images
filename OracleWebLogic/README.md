WebLogic 10.3.6. on Docker
==========================

1. Create the image.

  cd OracleWebLogic/dockerfiles
  ./buildDockerImage.sh -v 10.3.6 -d

2. Verify the docker image

  docker images

you should see something like this:

  REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
  oracle/weblogic     10.3.6-dev          81f58771358b        2 minutes ago       2.01 GB

3. Installing weblogic 10.3.6 and create another custom image

  cd OracleWeblogic/samples/11g-domain
  docker build -t oracle/weblogic:10.3.6-dev-custom .

4. Verify the docker image

  docker images

you should see something like this:

  REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
  oracle/weblogic     10.3.6-dev-custom   9ffffd180f6c        3 seconds ago       2.011 GB
  oracle/weblogic     10.3.6-dev          81f58771358b        2 minutes ago       2.01 GB


5. Create the container

  docker run --name wlsadmin -d -i oracle/weblogic:10.3.6-dev-custom 

6. Verify that the container is running

  docker ps

you should see something like this:

  CONTAINER ID        IMAGE                               COMMAND              CREATED             STATUS              PORTS                          NAMES
  73a1298ac30c        oracle/weblogic:10.3.6-dev-custom   "startWebLogic.sh"   3 seconds ago       Up 2 seconds        5556/tcp, 7001/tcp, 7002/tcp   wlsadmin 

7. Connect to the container

  docker exec -i -t wlsadmin /bin/bash

