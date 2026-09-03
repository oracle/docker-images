# The Sharding Extension
The sharding extension is required to build the catalog and shard containers. When
the SingleInstance container image is extended with the **sharding** extension, it downloads the
required scripts from [docker-images/OracleDatabase/GDD/containerfiles](https://github.com/oracle/docker-images/tree/main/OracleDatabase/GDD/containerfiles)
repository, and packages them with the SingleInstance container image to form an extended image.

More information on catalog and shard containers can be found at `docker-images/OracleDatabase/GDD/containerfiles` [README](https://github.com/oracle/docker-images/tree/main/OracleDatabase/GDD/README.md).
