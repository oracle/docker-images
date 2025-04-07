# Oracle Database on Containers

This guide contains details of build files to facilitate installation, configuration, and environment setup of an Oracle Real Application Clusters (Oracle RAC) Oracle Database on Containers for DevOps users. For more information about Oracle Database, see [_Oracle Database Online Documentation_](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

## How to build an Oracle RAC container image and access in your environment

Review the README of the following sections in the order given. After reviewing the README of each section, use the build files, and skip the image or container creation steps that do not match your requirements.

* Review the following points before you proceed to the next sections:
  * Review the [Oracle Container Runtime for Podman documentation](https://docs.oracle.com/en/learn/run-containers-podman/index.html#introduction)
  * To run Oracle RAC on Podman, install and configure the Podman engine on Oracle Linux 8.
  * For the Oracle RAC setup in this document, we have configured the public network on 10.0.20.0/24 and the private network on 192.168.17.0/24 and 192.168.18.0/24.
  * If you plan to use different public and private networks in your environment, then obtain the configuration you need for the following IPs:
    * Public IP address for each OracleRealApplicationClusters container.
    * Private IP address for each OracleRealApplicationClusters container.
    * Virtual IP address for each OracleRealApplicationClusters container.
    * If you have DNS then collect three single client access name (SCAN) addresses for the cluster. For details, see [Installing Oracle Grid Infrastructure Guide](https://docs.oracle.com/en/database/oracle/oracle-database/21/cwlin/index.html).
    * (Optional) Public IP for OracleConnectionManager container.
  * Ensure to have internet connectivity for DNF Package Manager.

## Oracle Restart
Provides Details to create Oracle Database on Oracle Restart. For more details, see [OracleRealApplicationClusters/docs/orestart/README.md](./OracleRealApplicationClusters/docs/orestart/README.md)

## Oracle Real ApplicationClusters

Provides Podman build files to create an Oracle RAC Database container image. For more details, see [OracleRealApplicationClusters/README.md](./OracleRealApplicationClusters/README.md)


## Oracle Real Application Clusters for Developers

Provides Details to create an Oracle RAC Database for a rapid deployment to build CI/CD pipeline.

You need to review `OracleRACDNSServer` and `OracleRACStorageServer` sections, create the images and containers based on your environment configuration before you proceed to `Oracle Real Application Clusters For Developers` section.

* **OracleRACDNSServer Container**

  Provides Podman build files to create a local DNS Server container for Oracle RAC on Podman. This container-based DNS server provides IP addresses and the hostname resolution for the containers on the host. For more details, see [OracleRACDNSServer/README.md](./OracleDNSServer/README.md)

* **OracleRACStorageServer Container**

  Provides Podman build files to create an NFS-based storage server for Oracle RAC. If you do not have a block storage or NAS device for Oracle RAC to store OCR, Voting files and Datafiles, then you can use the Oracle RAC Storage Server Container Image to provide shared storage. For more details, see [OracleRACStorageServer/README.md](./OracleRACStorageServer/README.md)

* **Oracle Real Application Clusters for Developers**  
  Provides Details to create an Oracle RAC Database Container Image for developers. For more details, see [OracleRealApplicationClusters/docs/developers/README.md](./OracleRealApplicationClusters/docs/developers/README.md)