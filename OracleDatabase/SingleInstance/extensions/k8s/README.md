#  Support for Deployment on K8S

Packages the scripts required to run multiple replicas of Oracle Single Instance Database docker image in a Kubernetes cluster.

More information on how to deploy the resulting image using [helm](https://helm.sh/) can be found [here](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/helm-charts/oracle-db/README.md).

## Performing operations that require Database Shutdown/Startup after building k8s extension

To perform operations on the database that require the restart of the database, use the maintenance shutdown/startup scripts, /home/oracle/shutDown.sh and /home/oracle/startUp.sh instead of issuing shutdown immediate and startup commands respectively as the latter would lead to exiting of the pod.