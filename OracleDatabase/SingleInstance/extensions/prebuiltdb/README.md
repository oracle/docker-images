# Pre-built Database Extension

This extension creates an additional layer having a pre-built database on top of the [base Oracle SingleInstance Database image](../../README.md).

The cofigurable parameters while building this extension are as follows:

- ORACLE_SID
- ORACLE_PDB
- ORACLE_PWD
- ENABLE_ARCHIVELOG

Example command for building this extension is as:

```
./buildExtension.sh -b <base-image> -t <target-image> -o '--build-arg ORACLE_SID=<Database SID> --build-arg ENABLE_ARCHIVELOG=true --build-arg ORACLE_PWD=<database-password>'
```

The detailed instructions for building extensions are [here](../README.md).

This extended image can be run as follows:

```
docker run -dt --name <container-name> -p :1521 -p :5500 oracle/database:ext 
```

**NOTE:**
This extension is supported SingleInstance Datbase 19.3.0 onwards.

## Advantages

The image which is created after building this extension has a pre-created database. So, when this image is used to spin-up a container, the startup time is really fast. In other words, this extended image saves the database creation time (~ 10-20 mins).

This extended image would be very useful in CI/CD scenarios, where database would be used for conducting tests, experiments and the workflow is simple.

## Limitations

Some limitations of this are as follows:
- Can not use external volume for database persistence (as datafiles are inside the image itself).
- In Kubernetes environment, the container can run only in single replica mode using this extended image.