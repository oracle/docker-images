#!/bin/bash

DB_HOST=$1
DB_PORT=$2
DB_SERVICE=$3
DB_USER=$4
DB_PASSWORD=$5

echo "Removing any existing APEX setup..."
cd /opt/oracle/apex
sqlplus -s sys/SysPassw0rd@192.168.4.48:1521/DEV as sysdba <<EOF
   ALTER SESSION SET CONTAINER = PDB1;
   @apxremov.sql
   exit;
EOF
echo "Finished removing APEX setup..."

# Configure APEX
echo "Starting APEX setup..."
cd /opt/oracle/apex

sqlplus -s sys/SysPassw0rd@192.168.4.48:1521/DEV as sysdba <<EOF
   ALTER SESSION SET CONTAINER = PDB1;
   @apexins.sql SYSAUX SYSAUX TEMP /i/
   exit;
EOF
echo "Finished APEX setup..."



# Check if APEX_PUBLIC_USER exists before attempting operations
sqlplus -s sys/SysPassw0rd@192.168.4.48:1521/DEV as sysdba <<EOF
   ALTER SESSION SET CONTAINER = PDB1;
   SET SERVEROUTPUT ON
   DECLARE
     user_exists NUMBER;
   BEGIN
     SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'APEX_PUBLIC_USER';
     IF user_exists = 1 THEN
       EXECUTE IMMEDIATE 'ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK';
       EXECUTE IMMEDIATE 'ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ApexPassw0rd';
       DBMS_OUTPUT.PUT_LINE('APEX_PUBLIC_USER unlocked and password set.');
     ELSE
       DBMS_OUTPUT.PUT_LINE('APEX_PUBLIC_USER not found. Installation may not have completed successfully.');
     END IF;
   END;
   /
   exit;
EOF
echo "Finished resetting password for APEX_PUBLIC_USER..."

