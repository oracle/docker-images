How to Build the image
======================
Before you Start
----------------
1. **FIRST TIME ONLY**
   - Update the OracleSOABPM/setenv.sh file to point
     to the right locations for the following environment variables
     specific to your environment (See top of file)    
     DC_USERHOME, DC_REGISTRY_SOA, DC_REGISTRY_DB    

SOA|BPM|OSB Domain images
-------------------------
1. You must have the install binaries downloaded from the
   [Oracle Technology Network](http://www.oracle.com/technetwork/middleware/soasuite/downloads/index.html) site before proceeding. 
2. From the current directory OracleSOABPM/dockerfiles, run
   these commands. You will be prompted with all the 
   information. Carefully review it and Confirm to proceed. 

    ```sh
# Use BUILD_OPTS to add extra arguments to the docker build command
sh buildDockerImage.sh -v 12.2.1.2-soabpm
    ```
