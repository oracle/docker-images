WebLogic on Kubernetes Sample
=========================================
This Example demonstrates the orchestration of a WebLogic 12.2.1.3 domain cluster in a Kubernetes environment. We run through different scaling action of the WebLogic cluster in K8s:
	1- Scale/shrink  the cluster by increasing/decreasing the number of ReplicaSet.
	2- Define a WLDF policy base on Open Session Count MBean and allow the WLS Admin Server initiate the scaling action.

We use StatefulSets to define the WebLogic servers in the domain, this provides a consistent way of assigning managed server names and of giving managed servers in a WebLogic cluster consistent visibility to each other through well-known DNS names.  

There are 2 applications deployed to the WebLogic cluster, the Open Session application which will trigger the WLDF policy to scale the cluster by one managed server.  The Memory Load application which allocates heap memory in the JVM.

When the WLDF policy is triggered it makes a call into a Webhook who is running in a container in the same pod as the Admin Server.  The webhook invokes a K8s API to trigger K8s to scale the K8s cluster and thus scale the WebLogic cluster.

As part of this sample we have developed a WLS Exporter which formats the WLS Runtime  MBean  metrics collected from the Managed Servers and exposes them into a format that can be read by Prometheus and displayed in a Grafana UI.

##How to Build and Run

**NOTE:** Our instructions are based on running this sample in Minikube but it will run on any Kubernetes environment. Make sure you have minikube installed, and have built **oracle/weblogic:12.2.1.3-developer**.

1. Build the WebLogic 12.2.1.3 domain image in this sample:

   ```
    $ cd wls-12213-domain
    $ docker build --build-arg ADMIN_PASS=<Admin Password> --build-arg ADMIN_USER=<Admin Username> -t wls-12213-domain .
   ```

2.  Deploy the Open Session webapp and the Memory Load webapp to the cluster.  Create wls-12213-oow-demo-domain image:
    ```
    $ docker build -t wls-12213-oow-demo-domain -f Dockerfile.adddemoapps .
    ```

3.  Create the Webhook image which is used to scale the cluster when the WLDF policy is triggered.  Create oow-demo-webhook image:
    ```
    $ docker build -t oow-demo-webhook -f Dockerfile.webhook .
    ```

4.  Save the docker images to the file system
    ```
    $ docker save -o wls-12213-oow-demo-domain.tar wls-12213-oow-demo-domain
    $ docker save -o oow-demo-webhook.tar oow-demo-webhook
    ```

5.  Start minikube and set
    ```
    $ minikube start
    $ eval $(minikube docker-env)
    ```

6.  Load the saved images into minikube.  
    ```
    $ minikube ssh "docker load -i $PWD/wls-12213-oow-demo-domain.tar"
    $ minikube ssh "docker load -i $PWD/oow-demo-webhook.tar"
    ```

7.  Go back to the **OracleWebLogic/samples/wls-k8s** directory
    ```
    $ cd ..
    ```

8.  Start the WLS Admin Server and Managed Servers.
    ```
    $ kubectl create -f k8s/wls-admin-webhook.yml
    $ kubectl create -f k8s/wls-stateful.yml
    ```

9.  Verify that the instances are running.
    ```
    $ kubectl get pods
    ```

    You should see one Admin Server and two Managed Servers, looking something like:
    ```
    NAME                                   READY     STATUS    RESTARTS   AGE
    ms-0                                   1/1       Running   0          3m
    ms-1                                   1/1       Running   0          1m
    wls-admin-server-0                     1/1       Running   0          5m
    ```

    Wait until all three have reached the _Running_ status before continuing.

10. Verify that you can reach the managed servers

    The servers are accessible on the minikube IP address, usually 168.192.99.100. To verify that address:

     ```
     $ minikube ip
     192.168.99.100
     ```

    Then use your browser to view one of the managed servers at `http://192.168.99.100:30011/memoryloadapp/`
    If you refresh it, its instance name should vary between `ms-0` and `ms-1`.

11. Log into the admin console

    0. Browse to `http://192.168.99.100:30001/console/` and log in using the credentials passed in as build arguments when building the wls-12213-domain
    1. Under **Domain Structure** click *Environment* and then *Servers*
    2. You should see 2 managed servers RUNNING, and 3 more SHUTDOWN

12. Start Prometheus to monitor the managed servers:
     ```
     $ kubectl create -f prometheus/prometheus-kubernetes.yml
     ```

     0. Verify that Prometheus is monitoring both servers by browsing to `http://192.168.99.100:32000`
     1. Click on the metrics pulldown and select 'wls_scrape_cpu_seconds' and click 'execute'. You should see a metric for each instance.

13. Start Grafana to monitor the managed servers:
     ```
     $ kubectl create -f prometheus/grafana-kubernetes.yml
     ```
     0. Connect to Grafana at: `http://192.168.99.100:31000`
     1. Log in with `admin`/`pass`
     2.  Click "Add Data Source" and then connect Grafana to Prometheus by entering:
         ```
         Name:   Prometheus
         Type:   Prometheus
         Url:    http://prometheus:9090
         Access: Proxy
         ```
     3. Click the leftmost menu on the menu bar, and select `Dashboards > Import`
     4. Upload and Import the file `prometheus/grafana-config.json` and select the data source
    you added in the previous step ("Prometheus"). It should generate a dashboard named "WLS_Prometheus"
     5. You should now see graphs of activity on the two active servers

14. Verify monitoring of WLS data in Grafana

    1. Browse to `http://192.168.99.100:30011/memoryloadapp` and click on button "Run Memory Load"
    2. A spike in memory will be displayed on the Grafana graph labeled "Used Heap Current Size"
    3. This action can be repeated multiple times

15. Observe the response to scaling up
     ```
     $ kubectl scale statefulset ms --replicas=3
     ```

   `kubectl get pods` should now show ms-0, ms-1, ms-2 and wls-admin-server-0.  Also,
   the console will show that ms-0, ms-1, ms-2 are RUNNING and ms-3 and ms-4 are SHUTDOWN.
   Prometheus should show metrics for all three managed servers
   After about a minute, data will show up in Grafana

16. Scale back the managed servers to 2 replica
     ```
     $ kubectl scale statefulset ms --replicas=2
     ```

   `kubectl get pods` will show ms-1, ms-2 shutting down.  
   The console will show that only ms-0 is RUNNING and ms1- through ms-4 are SHUTDOWN.
   Prometheus and Grafana will stop showing data for ms-1 and ms-2.

17. Trigger a WLDF scaling event.

    1. Browse to `http://192.168.99.100:30011/opensessionapp`
    2. Within a minute or two, a new ms-1 instance will be created, and show up in all of the above ways to view it.

        **Note**: The WLDF smart rule configured for this demo monitors the OpenSessionsCurrentCount of the
        WebAppComponentRuntimeMBean for ApplicationRuntime called "OpenSessionApp". It will trigger
        a REST action when the average number of opened sessions >= 0.01 on 5% or more of the servers in a WebLogic cluster called
        "DockerCluster", computed over the last ten seconds, sampled every second. The REST action invokes a webhook
        that scales up the statefulset named "ms" by one.
        The WLDF rule is configured with a 1 minute alarm, so it will not trigger another action within 1 minute.  
        After that same step can repeat again and again to continue scaling up.
    3. Connect to Grafana to check the collected metrics for OpenSessionCount in the
       graph "Open Sessions Current Count"

18. Clean up by shutting down the services. Shutting down the WLS instances can take some time.
     ```
     $ kubectl delete -f prometheus/grafana-kubernetes.yml
     $ kubectl delete -f prometheus/prometheus-kubernetes.yml
     $ kubectl delete -f k8s/wls-stateful.yml
     $ kubectl delete -f k8s/wls-admin-webhook.yml
     ```

*Troubleshooting*
  - if something is not working as expected, sometimes just shutting down minikube and
    starting it back up again will fix the problem:
    ```
      minikube stop
      minikube start
    ```

  - it might be helpful to check the log(s) to see if everything is starting up successfully, *e.g.*,
    ```
    $ kubectl logs -f wls-admin-server-0 -c wls-admin-server
    ```
##COPYRIGHT
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
