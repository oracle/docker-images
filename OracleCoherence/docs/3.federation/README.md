# Federated Caching in Docker

Federated Caching in Oracle Coherence allows cached data to be replicated between multiple clusters. To use federation, these clusters must be visible to eachother over the network. This can cause some challenges in Docker depending on which of Docker's network modes is being used.

## Docker Host Networking
Using host networking, i.e. starting Coherence containers with the `--net=host` argument, means that the containers use the hosts network stack and consequently are visible to each other as though they were running directly on the host. This is the easiest way to use Coherence with Federated Caching as everything works as normal. Federation can then be configured with the host names of the Docker hosts. 
  
Using host networking it is possible to federate caches between containerised and non-containerised clusters.
   
## Docker Overlay Network
If host networking cannot be used, then the second option is to use an overlay network. Docker's overlay network allows containers on different hosts to communicate with each other using a virtualized network. For Federated Caching to work, the containers in all of the clusters that are being federated must be attached to the same overlay network.     
