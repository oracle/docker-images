# Using Docker Compose to orchestrate containers

1. **FIRST TIME ONLY:**
   - Update the `OracleSOASuite/setenv.sh` file to point
     to the right locations for the following environment variables
     specific to your environment (See top of file):    
     `DC_USERHOME`, `DC_REGISTRY_SOA`, `DC_REGISTRY_DB`    

2. Setup your current environment (running `bash`)

       # cd OracleSOASuite/samples
       # source ../setenv.sh

3. Setup and start the Database container
   - Ensure port 1521 is free for use for the database

         netstat -an | grep 1521

   - Start the DB Container

         docker-compose up -d soadb
         docker logs -f soadb

4. Starting the Admin Server (AS) container. 
    - **Ensure Database is up first**
    - Start AS - First Run will run RCU and create the SOA schemas, 
      Create the needed Domain (SOA/OSB/BPM etc) and Start the Admin 
      Server
    - Subsequent runs will just start the already configured Admin Server

          docker-compose up -d soaas
          docker logs -f soaas

5.  Starting the Managed Server (MS) container 
    - **Ensure the Admin Server is up first**, then run:

          docker-compose up -d soams
          docker logs -f soams
