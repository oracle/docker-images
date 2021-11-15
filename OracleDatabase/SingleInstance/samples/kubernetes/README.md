Example of Kubernetes deployment
===========================================================

This example will describe how to deploy the Oracle Database image using native Kubernetes objects. 
It's not intended for production use as the values used are not necessarily appropriate. 

# Configuration
This example YAML file will create:
* A namespace _example-namespace_ to hold all objects
* A ConfigMap _oracle-rdbms-config_ that describes database initialization settings (characterset, name, etc)
* A PersistantVolumeClaim _oracle-rdbms-oradata_ that will hold the database files
* A Deployment _oracle-rdbms_ that starts a container with the settings from _oracle-rdbms-config_ using the 
    volume _oracle-rdbms-oradata_ and ensures it remains running
* A Service _database_ that directs traffic flow into the database container

Some key values customizable values:
* _oracle-rdbms_
  * image: "local-repo.com/oracle/database:19.3.0-ee"
  * livenessProbe.initialDelaySeconds: 300               # In seconds, this is five minutes
* _oracle-rdbms-config_
  * ORACLE_CHARACTERSET: "AL32UTF8"
  * ORACLE_EDITION: "enterprise"
  * ORACLE_SID: "ORCLCDB"
  * ORACLE_PDB: "ORCLPDB1"
* _oracle-rdbms-oradata_
  * storage: 10Gb

You **must** change the image path to match your local image registry. 

The livenessProbe will restart a container if it is not ready within the timeout, development systems may 
    require more time and this should be adjusted accordingly.

# Deployment

1. Deploy the objects
    ```
    $ kubectl apply -f kubernetes-example.yaml
    namespace/example-namespace created
    persistentvolumeclaim/oracle-rdbms-oradata created
    configmap/oracle-rdbms-config created
    deployment.apps/oracle-rdbms created
    service/database created   
    ```

1. Create a password

   Define your own password or generate one as in the example
    ```
    $ PASS=$(head /dev/urandom | tr -dc [:alnum:][:graph:] | head -c15) 
    $ kubectl create secret generic oracle-rdbms-credentials --namespace example-namespace \
                            --from-literal=ORACLE_PWD="$PASS" 
    secret/oracle-rdbms-credentials created
    ```

# Testing

1. Observe the status of the system

    ```
    $ kubectl get all
    NAME                                READY   STATUS    RESTARTS   AGE
    pod/oracle-rdbms-68ccc67545-6g5sb   1/1     Running   0          15m
    
    NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    service/database   ClusterIP   10.111.69.145   <none>        1521/TCP   15m
    
    NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/oracle-rdbms   1/1     1            1           15m
    
    NAME                                      DESIRED   CURRENT   READY   AGE
    replicaset.apps/oracle-rdbms-68ccc67545   1         1         1       15m
    ```
1. Get the password of the SYS user
    ```aidl
    $ kubectl get secret --namespace example-namespace oracle-rdbms-credentials \
                         -o jsonpath={.data.ORACLE_PWD} | base64 --decode; echo
    ```

1. Create a new database client container within the same namespace. This will talk to the database
    via the Kubernetes Service named _database_.

    Replace `local-repo.com/oracle/instantclient:19` with the image path in your local image registry.

    ```
     kubectl run --namespace example-namespace \
                 -i --tty --generator=run-pod/v1 temporary \
                 --image=local-repo.com/oracle/instantclient:19 \
                 -- sh
    If you don't see a command prompt, try pressing enter.
    sh-4.2# 
    sh-4.2# sqlplus sys@//database/ORCLCDB as SYSDBA
    
    SQL*Plus: Release 19.0.0.0.0 - Production on Thu Aug 6 23:33:32 2020
    Version 19.6.0.0.0
    
    Copyright (c) 1982, 2019, Oracle.  All rights reserved.
    
    Enter password: 
    
    Connected to:
    Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
    Version 19.3.0.0.0
    
    SQL> SHOW CON_NAME
    
    CON_NAME
    ------------------------------
    CDB$ROOT
    SQL> COLUMN NAME FORMAT A15
    SQL> SELECT NAME, CON_ID FROM V$CONTAINERS;
    
    NAME		    CON_ID
    --------------- ----------
    CDB$ROOT		 1
    PDB$SEED		 2
    ORCLPDB1		 3

    
    SQL> exit
    Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
    Version 19.3.0.0.0
    
    sh-4.2# sqlplus sys@//database/ORCLPDB1 as SYSDBA
    
    SQL*Plus: Release 19.0.0.0.0 - Production on Thu Aug 6 23:31:52 2020
    Version 19.6.0.0.0
    
    Copyright (c) 1982, 2019, Oracle.  All rights reserved.
    
    Enter password: 
    
    Connected to:
    Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
    Version 19.3.0.0.0
    
    SQL> SHOW CON_NAME
    
    CON_NAME
    ------------------------------
    ORCLPDB1
    SQL> exit
    Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
    Version 19.3.0.0.0
    sh-4.2# exit
    Session ended, resume using 'kubectl attach temporary -c temporary -i -t' command when the pod is running
    $ kubectl delete pod temporary
    pod "temporary" deleted
    ```
   
# Removal
    
1. Delete all example objects

    ```
    $ kubectl delete -f kubernetes-example.yaml
    namespace "example-namespace" deleted
    persistentvolumeclaim "oracle-rdbms-oradata" deleted
    configmap "oracle-rdbms-config" deleted
    deployment.apps "oracle-rdbms" deleted
    service "database" deleted
    ```   