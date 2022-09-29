
# Tuxedo "ws (workstation) ssl server" sample with container image

Example of Image with Tuxedo Domain

This Dockerfile extends the Oracle Tuxedo image by creating a sample ws (workstation) ssl server app.

## How to run

First make sure you have built oracle/tuxedo:latest version from the core directory.  

Now to build this sample, run:  
docker build -t oracle/tuxedows_svr .  
or  
./buildContainerImage.sh

You can then start the image and run the sample in a new container using the below command:  
docker run -d -h tuxhost -v ${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedows_svr

You can check the logs from `docker logs <container_id>`, container_id can be checked by `docker ps -a`.

Push the built container image into your private or public container registry and then use tuxedows-helm-chart in [Oracle Tuxedo Helm Charts](https://github.com/oracle/helm-charts) for deploying to kubernetes engine.
