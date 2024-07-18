# Installing Oracle DB,  APEX and ORDS in Docker


## Step 1: Installing Docker

Follow the instructions on the Docker official documentation to install Docker Desktop on Windows:
- [Docker Desktop Installation for Windows](https://docs.docker.com/desktop/install/windows-install/)

**Important**: Download 'Docker Desktop for Windows - x86_64' and 
               Do not run the `.exe` file by double-clicking. Instead, follow these steps:
1. Navigate to the installer directory.
2. Open a Command Prompt and run the following command:
   ```sh
   start /w "" "Docker Desktop Installer.exe" install -accept-license --installation-dir="D:\Docker\Docker" --wsl-default-data-root="D:\Docker\wsl" --windows-containers-default-data-root="D:\Docker"
   ```

Verify the Docker installation by running:
```sh
docker --version
```

Start the Docker engine if it's not already running.

## Step 2: Download Oracle Database 19.3.0 (Enterprise Edition)

Download Oracle Database 19c for Linux x86-64 from the following link:
- [Oracle Database 19c for Linux x86-64 ZIP](https://www.oracle.com/au/database/technologies/oracle-database-software-downloads.html#db_ee)

Clone this repository and Copy the `.zip` file into the folder:
```
Oracle-Docker-Images\OracleDatabase\SingleInstance\dockerfiles\19.3.0\
```

## Step 3: Installing Oracle Database 19.3.0 (Enterprise Edition), APEX 24.1, and ORDS 24.2

Open a Git Bash window in the root directory of this project and run the following script:
```sh
./install.sh
```

This process will take approximately 30 minutes.

## Step 4: Reset Password for the APEX Administration Services Account

Create a connection in SQL Developer using the following details:

- **DB_PORT**: `1521`
- **DB_HOST**: `localhost`
- **DB_SERVICE**: `DEV`
- **DB_USER**: `sys`
- **DB_PASSWORD**: `SysPassw0rd`

After logging in, run the following command and provide the Admin Username, Email Address, and Password:
```sql
alter session set container = PDB1;
@D:\Path\To\Oracle-Docker-Images\OracleApplicationExpress\dockerfiles\tmp\apex\apxchpwd.sql;
```

## Step 5: Login to APEX

Use the credentials set in Step 4 to log in to APEX:
- [APEX Login](http://localhost:8081/ords/pdb1/r/apex/workspace-sign-in/administration-sign-in)

---

