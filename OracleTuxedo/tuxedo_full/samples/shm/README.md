
Tuxedo SHM sample on Docker
===============

Example of Image with Tuxedo Domain

This Dockerfile extends the Oracle Tuxedo image by creating a sample domain.

## How to run
First make sure you have built oracle/tuxedo:12.2.2. Now to build this sample, run:
docker build -t oracle/tuxedoshm .
or
./buildDockerImage.sh

You can then start the image in a new container with:  
docker run -d -h tuxhost -v ${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedoshm 

which will run the sample. You can check the logs from `docker logs <container_id>`, container_id can be checked by `docker ps -a`.

