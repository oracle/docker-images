# FAQ: Docker and Oracle Database

## Can I use setup or startup scripts with the Oracle Database image pulled from the Oracle Container Registry or Docker Hub?
Unfortunately, no. 

Unlike the other pre-built images published by Oracle on both the [Oracle Container Registry](https://container-registry.oracle.com) and [Docker Hub](https://hub.docker.com/search?q=oracle&type=image&image_filter=store), the Oracle Database 12c R2 Standard Edition 2 and Enterprise Edition images are not based on any of the Dockerfiles contained in this repository. If you require the runtime functionality documented in this repository, you will need to build an image from the appropriate Dockerfile. 

You can review the documentation for the published [Oracle Database 12c R2 Standard Edition 2](https://container-registry.oracle.com/pls/apex/f?p=113:4:115514266578664::NO:4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:8,8,Oracle%20Database%20Standard%20Edition%202,Oracle%20Database%20Standard%20Edition%202,1,0&cs=3M7OZKUYUdXrhRcqDYvjcNMWxeKHvx6UsXuvffUQ_Jzxp3L23ABb0HfUj6WwrUFwCIOcQQJi9fvA5cNYNtaZTkw) and [Oracle Database 12c R2 Enterprise Edition](https://container-registry.oracle.com/pls/apex/f?p=113:4:115514266578664::NO:4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:9,9,Oracle%20Database%20Enterprise%20Edition,Oracle%20Database%20Enterprise%20Edition,1,0&cs=3lBoxWZ5InuJuWk8u1uRtc6CDKy3bKfdwUFF4uxS8sl3_E5PEGVWIZxntjcUezVRaePRKf3M8vTVdZifwndd37g) images on the Oracle Container Registry. Reviewing the documentation does not require an Oracle Single Sign-on account.


## How do I change the timezone of my container
As of Docker 17.06-ce, Docker does not yet provide a way to pass down the `TZ` Unix environment variable from the host to the container. Because of that all containers run in the UTC timezone. If you would like to have your database run in a different timezone you can pass on the `TZ` environment variable within the `docker run` command via the `-e` option. An example would be: `docker run ... -e TZ="Europe/Vienna" oracle/database:12.2.0.1-ee`. Another option would be to specify two read-only volume mounts: `docker run ... -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro oracle/database:12.2.0.1-ee`. This will synchronize the timezone of the the container with that of the Docker host.

## checkSpace.sh: ERROR - There is not enough space available in the docker container.
This error is thrown when there is no sufficient space available within the Docker container to unzip the install binaries and run the installation of the Oracle database. The Docker container runs the `df` Unix command, meaning that even if you think there should be enough space, there certainly isn't within the container.  

Please make sure that you have enough space available. If you use a storage diver such as `overlay2`, make sure that the output of `docker info` shows a `Base Device Size:` that is bigger than the required space. If not, please change the Base Device Size via the `--storage-opt dm.basesize=` option for the Docker daemon, see [this thread on Docker forums](https://forums.docker.com/t/increase-container-volume-disk-size/1652/4) for more information on that. **Note: You will have to delete all images afterwards to make sure that they new setting is picked up!**

## Error: The container doesn't have enough memory allocated. A database XE container needs at least 1 GB of shared memory (/dev/shm).
The default size for `/dev/shm` is only 64 KB. In order to increase it you have to pass on the `--shm-size` option to the `docker run` command. For example: `docker run ... --shm-size=1g oracle/database:11.2.0.2-xe`

## Image build: unzip error: invalid compressed data to inflate
CRC errors by the Unix unzip command during image build can be caused by a lack of sufficient memory for your container. On macOS X it has been proven that running Docker with only 2GB of RAM will cause this error. Increasing the RAM for Docker to 4GB remedies the situation.

## "Cannot create directory" error when using volumes
This is a Unix filesystem permission issue. Docker by default will map the `uid` inside the container to the outside world. The `uid` for the `oracle` user inside the container is `54321` and therefore all files are created with this `uid`. If you happen to have your volume pointed at a location outside there container where this `uid` doesn't have any permissions for, the container can't write to it and therefore the database files creation fails. There are several remedies for this situation:  
* Use named volumes
* Change the ownership of your folder to `54321`
* Change the permissions of your folder so that the `uid 54321` has write permissions

## ORA-00600: internal error code, arguments: [pesldl03_MMap: errno 1 errmsg Operation not permitted], [], [], [], [], [], [], [], [], [], [], []
This error happens if you try to use native compilation for PL/SQL but haven't assigned `exec` rights to `/dev/shm`.
For example, the below would raise the error in such case:
```
alter session set plsql_code_type='NATIVE';

create or replace procedure test as
begin
   null;
end;
/
```
Docker, by default, doesn't assign `exec` rights to `/dev/shm` which is where the native compiled code is stored and executed.
As you don't have execution rights to it, however, you get the error `Operation not permitted`.

Run the container with `-v /dev/shm --tmpfs /dev/shm:rw,exec,size=<yoursize>` instead, the important part being the `exec` in `--tmpfs /dev/shm:rw,exec,size=<yoursize>`.
Also make sure you assign an appropriate size as the default Docker uses is only 64MB. Assigning 1GB or  more is recommended.

