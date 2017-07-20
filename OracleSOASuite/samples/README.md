# Docker Compose to Orchestrate Containers

1. **FIRST TIME ONLY**
   - Update the OracleSOASuite/setenv.sh file to point
     to the right locations for the following environment variables
     specific to your environment (See top of file)    
     DC_USERHOME, DC_REGISTRY_SOA, DC_REGISTRY_DB    

2. Setup your current environment

       exec bash (To replace your current shell with bash)
       # cd OracleSOASuite/samples
       . ../setenv.sh

3. Setup and start the Database
   - Ensure port 1521 is free for use for the database

         netstat -an | grep 1521

   - Start the DB Container

         docker-compose up -d soadb
         docker logs -f soadb

4. Starting the Admin Server Container. **DB MUST BE UP**
  - Start AS - First Run will run RCU and create the SOA schemas, 
    Create the needed Domain (SOA/OSB/BPM etc) and Start the Admin 
    Server
  - Subsequent runs should simply start the Admin Server

        docker-compose up -d soaas
        docker logs -f soaas

5.  Starting the Managed Server Container **ADMINSERVER MUST BE UP**

        docker-compose up -d soams
        docker logs -f soams
