# Oracle Database
[Oracle](http://www.oracle.com)
Database Server 19c is an industry leading relational database server.

## Getting started
A Helm chart is used for packaging the deployment yamls to simplify install in Kubernetes. The chart is available at [charts/oracle-db](./) directory.
Clone the repo and execute the following command to generate oracle-db-1.0.0.tgz
```
$ helm package charts/oracle-db
```

## Introduction

The Oracle Database Server Chart contains the Oracle Database Server 19c running on Oracle Linux 7. This image contains a default database in a multitenant configuration with one pdb.

For more information on Oracle Database Server 19c refer to http://docs.oracle.com/en/database/

## Prerequisites

- Kubernetes 1.12+
- Helm 2.x or 3.x
- NFS PV: https://kubernetes.io/docs/concepts/storage/volumes/#nfs
- Using Oracle Database Docker image requires you to accept terms of service from https://container-registry.oracle.com
- Create image pull secrets
    ``` 
    $ kubectl create secret docker-registry regcred --docker-server=container-registry.oracle.com --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
    ```

## Using Oracle  Database Docker image
### Accepting the terms of service
From the container-registry.oracle.com website accept `Terms of Service` for Oracle Database Enterprise Edition.


## Installing the Chart

To install the chart with the release name `db19c`:

Helm 3.x syntax
```
$ helm install db19c oracle-db-1.0.0.tgz
```
Helm 2.x syntax
```
$ helm install --name db19c oracle-db-1.0.0.tgz
```

The command deploys Oracle Database on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `db19c` deployment:

Helm 3.x syntax
```
$ helm uninstall db19c 
```
Helm 2.x syntax
```
$ helm delete db19c
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
| loadBalService                       | Create a load balancer service instead of NodePort | false                                              |
| image                                | Image to pull                              | container-registry.oracle.com/database/enterprise:19.3.0.0 |
| imagePullPolicy                      | Image pull policy                          | Always                                                     |
| imagePullSecrets                     | container registry login/password          |                                                            |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

Helm 3.x syntax
```
$ helm install db19c --set oracle_sid=ORCL,oracle_pdb=prod oracle-db-1.0.0.tgz
```
Helm 2.x syntax
```
$ helm install --name db19c --set oracle_sid=ORCL,oracle_pdb=prod oracle-db-1.0.0.tgz
```

The above command sets  the Oracle Database name to 'ORCL' and PDB name to 'prod'.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

Helm 3.x syntax
```
$ helm install db19c -f values.yaml oracle-db-1.0.0.tgz
```
Helm 2.x syntax
```
$ helm install --name db19c -f values.yaml oracle-db-1.0.0.tgz
```

> **Tip**: You can use the default [values.yaml](values.yaml)
 

## Persistence

The [Oracle Database](https://www.oracle.com) image stores the Oracle Database data files  and configurations at the `/opt/oracle/oradata` path of the container.

Persistent Volume Claims are used to keep the data across deployments. 
See the [Configuration](#configuration) section to configure the PVC or to disable persistence.

