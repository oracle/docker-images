# Example Docker Setup
The examples in the Docs section show various different aspects of Oracle Coherence functionality running in a multi-host Docker environment. The examples require a Docker environment with two Docker hosts configured to run Docker's overlay network, i.e. with a suitable key store configured. The easiest way to configure a suitable example environment is to use Docker Machine to set up some temporary virtual machines that can then be disposed of afterwards. aA very similar configuration can be used to that described in Docker's own [Get Started with multi-host networking](https://docs.docker.com/engine/userguide/networking/get-started-overlay/) examples using Consul as the keystore required to use Docker networking. This example is not going to use Swarm so there is no requirement to configure it. 

1 Create the key store machine using the following command

    ```
    $ docker-machine create -d virtualbox coh-keystore
    ```
    
    This will create a Docker Machine VM called `coh-keystore`
    
2 Set your local environment to the coh-keystore machine.
    
    `$ eval "$(docker-machine env coh-keystore)"`
    
3 Start a `progrium/consul` container running on the coh-keystore machine.
    
    ```
    $ docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap`
    ```
    
4 Create a second machine that will be used to run Coherence containers.
    
    ```
    docker-machine create -d virtualbox \
    --engine-opt="cluster-store=consul://$(docker-machine ip coh-keystore):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    coh-demo0
    ```

    This will create a Docker Machine VM called `coh-demo0` that is configured to use the Consul keystore created above.
    
5 Create a third machine that will be used to run Coherence containers.

    ```
    docker-machine create -d virtualbox \
    --engine-opt="cluster-store=consul://$(docker-machine ip coh-keystore):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    coh-demo1
    ```

    This will create a Docker Machine VM called `coh-demo1` that is configured to use the Consul keystore created above.
    
6 Create an overlay network to use in the overlay examples. This command only needs to be executed for one of the cluster machines so the `$(docker-machine config coh-demo0)` argument is used to target the command to the `coh-demo0` machine. 
    
    ```
    $ docker $(docker-machine config coh-demo0) network create \
    --driver overlay coh-net
    ```

    There will now be an overlay network called `coh-net` available to both `coh-demo0` and `coh-demo1` machines.
    
7 Build the Java 8 image. Change directory to the `OracleJDK/java-8` directory, make sure the required JRE install (as documented in the [OracleJDK](../../../OracleJDK) section) has been downloaded to that directory, and then run these commands:
    
    `$ eval "$(docker-machine env coh-demo0)"`
    
    `$ sh build.sh`
    
    `$ eval "$(docker-machine env coh-demo1)"`
    
    `$ sh build.sh`
    
8 Build the Coherence image. Change directory to the `OracleCoherence/dockerfiles/12.2.1` directory, make sure that the Coherence 12.2.1 Standalone installer has been downloaded to the directory and run these commands:
    
    `$ eval "$(docker-machine env coh-demo0)"`
    
    `$ sh buildDockerImage.sh -s`
    
    `$ eval "$(docker-machine env coh-demo1)"`
    
    `$ sh buildDockerImage.sh -s`
    
There should now be three Docker Machine VMs running, one running the Consul key store and two with the `oracle/coherence:12.2.1.0.0-standalone` image installed.