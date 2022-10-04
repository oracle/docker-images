
# Oracle Tuxedo SHM sample container image

This example extends the Oracle Tuxedo image by creating a sample domain.

## How to run

Before building this sample image, ensure you have successfully created the `oracle/tuxedo:latest` image using the documentation in the `core` folder.

To build the sample container image, run:

```shell
docker build -t oracle/tuxedoshm .  
```
or use the `./buildContainerImage.sh` script in this folder.

Next, use the sample image to create a container that runs the sample application with the following command:

```shell
docker run -d -h tuxhost -v ${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoshm
```

You can review the container logs using `docker logs <container_id>`. The `container_id` can be found by running `docker ps`.
