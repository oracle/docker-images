#!/bin/bash

# Source the properties file
source ../../config.properties

echo "Removing any existing APEX setup..."
cd /opt/oracle/apex
sqlplus -s $DB_USER/$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_SERVICE as sysdba <<EOF
   alter session set container = PDB1;
   @apxremov.sql
   exit;
EOF
echo "Finished removing APEX setup..."

# Configure APEX
echo "Starting APEX setup..."
cd /opt/oracle/apex

sqlplus -s $DB_USER/$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_SERVICE as sysdba <<EOF
   alter session set container = PDB1;
   @apexins.sql SYSAUX SYSAUX TEMP /i/
   exit;
EOF
echo "Finished APEX setup..."



# Check if APEX_PUBLIC_USER exists before attempting operations
sqlplus -s $DB_USER/$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_SERVICE as sysdba <<EOF
   alter session set container = pdb1;
   set serveroutput on
   declare
     user_exists number;
   begin
     select count(*) into user_exists from dba_users where username = 'APEX_PUBLIC_USER';
     if user_exists = 1 then
       execute immediate 'alter user APEX_PUBLIC_USER account unlock';
       execute immediate 'alter user APEX_PUBLIC_USER identified by ApexPassw0rd';
       dbms_output.put_line('APEX_PUBLIC_USER unlocked and password set.');
	   
	   ords_admin.config_plsql_gateway(
		  p_runtime_user => 'ORDS_PUBLIC_USER', 
		  p_plsql_gateway_user => 'APEX_PUBLIC_USER' 
	   );

       apex_instance_admin.set_parameter(
            p_parameter => 'IMAGE_PREFIX',
            p_value     => 'https://static.oracle.com/cdn/apex/24.2.0/' );
			
     else
       dbms_output.put_line('APEX_PUBLIC_USER not found. Installation may not have completed successfully.');
     end if;
   end;
   /
   exit;
EOF
echo "Finished resetting password for APEX_PUBLIC_USER..."

