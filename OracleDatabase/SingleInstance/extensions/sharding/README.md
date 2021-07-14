# Sharding Extension
Sharding extension is required to build the catalog and shard containers. When
the SIDB container image is extended with **sharding** extension, it downloads the 
required scripts from [db-sharding/docker-based-sharding-deployment/dockerfiles/19.3.0/scripts](https://github.com/oracle/db-sharding/tree/master/docker-based-sharding-deployment/dockerfiles/19.3.0/scripts)
and package them with the SIDB container image to form extended image.

More information on catalog and shard containers can be found at `db-sharding/docker-based-sharding-deployment` [README](https://github.com/oracle/db-sharding/blob/master/docker-based-sharding-deployment/README.md).