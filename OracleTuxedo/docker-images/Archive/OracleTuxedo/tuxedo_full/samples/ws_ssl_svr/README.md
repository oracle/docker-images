
Tuxedo "ws (workstation) ssl server" sample on Docker
============================================

Example of Image with Tuxedo Domain

This Dockerfile extends the Oracle Tuxedo image by creating a sample ws (workstation) ssl server app.

## How to run
First make sure you have built oracle/tuxedo:latest version from the core directory. Now to build this sample, run:
docker build -t oracle/tuxedows_svr .
or
./buildDockerImage.sh

You can then start the image in a new container with:  
docker run -d -h tuxhost -v ${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedows_svr

which will run the sample. You can check the logs from `docker logs <container_id>`, container_id can be checked by `docker ps -a`.

Push the built docker image into your private or public docker/container registry and then use tuxedows-helm-chart for deploying to kubernetes engine.
