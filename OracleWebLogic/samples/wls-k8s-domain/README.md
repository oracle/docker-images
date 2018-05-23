WebLogic Sample on Kubernetes with Shared Domain Home
=========================================
This sample extends the Oracle WebLogic developer install image by creating a sample WLS 12.2.1.3 domain and cluster to run in Kubernetes. The WebLogic domain consists of an Admininstrator Server and several Managed Servers running in a WebLogic cluster. All WebLogic servers share the same domain home which has been mapped to an external volume.

## Prerequisites
1. You need to have a Kubernetes cluster up and running with kubectl installed.
2. You have built oracle/weblogic:12.2.1.3-developer image locally based on Dockerfile and scripts here: https://github.com/oracle/docker-images/tree/master/OracleWebLogic/dockerfiles/12.2.1.3/
3. Username/password for the WebLogic domain are stored in k8s/secrets.yml and they are encoded by base64. The default values are weblogic/weblogic1.  
If you want to customize it, first get the encoded data of your username/password via running `echo -n <username> | base64` and `echo -n <password> | base64`. Next upate k8s/secrets.yml with the new encoded data.

## How to Build and Run

### 1. Build the WebLogic Image for This Sample Domain
Build the image:
```
$ docker build -t wls-k8s-domain .
```
If you run `docker build` behind a proxy, you need to set proxy settings via `--build-arg`.

### 2. Prepare Volume Directories
Three volumes are defined in `k8s/pv.yml` which refer to three external directories. You can choose to use host paths or shared NFS directories. Please change the paths accordingly. The external directories need to be initially empty.

**NOTE:** The first two persistent volumes `pv1` and `pv2` will be used by WebLogic server pods. All processes in WebLogic server pods are running with UID 1000 and GID 1000 by default, so proper permissions need to be set to these two external directories to make sure that UID 1000 or GID 1000 have permission to read and write the volume directories. The third persistent volume `pv3` is reserved for later use. We assume that root user will be used to access this volume so no particular permission need to be set to the directory.  

### 3. Deploy All the Kubernetes Resources

Run the following commands to deploy the Kubernetes resources:
```
$ kubectl create -f  k8s/secrets.yml
$ kubectl create -f  k8s/pv.yml
$ kubectl create -f  k8s/pvc.yml
$ kubectl create -f  k8s/wls-admin.yml
$ kubectl create -f  k8s/wls-stateful.yml
```

### 4. Check Resources Deployed to Kubernetes
#### 4.1 Check Pods and Controllers
List all pods and controllers:
```
$ kubectl get all
NAME                               READY     STATUS    RESTARTS   AGE
po/admin-server-1238998015-f932w   1/1       Running   0          11m
po/managed-server-0                1/1       Running   0          11m
po/managed-server-1                1/1       Running   0          8m

NAME                CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
svc/admin-server    10.102.160.123   <nodes>       8001:30007/TCP   11m
svc/kubernetes      10.96.0.1        <none>        443/TCP          39d
svc/wls-service     10.96.37.152     <nodes>       8011:30009/TCP   11m
svc/wls-subdomain   None             <none>        8011/TCP         11m

NAME                          DESIRED   CURRENT   AGE
statefulsets/managed-server   2         2         11m

NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/admin-server   1         1         1            1           11m

NAME                         DESIRED   CURRENT   READY     AGE
rs/admin-server-1238998015   1         1         1         11m

```

#### 4.2 Check PV and PVC
List all pv and pvc:
```
$ kubectl get pv
NAME      CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS      CLAIM                    STORAGECLASS   REASON    AGE
pv1       10Gi       RWX           Recycle         Available                            manual                   17m
pv2       10Gi       RWX           Recycle         Bound       default/wlserver-pvc-1   manual                   17m
pv3       10Gi       RWX           Recycle         Bound       default/wlserver-pvc-2   manual                   17m

$ kubectl get pvc
NAME             STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
wlserver-pvc-1   Bound     pv2       10Gi       RWX           manual         18m
wlserver-pvc-2   Bound     pv3       10Gi       RWX           manual         18m
```

#### 4.3 Check Secrets
List all secrets:
```
$ kubectl get secrets
NAME                  TYPE                                  DATA      AGE
default-token-m93m1   kubernetes.io/service-account-token   3         39d
wlsecret              Opaque                                2         19m
```

### 5. Check Weblogic Server Status via Administrator Console
The admin console URL is 'http://[hostIP]:30007/console'.

### 6. Troubleshooting
You can trace WebLogic server output and logs for troubleshooting.

Trace WebLogic server output. Note you need to replace $serverPod with the actual pod name.
```
$ kubectl logs -f $serverPod
```
You can look at the WebLogic server logs by running:
```
$ kubectl exec managed-server-0 -- tail -f /u01/wlsdomain/servers/managed-server-0/logs/managed-server-0.log
$ kubectl exec managed-server-0 -- tail -f /u01/wlsdomain/servers/managed-server-1/logs/managed-server-1.log
$ kubectl exec managed-server-0 -- tail -f /u01/wlsdomain/servers/AdminServer/logs/AdminServer.log
```

### 7. Restart Pods
You may need to restart some or all of the WebLogic Server pods, for instance, you make some configuration change which can not be applied dynamically.

#### 7.1 Shutdown the Managed Servers' Pods Gracefully
```
$ kubectl exec -it managed-server-0 -- /u01/wlsdomain/bin/stopManagedWebLogic.sh managed-server-0 t3://admin-server:8001
$ kubectl exec -it managed-server-1 -- /u01/wlsdomain/bin/stopManagedWebLogic.sh managed-server-1 t3://admin-server:8001
```
#### 7.2 Shutdown the Administrator Server Pod Gracefully
First gracefully shutdown admin server process. Note that you need to replace $adminPod with the real admin server pod name.
```
$ kubectl exec -it $adminPod -- /u01/wlsdomain/bin/stopWebLogic.sh <username> <password> t3://localhost:8001
```
Next manually delete the admin pod.
```
$ kubectl delete pod/$adminPod
```
After the pods are stopped, each pod's corresponding controller is responsible for restarting the pods automatically.
Wait until all pods are running and ready again. Monitor status of pods via `kubectl get pod`.

### 8. Cleanup
Remove all resources from your Kubernetes cluster by running:
```
$ kubectl delete -f k8s/wls-stateful.yml
$ kubectl delete -f k8s/wls-admin.yml
$ kubectl delete -f k8s/pvc.yml
$ kubectl delete -f k8s/pv.yml
$ kubectl delete -f k8s/secrets.yml
```
You can now delete all of data generated to the external directories.
## COPYRIGHT
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
