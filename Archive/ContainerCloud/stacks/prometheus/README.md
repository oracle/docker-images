# Monitoring with Prometheus and cAdvisor Stack

This monitoring stack demonstrates how cAdvisor can feed monitoring data into a time series aggregator like Prometheus.

## Running the Stack

When you run the monitoring stack, you can load both the cAdvisor and the Prometheus UIs.

The cAdvisor UI is available at http://mesh-leader:8081 (where `mesh-leader` is the hostname or IP address of the host that is running that container). From here, you can inspect information about the host on which the cAdvisor container is running.

The Prometheus server UI is available at http://mesh-leader:9090 (where `mesh-leader` is the hostname or IP address of the host that is running that container). From here, you can use the built in query and charting features of Prometheus server to learn about what is running on the host.

To see a sample graph, go to http://mesh-leader:9090/graph, enter `container_memory_usage_bytes` in the *Expression* field and click the *Execute* button. The graph will begin to show a line chart plotting the memory usage of all the containers running on that host.

## cAdvisor

cAdvisor requires some host volume mounts to gather metrics about the Docker engine:

* /var/run:/var/run
* /sys/:/sys:ro
* /var/lib/docker/:/var/lib/docker:ro

## Prometheus

Prometheus scrapes metrics from cAdvisor (on http://mesh-leader:8081/metrics). In order to do this, the prometheus container must derive the IP address and the port of the cAdvisor service. This requires the following environment variables to be defined:

* `OCCS_API_TOKEN={{api_token}}` - the token for authenticating against the key/value endpoint
* `KV_IP=172.17.0.1` - the IP address which provides the key/value endpoint, in this case the host running the container
* `KV_PORT=9109` - the port on which the key/value endpoint is listening
* `OCCS_BACKEND_KEY={{sd_deployment_containers_path "cadvisor" 8080}}` - the key prefix in the key/value store that can be used to lookup the IP and published port of cAdvisor
