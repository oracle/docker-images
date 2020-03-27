# Oracle Database
[Oracle](http://www.oracle.com)
Oracle Database Server 19c is an industry leading relational database server.

## Getting started

```console
$helm install local/oracle-db
```

## Introduction

The Oracle Database Server Chart contains the Oracle Database Server 19c Enterprise Edition running on Oracle Linux 7. This image contains a default database in a multitenant configuration with one pdb.

For more information on Oracle Database Server 19c refer to http://docs.oracle.com/en/database/

## Prerequisites

- Kubernetes 1.8+
- NFS PV provisioner support from https://github.com/kubernetes-incubator/external-storage/tree/master/nfs
- Using Oracle Database EE Docker image require you to accept terms of service

## Using Oracle  Database EE Docker image
### Accepting the terms of service
From the store.docker.com website accept `Terms of Service` for Oracle Database Enterprise Edition.

### Login to Docker Store
Login to Docker Store with your credentials 

`$ docker login store.docker.com`

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release local/oracle-db
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
| db_sid                               | set database name(ORACLE_SID)              | ORCLCDB                                                    |
| db_pdb                               | set pdb name                               | ORCLPDB1                                                   |
| db_memory                            | SGA and PGA size                           | 2GB                                                        |
| db_domain                            | domain name of database                    | localdomain                                                |
| persistence.enabled                  | Enable Datafiles Persistence               | true                                                       |
| persistence.accessMode               | Datafile mount access mode                 | ReadWriteOnce                                              |
| persistence.size                     | size of persistence storage                | 50g                                                        |
| persistence.storageClass             | Storage Class for PVC                      | oci                                                        |
| imageRegistry                        | image registry to pull db image from       | local                                                      |
| image                                | image to pull                              | database19c:19.3.0                                 |
| imagePullPolicy                      | image pull policy                          | IfNotPresent                                               |
| hcInitialDelay                       | Health Check initial delay(in seconds)     | 300                                                        |
| hctimeout                            | Health Check timeout      (in seconds)     | 10                                                         |
| shutdownTimeout                      | Timeout to wait for graceful shutdown      | 120                                                        |
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

