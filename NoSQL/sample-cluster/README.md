Oracle NoSQL on Docker: Sample Cluster 
==========
This sample demonstrates how to create a scalable NoSQL cluster on Docker with Multihost Network support. To get this up and running, follow these steps:

 1. Install Docker 1.9+ and Docker Machine (as well VirtualBox)
 2. Checkout the **sample-cluster** folder from the NoSQL repository
 3. Run the **bootstrap.sh** script in your host environment
 4. Find the IP address of the Docker Machine **node-admin** and go to http://<ip>:5001 to access the NoSQL Web Console
 5. Create a Storage Node by running **create-storage-node.sh**
 6. Check the NoSQL Web Console to see the new Storage Node
 7. Create as many Storage Nodes you want by calling **create-storage-node.sh**
 8. Redistribute the Storage Nodes by calling the **sample-cluster/redistribute-topology.sh** from inside any of the existing running containers.
 9. Check the web console again.

Enjoy elastic Oracle NoSQL on Docker.
