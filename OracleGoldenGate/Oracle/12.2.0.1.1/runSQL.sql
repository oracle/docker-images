set echo on
set serveroutput on
SPOOL /tmp/runSQL.log
alter system set enable_goldengate_replication=true;
--alter system set log_archive_dest_1='location=/opt/datafile/ora12102i/arch';
alter system set processes=300 scope=spfile;
alter system set sessions=500 scope=spfile;
shutdown immediate;
startup mount;
alter database archivelog;
alter database open;
alter system switch logfile;
archive log list;
--select * from v$encryption_wallet;
alter system set job_queue_processes=1000;
alter system set streams_pool_size=200m;
alter system set shared_pool_size=500m;
alter database add supplemental log data;
--drop tablespace GGATE including contents and datafiles;
create tablespace GGATE datafile '/u01/app/oracle/oradata/ggate01.dbf' size 1G;
drop user ggate cascade;
create user ggate identified by ggate default tablespace GGATE temporary tablespace TEMP quota unlimited on GGATE account unlock;
grant sysdba to ggate;
grant dba to ggate;
grant connect to ggate;
grant resource to ggate;
alter user ggate default role dba, connect, resource;
execute dbms_goldengate_auth.grant_admin_privilege('ggate'); 
set linesize 180
select open_mode, supplemental_log_data_min, force_logging, current_scn from v$database;
select instance_name, version, startup_time, status from v$instance;
SPOOL OFF
