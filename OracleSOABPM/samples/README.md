# Docker Compose to Orchestrate Containers

1. **FIRST TIME ONLY**
   - Update the OracleSOABPM/setenv.sh file to point
     to the right locations for the following environment variables
     specific to your environment (See top of file)    
     DC_USERHOME, DC_REGISTRY_SOA, DC_REGISTRY_DB    
   - Update the OracleSOABPM/setenv.sh file with the proxy details
     if you have an internal proxy - ensure that the proxy
     related env variables are set    
     http_proxy, https_proxy, no_proxy

2. Setup your current environment
    ```sh
exec bash (To replace your current shell with bash)
# cd OracleSOABPM/samples
. ../setenv.sh
```

3. Setup and start the Database
   - Ensure port 1521 is free for use for the database

    ```sh
netstat -an | grep 1521
```
   - Start the DB Container

    ```sh
docker-compose up -d soadb
docker logs -f soadb
    ```

4. Starting the Admin Server Container. **DB MUST BE UP**
  - Start AS - First Run will run RCU and create the SOA schemas, 
    Create the needed Domain (SOA/OSB/BPM etc) and Start the Admin 
    Server
  - Subsequent runs should simply start the Admin Server
  - Use **soaas|bpmas|osbas** depending on which one you want to start

    ```sh
docker-compose up -d soaas
docker logs -f soaas
    ```
  - Verify Admin Server  
    http://host.acme.com:7001/console (weblogic/welcome1)

5.  Starting the Managed Server Container **ADMINSERVER MUST BE UP**
  - Use **soaas|bpmas|osbas** depending on which one you want to start

    ```sh
docker-compose up -d soams
docker logs -f soams
    ```
  - Verify Managed Server  
    SOA|BPM: http://host.acme.com:8001/soa-infra (weblogic/welcome1)  
    OSB: http://host.acme.com:7001/servicebus (weblogic/welcome1)

6. [Compose Command line Reference Page](https://docs.docker.com/compose/reference/)
    ```sh
docker-compose --help
    ```
