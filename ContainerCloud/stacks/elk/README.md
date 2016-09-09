# ELK Stack

ELK is a logging stack composed of elasticsearch, logstash, and kibana. Additionally, logspout is included in this stack to send system logging events about a host into logstash.

## Running the Stack

When you run the ELK stack, you can load the kibana UI at http://mesh-leader:5601 (where `mesh-leader` is the hostname or IP address of the host that is running that container).

The initial page load of kibana asks you to configure an index pattern. Use the default `logstash-*` pattern, choose `@timestamp` for the *Time-field name* field, and then click the *Create* button.

Choose *Discover* from the top navigation menu and events from logspout should appear in kibana!

## Elasticsearch

Logstash and kibana link directly to elasticsearch, and use the `elasticsearch` DNS name to send and pull events from.

## Logstash

Logstash uses input listeners which are listening on port 5000 for both TCP and UDP connections.

## Logspout

Logspout pulls metrics from the Docker engine's socket file and sends the data to logstash using a syslog connection. In order to do this, the logspout container must derive the IP address and the port of the logstash service. This requires the following environment variables to be defined:

* `OCCS_API_TOKEN={{api_token}}` - the token for authenticating against the key/value endpoint
* `KV_IP=172.17.0.1` - the IP address which provides the key/value endpoint, in this case the host running the container
* `KV_PORT=9109` - the port on which the key/value endpoint is listening
* `OCCS_LOGSTASH_KEY={{sd_deployment_containers_path "logstash" 5000}}` - the key prefix in the key/value store that can be used to lookup the IP and published port of logstash

## Kibana

Kibana links to the elasticsearch service. As mentioned above, port 5601 is published for access the UI.
