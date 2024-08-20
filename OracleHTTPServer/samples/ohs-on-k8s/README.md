# Running OHS and WebGate in Kubernetes sample
===============================================
This sample provides the instructions and yaml files for you to run Oracle HTTP Server (OHS) and WebGate in Kubernetes. The instance of OHS that is running in the Kubernetes pod/container is a OHS 12.2.1.4 Standalone (w/ Database Client 19c) domain. 

Before running this sample you need an OHS 12.2.1.4 image and a Kubernetes cluster where to run OHS and WebGate containers.


## How to Run
First make sure you have built oracle/ohs:12.2.1.4.0 image.

###Deploying OHS in Kubernetes
 1. Create a namespace for OHS
        "kubectl create namespace ohsns"


2. Create config maps for the Configuration files based on the directory structure above

        "kubectl create cm -n ohsns ohs-config --from-file=ohsConfig/moduleconf"
        "kubectl create cm -n ohsns ohs-httpd --from-file=ohsConfig/httpconf"
        "kubectl create cm -n ohsns ohs-htdocs --from-file=ohsConfig/htdocs"
        "kubectl create cm -n ohsns webgate-config --from-file=config/webgateConf"
        "kubectl create cm -n ohsns webgate-wallet --from-file=ohsConfig/webgateWallet"
        "kubectl create cm -n ohsns ohs-wallet --from-file=config/wallet"

3.  Create a secret for your Registry (if needed)

        "kubectl create secret -n hosts docker-registry regcred --docker-server=<REGISTRY> --docker-username=<REG_USER> --docker-password=<REG_PWD>"

4. Create a secret for OHS domain credentials

Create the secret using the command:

        "kubectl create secret generic ohs-secret -n ohsns --from-literal=username=weblogic --from-literal=password='welcome1'"


5. The yaml file  ohs.yaml is used to deploy the container in Kubernetes.

You need to modify the ohs.yaml file to add the OHS image name, namespace, and wallet name. You might want to make changes to the port numbers to customize them to your environment requirements. 


**Notes:**

**Set DEPLOY_WG to true or false depending on whether webgate is to be deployed.**
**All config Maps have been shown for completeness.  If you do not wish htdocs then remove that configMap, if you are not deploying webgate then remove the webgate config maps, remove maps as appropriate.**
**All config Maps must mount to the directories stated.**
**If you registry is open you do not need the imagePullSecrets.**
**User changeable values:   Ports, and Image.**


6. Create the OHS container using the command:

        "kubectl create -f ohs.yaml"


7. Monitor the container creation using 

        "kubectl get pods -n ohsns"

        "kubectl logs n hosts ohs-domain-<uniqueValue>"


8. Create a kubernetes service (node port) for OHS  ** must there be 1 per pod? **

a) Use ohs_service.yaml to create the service for OHS.
 
The ohs_service.yaml file needs to be changed to add the namespace where the domain will run.  If you made changes to the port numbers in step 5 you need to modify ohs_service.yaml to have the same port numbers.

b) Create the service using the command:

        "kubectl create -f ohs_service.yaml"

c) Validate the service has been created using the command:

        "kubectl get service -n ohsns"


###Updating OHS/Webgate Image
Edit the deployment (created with ohs.yaml)

Change at runtime 

        "kubectl set image deployment/ohs-domain -n ohsns ohs=<new image tag>"

spec:
      containers:
      - name: ohs
        image: <new image tag>

###Scaling OHS/Webgate in Kubernetes
Edit the deployment (created with ohs.yaml)

        "kubectl -n ohsns patch deployment  ohs-domain -p '{"spec": {"replicas": <replica count>}}'"

spec:
  progressDeadlineSeconds: 600
  replicas: <increase replica count>

## Support
Oracle HTTP Server is supported in containers by Oracle.

## Copyright
Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
