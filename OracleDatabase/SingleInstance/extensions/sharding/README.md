# The Sharding Extension
The sharding extension is required to build the catalog and shard containers. When
the SingleInstance container image is extended with the **sharding** extension, it downloads the
required scripts from [db-sharding/container-based-sharding-deployment](https://github.com/oracle/db-sharding/tree/master/container-based-sharding-deployment)
repository, and packages them with the SingleInstance container image to form an extended image.

More information on catalog and shard containers can be found at `db-sharding/container-based-sharding-deployment` [README](https://github.com/oracle/db-sharding/blob/master/container-based-sharding-deployment/README.md).