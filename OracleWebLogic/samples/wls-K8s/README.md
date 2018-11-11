WebLogic on Kubernetes Sample
=========================================
This Example demonstrates the orchestration of a WebLogic 12.2.1.3 domain cluster in a Kubernetes environment. We run through different scaling action of the WebLogic cluster in K8s:
	1- Scale/shrink  the cluster by increasing/decreasing the number of ReplicaSet.
	2- Define a WLDF policy base on Open Session Count MBean and allow the WLS Admin Server initiate the scaling action.

**NOTE:** This sample has been removed since it no longer is aligned with our WebLogic on Kubernetes deployment. Please refer to our WebLogic on Kubernetes Operator project for the latest implmentation at [https://github.com/oracle/weblogic-kubernetes-operator].  The Prometheus and Grafana sample have been moved under the WebLogic Monitoring Exporter project [https://github.com/oracle/weblogic-monitoring-exporter/tree/master/samples/kubernetes].

##COPYRIGHT
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.

