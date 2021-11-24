# Pre-built Database (prebuiltdb) Extension

This extension extends [the base Oracle Single Instance Database image](../../README.md) in such a way that the resultant image has a pre-built database. So, when a container is started using this extended image, the start-up time is quite fast. 

The configurable parameters while building this extension are as follows:

- ORACLE_SID
- ORACLE_PDB
- ORACLE_PWD
- ENABLE_ARCHIVELOG

Example command for building this extension is as:

```
./buildExtension.sh -b <base-image> -t <target-image> -x 'prebuiltdb' -o '--build-arg ORACLE_SID=<Database SID> --build-arg ENABLE_ARCHIVELOG=true --build-arg ORACLE_PWD=<database-password>'
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

This extended image has an additional layer containing pre-created database on top of the base image. So, when this image is used to spin-up a container, the startup time is really fast. In other words, this extended image saves the database creation time (~ 10-20 mins).

This extended image would be very useful in CI/CD scenarios, where database would be used for conducting tests, experiments and the workflow is simple.

## Limitations

Some limitations are listed as follows:
- **External volume can not be used** for database persistence (as data files are inside the image itself).
- In Kubernetes environment, **the single replica mode** (i.e. replicas=1) can be used for database deployments.