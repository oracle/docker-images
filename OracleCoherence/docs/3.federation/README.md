# Federated Caching in Docker

Federated Caching in Oracle Coherence allows cached data to be replicated between multiple clusters. For this to occur these clusters must be visible to each other over the network. This can cause some challenges in Docker depending on which of Docker's network modes is being used.

## Docker Host Networking
Using host networking, i.e. starting Coherence containers with the `--net=host` argument will mean that the containers use the Docker host machine's network stack and consequently are visible to each other as though they were running directly on the host. This is the easiest way to use Coherence with Federated Caching as everything will work as normal. Federation can then be configured with the host names of the Docker hosts. 

Using host networking it is possible to federate caches between containerised and non-containerised clusters.
   
## Docker Overlay Network
If host networking cannot be used the second option would be to use an overlay network. Docker's overlay network allows containers on different hosts to communicate with each other via a virtualized network. For Federated Caching to work all of the containers in all of the clusters being federated must be attached to the same overlay network, therefore when using overlay networking it is not possible to federate caches between containerised and non-containerised clusters.
