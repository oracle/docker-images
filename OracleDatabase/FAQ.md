# FAQ: Docker and Oracle Database

## How do I change the timezone of my container
As of Docker 17.06-ce, Docker does not yet provide a way to pass down the `TZ` Unix environment variable from the host to the container. Because of that all containers run in the UTC timezone. If you would like to have your database run in a different timezone you can pass on the `TZ` environment variable within the `docker run` command via the `-e` option. An example would be: `docker run ... -e TZ="Europe/Vienna" oracle/database:12.2.0.1-ee"`

## checkSpace.sh: ERROR - There is not enough space available in the docker container.
This error is thrown when there is no sufficient space available within the Docker container to unzip the install binaries and run the installation of the Oracle database. The Docker container runs the `df` Unix command, meaning that even if you think there should be enough space, there certainly isn't within the container.  

Please make sure that you have enough space available. If you use a storage diver such as `overlay2`, make sure that the output of `docker info` shows a `Base Device Size:` that is bigger than the required space. If not, please change the Base Device Size via the `--storage-opt dm.basesize=` option for the Docker daemon, see [this thread on Docker forums](https://forums.docker.com/t/increase-container-volume-disk-size/1652/4) for more information on that. **Note: You will have to delete all images afterwards to make sure that they new setting is picked up!**

## Error: The container doesn't have enough memory allocated. A database XE container needs at least 1 GB of shared memory (/dev/shm).
The default size for `/dev/shm` is only 64 KB. In order to increase it you have to pass on the `--shm-size` option to the `docker run` command. For example: `docker run ... --shm-size=1g oracle/database:11.2.0.2-xe`

## Image build: unzip error: invalid compressed data to inflate
CRC errors by the Unix unzip command during image build can be caused by a lack of sufficient memory for your container. On macOS X it has been proven that running Docker with only 2GB of RAM will cause this error. Increasing the RAM for Docker to 4GB remedies the situation.

## "Cannot create directory" error when using volumes
This is a Unix filesystem permission issue. Docker by default will map the `uid` inside the container to the outside world. The `uid` for the `oracle` user inside the container is `54321` and therefore all files are created with this uid. If you happen to have your volume pointed at a location outside there container where this `uid` doesn't have any permissions for, the contianer can't write to it and therefore the database files creation fails. There are several remedies for this situation:  
* Use named volumes
* Change the ownership of your folder to `54321`
* Change the permissions of your folder so that the `uid 54321` has write permissions