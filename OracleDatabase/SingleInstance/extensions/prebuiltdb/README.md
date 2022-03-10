# Pre-built Database (prebuiltdb) Extension

This extension extends [the base Oracle Single Instance Database image](../../README.md) in such a way that the resultant image has a pre-built database. So, when a container is started using this extended image, the start-up time is quite fast. 

The configurable parameters while building this extension are as follows:

- ORACLE_SID
- ORACLE_PDB
- ORACLE_PWD
- ENABLE_ARCHIVELOG
- AUTO_MEM_CALCULATION

Example command for building this extension is as:

```
./buildExtensions.sh -b <base-image> -t <target-image> -x 'prebuiltdb' -o '--build-arg ORACLE_SID=<Database SID> --build-arg ENABLE_ARCHIVELOG=true --build-arg ORACLE_PWD=<database-password>'
```

The detailed instructions for building extensions are [here](../README.md).

This extended image can be run as follows:

```
docker run -dt --name <container-name> -p :1521 -p :5500 oracle/database:ext 
```

**NOTE:**
- This extension supports Oracle Single Instance Database container image from version 19.3.0 onwards.
- The user should override 'persistence' to 'null' explicitly while deploying this image on Kubernetes. For example,

```
helm install db21c --set image=<image-url>,persistence=null oracle-db-1.0.0.tgz
```

## Advantages

This extended image includes an already setup database inside the image itself. Although the image size is larger, the startup time of the container includes only the database startup itself, which makes the container startup duration just a couple of seconds.

This extended image would be very useful in CI/CD scenarios, where database would be used for conducting tests, experiments and the workflow is simple.

## Limitations

Some limitations are listed as follows:
- **External volume can not be used** for database persistence (as data files are inside the image itself).
- In Kubernetes environment, **the single replica mode** (i.e. replicas=1) can be used for database deployments.
- The database created will not use more than 2GB of memory.
  - The amount of memory allocated for the database is calculated during creation of the database, which runs during the docker build phase. By default, `AUTO_MEM_CALCULATION` is `false` so that the container built with this extension is portable, but it also means that the database inside of the containers deployed with this image will not use more than 2GB, even if more is available/allocated.
  - If you know the environment where you plan to deploy the container built with this extension, you can build the image with `DOCKER_BUILDKIT=0 docker build --memory=4096m --build-arg AUTO_MEM_CALCULATION=true` so that the database is created with 4GB of memory allocated.
    PS: `DOCKER_BUILDKIT=0` is used because [Docker Buildkit does not currently support the `--memory` option](https://github.com/moby/buildkit/issues/593).
