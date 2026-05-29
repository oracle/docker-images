# Oracle Database on Docker
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

## SingleInstance
Provides Docker build files to create an Oracle Database Single Instance Docker image. For more details, see [SingleInstance/README.md](./SingleInstance/README.md).

## Oracle Sharding
Provides Docker build files to deploy Oracle Globally Distributed Database using containers. For more details, see [oracle/docker-images/OracleDatabase/GDD](https://github.com/oracle/docker-images/tree/main/OracleDatabase/GDD).

## RAC
Provides Podman build files to create an Oracle RAC Database podman image. For more details, see [RAC/README.md](./RAC/README.md).

## OracleConnectionManager

Provides container build files to create an Oracle Connection Manager container image. If you are planing to run RAC containers on single host and RAC containers IPs are not accessible on your network, you can use connection manager image to access RAC database on your network. For more details, see [OracleConnectionManager/README.md](./OracleConnectionManager/README.md)
