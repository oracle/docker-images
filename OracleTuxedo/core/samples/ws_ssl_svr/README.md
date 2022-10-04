
# Oracle Tuxedo workstation (WS) SSL server sample container image

This example extends the Oracle Tuxedo image by creating a sample workstation (WS) SSL server application.

## How to run

Before building this sample image, ensure you have successfully created the `oracle/tuxedo:latest` image using the documentation in the `core` folder.

To build the sample container image, run:

```shell
docker build -t oracle/tuxedows_svr .  
```
or use the `./buildContainerImage.sh` script in this folder.

Next, use the sample image to create a container that runs the sample application with the following command:

```shell
docker run -d -h tuxhost -v ${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedows_svr
```

You can review the container logs using `docker logs <container_id>`. The `container_id` can be found by running `docker ps`.

Push this container image to a private container registry and use `tuxedows-helm-chart` from the [Oracle Helm Charts](https://github.com/oracle/helm-charts) repository to deploy this Tuxedo WS SSL server sample to a Kubernetes cluster.
