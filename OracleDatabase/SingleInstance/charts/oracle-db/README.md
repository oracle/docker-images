# Oracle Database
[Oracle](http://www.oracle.com)
Oracle Database Server 19c is an industry leading relational database server.

## Getting started

```console
$helm install oracle-db
```

## Introduction

The Oracle Database Server Chart contains the Oracle Database Server 19c running on Oracle Linux 7. This image contains a default database in a multitenant configuration with one pdb.

For more information on Oracle Database Server 19c refer to http://docs.oracle.com/en/database/

## Prerequisites

- Kubernetes 1.11+
- NFS PV provisioner support from https://github.com/kubernetes-incubator/external-storage/tree/master/nfs
- Using Oracle Database Docker image require you to accept terms of service

## Using Oracle  Database Docker image
### Accepting the terms of service
From the container-registry.oracle.com website accept `Terms of Service` for Oracle Database Enterprise Edition.


## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release oracle-db
```

The command deploys Oracle Database on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the Oracle  Database chart and their default values.

| Parameter                            | Description                                | Default                                                    |
| -------------------------------      | -------------------------------            | ---------------------------------------------------------- |
| oracle_sid                           | Database name (ORACLE_SID)                 | ORCLCDB                                                    |
| oracle_pdb                           | PDB name                                   | ORCLPDB1                                                   |
| oracle_pwd                           | SYS, SYSTEM and PDB_ADMIN password         | Auto generated                                             |
| oracle_characterset                  | The character set to use                   | AL32UTF8                                                   |
| oracle_edition                       | The database edition                       | enterprise                                                 |
| persistence.size                     | Size of persistence storage                | 100g                                                       |
| persistence.storageClass             | Storage Class for PVC                      |                                                            |
| image                                | Image to pull                              | database19c:19.3.0                                         |
| imagePullPolicy                      | Image pull policy                          | IfNotPresent                                               |
| -------------------------------      | -------------------------------            | ---------------------------------------------------------- |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install --name my-release --set db_sid=ORCL,db_pdb=prod  local/oracle-db
```

The above command sets  the Oracle Database name to 'ORCL' and PDB name to 'prod'.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install --name my-release -f values.yaml local/oracle-db
```

> **Tip**: You can use the default [values.yaml](values.yaml)
 

## Persistence

The [Oracle Database](https://www.oracle.com) image stores the Oracle Database data files  and configurations at the `/ORCL` path of the container.

Persistent Volume Claims are used to keep the data across deployments. 
See the [Configuration](#configuration) section to configure the PVC or to disable persistence.

