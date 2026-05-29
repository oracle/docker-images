#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

import os
import sys
import re
import socket
from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *

class OraPCatalog:
      """
      This class sets up the Catalog after DB installation.
      """
      _CATALOG_LIVE_OK_MSG = "Catalog liveness check completed successfully!"

      def __init__(self,oralogger,orahandler,oraenv,oracommon):
        """
        Initialize catalog setup object for primary DB.

        Attributes:
           oralogger (object): object of OraLogger Class.
           ohandler (object): object of Handler class.
           oenv (object): object of singleton OraEnv class.
           ocommon(object): object of OraCommon class.
           ora_env_dict(dict): Dict of env variable populated based on env variable for the setup.
           file_name(string): Filename from where logging message is populated.
        """
        self.ologger             = oralogger
        self.ohandler            = orahandler
        self.oenv                = oraenv.get_instance()
        self.ocommon             = oracommon
        self.ora_env_dict        = oraenv.get_env_vars()
        self.file_name           = os.path.basename(__file__)
        self.omachine            = OraMachine(self.ologger,self.ohandler,self.oenv,self.ocommon)

      def _run_sqlplus_checked(self, sqlpluslogin, sqlcmd, status):
          """
          Execute SQLPlus command and perform standard SQL error validation.
          """
          output,error,retcode=self.ocommon.run_sqlplus(sqlpluslogin,sqlcmd,None)
          self.ocommon.log_info_message("Validating SQL command return status via check_sql_err()",self.file_name)
          self.ocommon.check_sql_err(output,error,retcode,status)
          return output,error,retcode

      def _get_sqlplus_sysdba_login(self):
          """
          Build a SYSDBA SQL*Plus login command from current environment.
          """
          ohome=self.ora_env_dict["ORACLE_HOME"]
          inst_sid=self.ora_env_dict["ORACLE_SID"]
          return self.ocommon.get_sqlplus_str(ohome,inst_sid,"sys",None,None,None,None,None,None,None)

      def _is_racdb(self):
          """
          Return True when running in RAC database mode.
          """
          return (
             self.ocommon.check_key("CRS_RACDB",self.ora_env_dict)
             and self.ora_env_dict["CRS_RACDB"].lower() == 'true'
          )

      def _is_gpc(self):
          """
          Return True when running in GPC mode.
          """
          return (
             self.ocommon.check_key("CRS_GPC",self.ora_env_dict)
             and self.ora_env_dict["CRS_GPC"].lower() == 'true'
          )

      def _require_cluster_nodes(self):
          """
          Return configured cluster nodes or exit if missing.
          """
          if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
             return self.ora_env_dict["COMMA_SEPARATED_CLS_NODES"].split(",")
          self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
          self.ocommon.prog_exit("127")

      def _exec_cmd_checked(self,cmd,status):
          """
          Run shell command and validate return code.
          """
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,status)
          return output,error,retcode

      def _run_remote_grid_listener_cmd(self,node,action,status):
          """
          Run `lsnrctl <action>` as GRID user on a remote node.
          """
          oracle_home=self.ora_env_dict["GRID_HOME"]
          giuser=self.ora_env_dict["GRID_USER"]
          remote_cmd = """ssh {0}@{1} '{2}/bin/lsnrctl {3}'""".format(giuser,node,oracle_home,action)
          cmd = '''sudo -u {0} {1}'''.format(giuser,remote_cmd)
          return self._exec_cmd_checked(cmd,status)

      def _is_catalog_ready(self):
          """
          Helper to evaluate catalog setup completion status.
          """
          return self.catalog_setup_check()

      def _catalog_lock_files(self):
          """
          Return create/exist lock file paths for catalog liveness handling.
          """
          lock_base = self.ocommon.get_db_lock_location()
          sid = self.ora_env_dict["ORACLE_SID"]
          return lock_base + sid + ".create_lck", lock_base + sid + ".exist_lck"

      def setup(self):
          """
           Set up catalog on primary DB.
          """
          self.check_for_racdb()
          if self.ocommon.check_key("ORACLE_FREE_PDB",self.ora_env_dict):
            self.ora_env_dict=self.ocommon.update_key("ORACLE_PDB",self.ora_env_dict["ORACLE_FREE_PDB"],self.ora_env_dict)

          if self.ocommon.check_key("CHECK_LIVENESS",self.ora_env_dict):
             create_db_file_lck, exist_db_file_lck = self._catalog_lock_files()
             self.ocommon.log_info_message("DB create lock file set to :" + create_db_file_lck ,self.file_name)
             self.ocommon.log_info_message("DB exist lock file set to :" + exist_db_file_lck ,self.file_name)

             if os.path.exists(create_db_file_lck):
                self.ocommon.log_info_message("Provisioning is still in progress because lock file " + create_db_file_lck + " still exists.",self.file_name)
                self.ocommon.log_result_message(False, "Catalog liveness check failed: provisioning lock file exists", self.file_name)
                sys.exit(127)

             if os.path.exists(exist_db_file_lck):
                self.ocommon.log_info_message("Database is up and running as file " + exist_db_file_lck + " exists!",self.file_name)

             status = self._is_catalog_ready()
             if not status:
                self.ocommon.log_result_message(False, "Catalog liveness check failed: catalog setup is incomplete", self.file_name)
                self.ocommon.prog_exit("127")
             self.ocommon.log_info_message(self._CATALOG_LIVE_OK_MSG,self.file_name)
             self.ocommon.log_result_message(True, "Catalog liveness check completed successfully", self.file_name)
             sys.exit(0)

          elif self.ocommon.check_key("CHECK_READYNESS",self.ora_env_dict):
             status = self._is_catalog_ready()
             if not status:
                self.ocommon.log_info_message("Catalog readiness check failed.",self.file_name)
                self.ocommon.log_result_message(False, "Catalog readiness check failed: catalog setup is incomplete", self.file_name)
                self.ocommon.prog_exit("127")
             self.ocommon.log_info_message("Catalog readiness check completed successfully!",self.file_name)
             self.ocommon.log_result_message(True, "Catalog readiness check completed successfully", self.file_name)

          elif self.ocommon.check_key("RESET_PASSWORD",self.ora_env_dict):
            _, exist_db_file_lck = self._catalog_lock_files()
            if os.path.exists(exist_db_file_lck):
               self.ocommon.log_info_message("Catalog database up and running. Resetting password...",self.file_name)
            else:
               self.ocommon.log_info_message("Catalog does not seem to be ready. Unable to reset password",self.file_name)
               self.ocommon.prog_exit("127")

          elif self.ocommon.check_key("EXPORT_TDE_KEY",self.ora_env_dict):
            status = self._is_catalog_ready()
            if not status:
               self.ocommon.log_info_message("Catalog does not seem to be ready. Unable to export the TDE key",self.file_name)
               self.ocommon.prog_exit("127")

            self.ocommon.log_info_message("Catalog database up and running.",self.file_name)
            self.ocommon.export_tde_key(self.ora_env_dict["EXPORT_TDE_KEY"])

          else:
            self.setup_machine()
            self.db_checks()
            self.reset_catalog_setup()
            status = self._is_catalog_ready()
            if status:
               self.ocommon.log_info_message("Catalog setup is already completed on this database",self.file_name)
            else:
               self.reset_passwd()
               self.setup_cdb_catalog()
               self.set_spfile_nonm_params()
               self.ocommon.set_events("spfile")
               self.set_dbparams_version()
               self.restart_db()
               self.restart_for_db_unique_name()
               self.create_pdb()
               self.alter_db()
               self.setup_pdb_catalog()
               self.set_primary_listener()
               self.restart_listener()
               self.register_services()
               self.list_services()
               self.backup_files()
               self.update_catalog_setup()
               self.gsm_completion_message()
               self.run_custom_scripts()
      ###########  SETUP_MACHINE begins here ####################
      ## Function to machine setup
      def setup_machine(self):
          """
           Perform compute-level setup before catalog operations.
          """
          self.omachine.setup()

      ###########  SETUP_MACHINE ENDS here ####################

      ###########  DB_CHECKS  Related Functions Begin Here  ####################
      ## Function to perform DB checks ######
      def db_checks(self):
          """
           Run required database checks before setup.
          """
          self.ohome_check()
          self.passwd_check()
          self.set_user()
          self.sid_check()
          self.dbunique_name_check() 
          self.hostname_check()
          self.dbport_check()
          self.dbr_dest_checks()
          self.dpump_dir_checks()

      def ohome_check(self):
          """
             Perform ORACLE_HOME validation checks.
          """
          if self.ocommon.check_key("ORACLE_HOME",self.ora_env_dict):
             self.ocommon.log_info_message("ORACLE_HOME variable is set. Check Passed!",self.file_name)
          else:
             self.ocommon.log_error_message("ORACLE_HOME variable is not set. Exiting!",self.file_name)
             self.ocommon.prog_exit("127")

          if os.path.isdir(self.ora_env_dict["ORACLE_HOME"]):
             msg='''ORACLE_HOME {0} directory exist. Directory Check passed!'''.format(self.ora_env_dict["ORACLE_HOME"])
             self.ocommon.log_info_message(msg,self.file_name)
          else:
             msg='''ORACLE_HOME {0} directory does not exist. Directory Check Failed!'''.format(self.ora_env_dict["ORACLE_HOME"])
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")

      def passwd_check(self):
           """
           Validate and load password inputs.
           """
           self.ocommon.get_password(None)
           if self.ocommon.check_key("ORACLE_PWD",self.ora_env_dict):
               msg='''ORACLE_PWD key is set. Check Passed!'''
               self.ocommon.log_info_message(msg,self.file_name)
               
      def set_user(self):
           """
           Set admin users for PDB and CDB.
           """
           if self.ocommon.check_key("SHARD_ADMIN_USER",self.ora_env_dict):
               msg='''SHARD_ADMIN_USER {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["SHARD_ADMIN_USER"])
               self.ocommon.log_info_message(msg,self.file_name)
           else:
               self.ora_env_dict=self.ocommon.add_key("SHARD_ADMIN_USER","mysdbadmin",self.ora_env_dict)
               msg="SHARD_ADMIN_USER is not set, setting default to mysdbadmin"
               self.ocommon.log_info_message(msg,self.file_name)

           if self.ocommon.check_key("PDB_ADMIN_USER",self.ora_env_dict):
               msg='''PDB_ADMIN_USER {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["PDB_ADMIN_USER"])
               self.ocommon.log_info_message(msg,self.file_name)
           else:
               self.ora_env_dict=self.ocommon.add_key("PDB_ADMIN_USER","PDBADMIN",self.ora_env_dict)
               msg="PDB_ADMIN_USER is not set, setting default to PDBADMIN."
               self.ocommon.log_info_message(msg,self.file_name)

      def sid_check(self):
           """
           Validate ORACLE_SID for CDB/PDB operations.
           """
           if self.ocommon.check_key("ORACLE_SID",self.ora_env_dict):
               msg='''ORACLE_SID {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["ORACLE_SID"])
               self.ocommon.log_info_message(msg,self.file_name)
           else:
               msg="ORACLE_SID is not set, exiting!"
               self.ocommon.log_error_message(msg,self.file_name)
               self.ocommon.prog_exit("127")

      def dbunique_name_check(self):
           """
           Validate and set DB_UNIQUE_NAME.
           """
           if self.ocommon.check_key("DB_UNIQUE_NAME",self.ora_env_dict):
               msg='''DB_UNIQUE_NAME {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["DB_UNIQUE_NAME"])
               self.ocommon.log_info_message(msg,self.file_name)

               msg='''Setting the Flag to restart the DB to set DB_UNIQUE_NAME to {0}! '''.format(self.ora_env_dict["DB_UNIQUE_NAME"])
               self.ocommon.log_info_message(msg,self.file_name)
               restart_db_to_set_db_unique_name='true'
               self.ora_env_dict=self.ocommon.add_key("RESTART_DB_TO_SET_DB_UNIQUE_NAME",restart_db_to_set_db_unique_name,self.ora_env_dict)
           else:
               msg="DB_UNIQUE_NAME is not set. Setting DB_UNIQUE_NAME to Oracle_SID"
               self.ocommon.log_info_message(msg,self.file_name)
               dbsid=self.ora_env_dict["ORACLE_SID"]
               self.ora_env_dict=self.ocommon.add_key("DB_UNIQUE_NAME",dbsid,self.ora_env_dict)


      def hostname_check(self):
           """
           Validate and set ORACLE_HOSTNAME.
           """
           if self.ocommon.check_key("ORACLE_HOSTNAME",self.ora_env_dict):
              msg='''ORACLE_HOSTNAME {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["ORACLE_HOSTNAME"])
              self.ocommon.log_info_message(msg,self.file_name)
           else:
              if self.ocommon.check_key("KUBE_SVC",self.ora_env_dict):
                # hostname='''{0}.{1}'''.format(socket.gethostname(),self.ora_env_dict["KUBE_SVC"])
                 hostname='''{0}'''.format(socket.getfqdn())
              else:
                 hostname='''{0}'''.format(socket.gethostname())
              msg='''ORACLE_HOSTNAME is not set, setting it to hostname {0} of the compute!'''.format(hostname)
              self.ora_env_dict=self.ocommon.add_key("ORACLE_HOSTNAME",hostname,self.ora_env_dict)
              self.ocommon.log_info_message(msg,self.file_name)

      def dbport_check(self):
           """
           Validate and set DB_PORT.
           """
           if self.ocommon.check_key("DB_PORT",self.ora_env_dict):
               msg='''DB_PORT {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["DB_PORT"])
               self.ocommon.log_info_message(msg,self.file_name)
           else:
               self.ora_env_dict=self.ocommon.add_key("DB_PORT","1521",self.ora_env_dict)
               msg="DB_PORT is not set, setting default to 1521"
               self.ocommon.log_info_message(msg,self.file_name)

      def dbr_dest_checks(self):
           """
           Validate and set recovery and data file destinations.
           """
           if self.ocommon.check_key("DB_RECOVERY_FILE_DEST",self.ora_env_dict):
               msg='''DB_RECOVERY_FILE_DEST {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["DB_RECOVERY_FILE_DEST"])
               self.ocommon.log_info_message(msg,self.file_name)
               self.ocommon.create_dir(self.ora_env_dict["DB_RECOVERY_FILE_DEST"],True,None,None)
           elif self._is_gpc():
              dest=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "+DATA"
              self.ora_env_dict=self.ocommon.add_key("DB_RECOVERY_FILE_DEST",dest,self.ora_env_dict)
              msg='''DB_RECOVERY_FILE_DEST set to {0}'''.format(dest)
              self.ocommon.log_info_message(msg,self.file_name)
           elif self._is_racdb():
              dest=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "+DATA"
              self.ora_env_dict=self.ocommon.add_key("DB_RECOVERY_FILE_DEST",dest,self.ora_env_dict)  
              msg='''DB_RECOVERY_FILE_DEST set to {0}'''.format(dest)
              self.ocommon.log_info_message(msg,self.file_name)
           else:
               dest='''{0}/oradata/fast_recovery_area/{1}'''.format(self.ora_env_dict["ORACLE_BASE"],self.ora_env_dict["ORACLE_SID"])
               self.ora_env_dict=self.ocommon.add_key("DB_RECOVERY_FILE_DEST",dest,self.ora_env_dict)
               msg='''DB_RECOVERY_FILE_DEST set to {0}'''.format(dest)
               self.ocommon.log_info_message(msg,self.file_name)
               msg='''Checking dir {0} on local machine. If not then create the dir {0} on local machine'''.format(self.ora_env_dict["DB_RECOVERY_FILE_DEST"])
               self.ocommon.log_info_message(msg,self.file_name)
               self.ocommon.create_dir(self.ora_env_dict["DB_RECOVERY_FILE_DEST"],True,None,None)

           # Checking the DB_RECOVERY_FILE_DEST_SIZE

           if self.ocommon.check_key("DB_RECOVERY_FILE_DEST_SIZE",self.ora_env_dict):
               msg='''DB_RECOVERY_FILE_DEST_SIZE {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["DB_RECOVERY_FILE_DEST_SIZE"])
               self.ocommon.log_info_message(msg,self.file_name)
           else:
               self.ora_env_dict=self.ocommon.add_key("DB_RECOVERY_FILE_DEST_SIZE","40G",self.ora_env_dict)
               msg='''DB_RECOVERY_FILE_DEST_SIZE set to {0}'''.format("40G")
               self.ocommon.log_info_message(msg,self.file_name)

           # Checking the DB_CREATE_FILE_DEST

           if self.ocommon.check_key("DB_CREATE_FILE_DEST",self.ora_env_dict):
               msg='''DB_CREATE_FILE_DEST {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["DB_CREATE_FILE_DEST"])
               self.ocommon.log_info_message(msg,self.file_name)
           elif self._is_gpc():
              if self.ocommon.check_key("DB_DATA_FILE_DEST",self.ora_env_dict):
                 dest=self.ora_env_dict["DB_DATA_FILE_DEST"]
              elif self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict):
                 dest=self.ora_env_dict["CRS_ASM_DISKGROUP"]
              else:
                 dest="+DATA"
              self.ora_env_dict=self.ocommon.add_key("DB_CREATE_FILE_DEST",dest,self.ora_env_dict)
              msg='''DB_CREATE_FILE_DEST set to {0}'''.format(dest)
              self.ocommon.log_info_message(msg,self.file_name)
           elif self._is_racdb():
              if self.ocommon.check_key("DB_DATA_FILE_DEST",self.ora_env_dict):
                 dest=self.ora_env_dict["DB_DATA_FILE_DEST"]
              elif self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict):
                 dest=self.ora_env_dict["CRS_ASM_DISKGROUP"]
              else:
                 dest="+DATA"
              self.ora_env_dict=self.ocommon.add_key("DB_CREATE_FILE_DEST",dest,self.ora_env_dict)
              msg='''DB_CREATE_FILE_DEST set to {0}'''.format(dest)
              self.ocommon.log_info_message(msg,self.file_name)
           else:
               dest='''{0}/oradata/{1}'''.format(self.ora_env_dict["ORACLE_BASE"],self.ora_env_dict["ORACLE_SID"])
               self.ora_env_dict=self.ocommon.add_key("DB_CREATE_FILE_DEST",dest,self.ora_env_dict)
               msg='''DB_CREATE_FILE_DEST set to {0}'''.format(dest)
               self.ocommon.log_info_message(msg,self.file_name)
               msg='''Checking dir {0} on local machine. If not then create the dir {0} on local machine'''.format(self.ora_env_dict["DB_CREATE_FILE_DEST"])
               self.ocommon.log_info_message(msg,self.file_name)
               self.ocommon.create_dir(self.ora_env_dict["DB_CREATE_FILE_DEST"],True,None,None)


      def dpump_dir_checks(self):
           """
           Validate and set DATA_PUMP_DIR path.
           """
           if self.ocommon.check_key("DATA_PUMP_DIR",self.ora_env_dict):
               msg='''DATA_PUMP_DIR {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["DATA_PUMP_DIR"])
               self.ocommon.log_info_message(msg,self.file_name)
           else:
               dest='''{0}/oradata/data_pump_dir'''.format(self.ora_env_dict["ORACLE_BASE"])
               self.ora_env_dict=self.ocommon.add_key("DATA_PUMP_DIR",dest,self.ora_env_dict)
               msg='''DATA_PUMP_DIR set to {0}'''.format(dest)
               self.ocommon.log_info_message(msg,self.file_name)
           msg='''Checking dir {0} on local machine. If not then create the dir {0} on local machine'''.format(self.ora_env_dict["DATA_PUMP_DIR"])
           self.ocommon.log_info_message(msg,self.file_name)
           self.ocommon.create_dir(self.ora_env_dict["DATA_PUMP_DIR"],True,None,None)

       ###########  DB_CHECKS  Related Functions Begin Here  ####################


       ## Function to check for RAC DB and populate keys for RAC DB
      def check_for_racdb(self):
         """
           Detect RAC mode and populate COMMA_SEPARATED_CLS_NODES.
         """
         self.ocommon.log_info_message("Running check_for_racdb()",self.file_name)
         if self._is_racdb():
            msg='''CRS_RACDB is set to TRUE. Populating parameters for RAC Database before running scripts for sharding setup'''
            self.ocommon.log_info_message(msg,self.file_name)

            COMMA_SEPARATED_CLS_NODES=self.ocommon.get_all_cls_nodes()
            msg='''Adding Key COMMA_SEPARATED_CLS_NODES with value = {0}'''.format(COMMA_SEPARATED_CLS_NODES)
            self.ocommon.log_info_message(msg,self.file_name)
            self.ora_env_dict=self.ocommon.add_key("COMMA_SEPARATED_CLS_NODES",COMMA_SEPARATED_CLS_NODES,self.ora_env_dict)


       ########## RESET_PASSWORD function Begin here #############################
       ## Function to perform password reset
      def reset_passwd(self):
         """
           Reset catalog passwords based on deployment mode.
         """
         self.ocommon.log_info_message("Running reset_passwd()",self.file_name)
         inst_sid=self.ora_env_dict["ORACLE_SID"]
         ohome=self.ora_env_dict["ORACLE_HOME"]
         if self._is_racdb():
            opdb=self.ora_env_dict["ORACLE_PDB_NAME"]
            # Check if its the first instance of the RAC Database, only then reset the password
            if inst_sid[-1] == '1':
               msg='''Current instance {0} is the Instance 1 of the RAC Database. Password reset will be done on this instance.'''.format(inst_sid)
               self.ocommon.log_info_message(msg,self.file_name)
               self.ocommon.reset_passwd_rac(ohome,opdb,inst_sid)
            else:
               msg='''Current instance {0} is not Instance 1 of the RAC database. Password reset will not be done on this instance.'''.format(inst_sid) 
               self.ocommon.log_info_message(msg,self.file_name)
         elif self._is_gpc():
             opdb=self.ora_env_dict["ORACLE_PDB_NAME"]
             self.ocommon.reset_passwd()
         else:
            opdb=self.ora_env_dict["ORACLE_PDB"]
            self.ocommon.reset_passwd()

       ########## RESET_PASSWORD function ENDS here #############################

       ########## SETUP_CDB_catalog FUNCTION BEGIN HERE ###############################

      def reset_catalog_setup(self):
           """
            Drop setup table when RESET_ENV is requested.
           """
      #     systemStr='''{0}/bin/sqlplus {1}/{2}'''.format(self.ora_env_dict["ORACLE_HOME"],"system",self.ora_env_dict["ORACLE_PWD"])
      #     sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])
             
           sqlpluslogincmd=self._get_sqlplus_sysdba_login()
           self.ocommon.log_info_message("Running reset_catalog_setup()",self.file_name)
           catalog_reset_file='''{0}/.catalog/reset_catalog_completed'''.format(self.ora_env_dict["HOME"])
           if self.ocommon.check_key("RESET_ENV",self.ora_env_dict):
              if self.ora_env_dict["RESET_ENV"]:
                if not os.path.isfile(catalog_reset_file):
                   msg='''Dropping catalogsetup table from CDB'''
                   self.ocommon.log_info_message(msg,self.file_name)
                   sqlcmd='''
                     drop table system.shardsetup;
                    '''
                   output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)
                else:
                    msg='''Reset env is already completed because {0} exists on this machine; skipping reset.'''.format(catalog_reset_file)
                    self.ocommon.log_info_message(msg,self.file_name)


      def catalog_setup_check(self):
           """
            Check whether catalog setup is completed.
           """
           #systemStr='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])

           systemStr=self._get_sqlplus_sysdba_login()
           tmp_dir=self.ora_env_dict["TMP_DIR"]
           msg='''Checking shardsetup table in CDB'''
           self.ocommon.log_info_message(msg,self.file_name)
           sqlcmd='''
            set heading off
            set feedback off
            set  term off
            SET NEWPAGE NONE
            spool {0}/catalog_setup.txt
            select * from system.shardsetup WHERE ROWNUM = 1;
            spool off
            exit;
           '''.format(tmp_dir)
           output,error,retcode=self._run_sqlplus_checked(systemStr,sqlcmd,None)
           fname='''{0}/{1}'''.format(tmp_dir,"catalog_setup.txt")
           fdata=self.ocommon.read_file(fname)
           ### Unsetting the encrypt value to None
         #  self.ocommon.unset_mask_str()

           if re.search('completed',fdata):
              return True
           else:
              return False

      def setup_cdb_catalog(self):
           """
            Configure catalog settings at CDB level.
           """
           #sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])
           self.ocommon.log_info_message("Running setup_cdb_catalog()",self.file_name)
           sqlpluslogincmd=self._get_sqlplus_sysdba_login()
           # Assigning variable
           dbf_dest=self.ora_env_dict["DB_CREATE_FILE_DEST"]
           dbr_dest=self.ora_env_dict["DB_RECOVERY_FILE_DEST"]
           dbr_dest_size=self.ora_env_dict["DB_RECOVERY_FILE_DEST_SIZE"]
           host_name=self.ora_env_dict["ORACLE_HOSTNAME"]
           dpump_dir = self.ora_env_dict["DATA_PUMP_DIR"]
           db_port=self.ora_env_dict["DB_PORT"]
           ohome=self.ora_env_dict["ORACLE_HOME"]
           obase=self.ora_env_dict["ORACLE_BASE"]
           dbuname=self.ora_env_dict["DB_UNIQUE_NAME"]

           self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
           msg='''Setting up catalog CDB'''
           self.ocommon.log_info_message(msg,self.file_name)
           if self._is_racdb():
              # RAC Database case
              sqlcmd='''
                alter system set db_create_file_dest=\"{0}\" scope=both sid='*';
                alter system set db_recovery_file_dest_size={1} scope=both sid='*';
                alter system set db_recovery_file_dest=\"{2}\" scope=both sid='*';
                alter user gsmcatuser account unlock;
                alter user gsmcatuser identified by HIDDEN_STRING;
              '''.format(dbf_dest,dbr_dest_size,dbr_dest,dpump_dir,host_name,db_port,obase,"dbconfig",dbuname)

              if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
                 nodes = self.ora_env_dict["COMMA_SEPARATED_CLS_NODES"].split(",")
                 for value in nodes:
                    #sqlcmd += f"alter system set local_listener='{value}:{db_port}' scope=both sid='{value}';\n"
                    sqlcmd += """alter system set local_listener='{0}:{1}' scope=both sid='{2}';\n""".format(value,db_port,value)
              else:
                 self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
                 self.ocommon.prog_exit("127")
           else:
              sqlcmd='''
                alter system set db_create_file_dest=\"{0}\" scope=both;
                alter system set db_recovery_file_dest_size={1} scope=both;
                alter system set db_recovery_file_dest=\"{2}\" scope=both;
                alter user gsmcatuser account unlock;
                alter user gsmcatuser identified by HIDDEN_STRING;
                alter system set local_listener='{4}:{5}' scope=both;
                alter system set db_unique_name='{8}' scope=spfile;
              '''.format(dbf_dest,dbr_dest_size,dbr_dest,dpump_dir,host_name,db_port,obase,"dbconfig",dbuname)

           output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)

           ### Unsetting the encrypt value to None
           self.ocommon.unset_mask_str()

      def set_spfile_nonm_params(self):
           """
            Set required non-modifiable SPFILE parameters.
           """
           #sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])
           self.ocommon.log_info_message("Running set_spfile_nonm_params()",self.file_name)
           if self.ocommon.check_key("CLONE_DB",self.ora_env_dict):
              if self.ora_env_dict["CLONE_DB"] != 'true':
                  sqlpluslogincmd=self._get_sqlplus_sysdba_login()
                  self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
                  dbf_dest=self.ora_env_dict["DB_CREATE_FILE_DEST"]
                  obase=self.ora_env_dict["ORACLE_BASE"]
                  dbuname=self.ora_env_dict["DB_UNIQUE_NAME"]
                  dskgrp=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "+DATA"
                     
                  msg='''Setting up catalog CDB with spfile non modifiable parameters'''
                  self.ocommon.log_info_message(msg,self.file_name)
                  if self._is_racdb():
                     # RAC Database case
                     sqlcmd='''
                       alter system set open_links_per_instance=16 scope=spfile sid='*';
                       alter system set db_file_name_convert='*','{0}' scope=spfile sid='*';
                       alter system set standby_file_management='AUTO' scope=spfile sid='*';
                       alter system set dg_broker_config_file1=\"{4}/{3}/dr1.dat\" scope=spfile sid='*';
                       alter system set dg_broker_config_file2=\"{4}/{3}/dr2.dat\" scope=spfile sid='*';
                     '''.format(dbf_dest,obase,"dbconfig",dbuname,dskgrp)
                  else:
                     sqlcmd='''
                       alter system set open_links_per_instance=16 scope=spfile;
                       alter system set db_file_name_convert='*','{0}/' scope=spfile;
                       alter system set standby_file_management='AUTO' scope=spfile;
                       alter system set dg_broker_config_file1=\"{1}/oradata/{2}/{3}/dr1{3}.dat\" scope=spfile;
                       alter system set dg_broker_config_file2=\"{1}/oradata/{2}/{3}/dr2{3}.dat\" scope=spfile;
                     '''.format(dbf_dest,obase,"dbconfig",dbuname)

                  output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)

         
      def set_dbparams_version(self):
           """
            Set version-specific database parameters.
           """
           self.ocommon.log_info_message("Running set_dbparams_version()",self.file_name)
           ohome1=self.ora_env_dict["ORACLE_HOME"]
           version=self.ocommon.get_oraversion(ohome1).strip()
           self.ocommon.log_info_message(version,self.file_name)
           if int(version) > 12:
              sqlpluslogincmd=self._get_sqlplus_sysdba_login()
              self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
              dbf_dest=self.ora_env_dict["DB_CREATE_FILE_DEST"]
              obase=self.ora_env_dict["ORACLE_BASE"]
              dbuname=self.ora_env_dict["DB_UNIQUE_NAME"]

              msg='''Setting up catalog CDB with spfile non modifiable parameters based on version'''
              self.ocommon.log_info_message(msg,self.file_name)

              if self._is_racdb():
##############This can be implemented once the support for wallet_root for ASM Diskgroup is implemented, Until then, we need to keep the wallet_root pointing to a disk location
#                 sqlcmd='''
#                   alter system set wallet_root=\"{0}/{3}\" scope=spfile sid='*';
#                 '''.format(dbf_dest,obase,"dbconfig",dbuname)

                 sqlcmd='''
                   alter system set wallet_root=\"{1}/oradata/{2}/{3}\" scope=spfile sid='*';
                 '''.format(dbf_dest,obase,"dbconfig",dbuname)
                 output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)
              else:
                 sqlcmd='''
                   alter system set wallet_root=\"{1}/oradata/{2}/{3}\" scope=spfile;
                 '''.format(dbf_dest,obase,"dbconfig",dbuname)
                 output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)

      def restart_db(self):
          """
          Restart the database instance(s).
          """ 
          self.ocommon.log_info_message("Running restart_db()",self.file_name)
          #if self.ocommon.check_key("CLONE_DB",self.ora_env_dict):
          #  if self.ora_env_dict["CLONE_DB"] != 'true':
          if self._is_racdb():
              # Its RAC Database
              dbuser=self.ora_env_dict["ORA_DB_USER"]
              dbhome=self.ora_env_dict["ORACLE_HOME"]
              dbuname=self.ora_env_dict["DB_UNIQUE_NAME"]
              hostname='''{0}'''.format(socket.gethostname())
              self.ocommon.log_info_message("Calling stop_rac_db() to shut down the RAC database",self.file_name)
              self.ocommon.stop_rac_db(dbuser,dbhome,dbuname,hostname)
              self.ocommon.log_info_message("Calling start_rac_db() to start the RAC database",self.file_name)
              self.ocommon.start_rac_db(dbuser,dbhome,dbuname,hostname,None)
          else:
              self.ocommon.log_info_message("Calling shutdown_db() to shut down the database",self.file_name)
              self.ocommon.shutdown_db(self.ora_env_dict)
              self.ocommon.log_info_message("Calling start_db() to start the database",self.file_name)
              self.ocommon.start_db(self.ora_env_dict)

            #self.ocommon.log_info_message("Enabling archivelog at DB level",self.file_name)
            #sqlcmd='''
            # alter database archivelog;
            # alter database open;
            #'''
            #output,error,retcode=self.ocommon.run_sqlplus(sqlpluslogincmd,sqlcmd,None)
            #self.ocommon.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
            #self.ocommon.check_sql_err(output,error,retcode,True)

      def restart_for_db_unique_name(self):
          """
          Restart DB when DB_UNIQUE_NAME was explicitly provided.
          """
          self.ocommon.log_info_message("Running restart_for_db_unique_name()",self.file_name)
          if self._is_racdb():
             self.ocommon.log_info_message("It is a RAC Database and DB_UNIQUE_NAME being mandatory parameter was already set. No need to restart to set DB_UNIQUE_NAME",self.file_name)
          else:
             if self.ocommon.check_key("RESTART_DB_TO_SET_DB_UNIQUE_NAME",self.ora_env_dict):
                 if self.ora_env_dict["RESTART_DB_TO_SET_DB_UNIQUE_NAME"] == 'true':
                     msg='''DB_UNIQUE_NAME {0} is passed as an env variable. Restarting the Database to set the DB_UNIQUE_NAME! '''.format(self.ora_env_dict["DB_UNIQUE_NAME"])
                     self.ocommon.log_info_message(msg,self.file_name)

                     self.ocommon.log_info_message("Calling shutdown_db() to shut down the database",self.file_name)
                     self.ocommon.shutdown_db(self.ora_env_dict)
                     self.ocommon.log_info_message("Calling start_db() to start the database",self.file_name)
                     self.ocommon.start_db(self.ora_env_dict)

      def create_pdb(self):
         """
         Create PDB when it does not exist.
         """
         self.ocommon.log_info_message("Running create_pdb()",self.file_name)
         if self._is_racdb():
            # RAC Database Case, FREE PDB is NOT supported
            dbname=self.ora_env_dict["DB_NAME"]
            ohome=self.ora_env_dict["ORACLE_HOME"]
            opdb=self.ora_env_dict["ORACLE_PDB"]
            status=self.ocommon.check_pdb(opdb)
            if not status:
              msg='''PDB {0} does not exist. Creating the PDB..'''.format(opdb)
              self.ocommon.log_info_message(msg,self.file_name)
              self.ocommon.create_pdb(ohome,opdb,dbname)
              for node in self._require_cluster_nodes():
                     self.ocommon.create_pdb_tns_entry_racdb(ohome,opdb,node)
            else:
              msg='''PDB {0} already exists.'''.format(opdb)
              self.ocommon.log_info_message(msg,self.file_name)  
         else:
            inst_sid=self.ora_env_dict["ORACLE_SID"]
            ohome=self.ora_env_dict["ORACLE_HOME"]
            if self.ocommon.check_key("ORACLE_FREE_PDB",self.ora_env_dict):
               self.ora_env_dict=self.ocommon.update_key("ORACLE_PDB",self.ora_env_dict["ORACLE_FREE_PDB"],self.ora_env_dict)
               opdb=self.ora_env_dict["ORACLE_PDB"]
               status=self.ocommon.check_pdb(opdb)
               if not status:
                 self.ocommon.create_pdb(ohome,opdb,inst_sid)
                 self.ocommon.create_pdb_tns_entry(ohome,opdb)
                                     
      def alter_db(self):
          """
          Enable required database modes for sharding.
          """
          self.ocommon.log_info_message("Running alter_db()",self.file_name)
          sqlpluslogincmd=self._get_sqlplus_sysdba_login()
          self.ocommon.log_info_message("Enabling flashback and force logging at DB level",self.file_name)
          if self._is_racdb():
              # RAC DB Case
              sqlcmd='''
                alter database flashback on;
                alter database force logging;
                ALTER PLUGGABLE DATABASE ALL OPEN INSTANCES=ALL;
              '''
          else:
              sqlcmd='''
                alter database flashback on;
                alter database force logging;
                ALTER PLUGGABLE DATABASE ALL OPEN;
              '''
          output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,None)
                           
      def setup_pdb_catalog(self):
           """
            Configure catalog users/settings at PDB level.
           """
           self.ocommon.log_info_message("Running setup_pdb_catalog()",self.file_name)
           sqlpluslogincmd=self._get_sqlplus_sysdba_login()
           # Assigning variable
           self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])

           if self._is_racdb():
               # RAC DB case
               if self.ocommon.check_key("ORACLE_PDB",self.ora_env_dict):
                  msg='''Setting up catalog PDB'''
                  self.ocommon.log_info_message(msg,self.file_name)
                  sqlcmd='''
                  alter pluggable database {0} close immediate instances=all;
                  alter pluggable database {0} open services=All;
                  alter pluggable database {0} open instances=all;
                  ALTER PLUGGABLE DATABASE {0} SAVE STATE;
                  alter session set container={0};
                  create user {1} identified by HIDDEN_STRING;
                  alter user {1} account unlock;
                  grant connect, create session, gsmadmin_role to {1};
                  grant inherit privileges on user SYS to GSMADMIN_INTERNAL;
                  execute dbms_xdb.sethttpport(8080);
                  exec DBMS_SCHEDULER.SET_AGENT_REGISTRATION_PASS('HIDDEN_STRING');
                  exit;
                  '''.format(self.ora_env_dict["ORACLE_PDB"],self.ora_env_dict["SHARD_ADMIN_USER"])

                  output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)

                  # Handle to run "alter system register" for all instances of RAC DB
                  if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
                     self.ocommon.log_info_message("Running alter system register for all instances of RAC DB",self.file_name)
                     osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
                     dbname,osid,dbuname=self.ocommon.getdbnameinfo()
                     for hostname in self._require_cluster_nodes():
                        inst_sid=self.ocommon.get_inst_sid(osuser,dbhome,osid,hostname)
                        cmd='''ssh {0}@{1} "export ORACLE_SID={2}; $ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
set heading off;
set pagesize 0;
alter system register;
alter session set container={3};
alter system register;
exit;
EOF"
'''.format(osuser,hostname,inst_sid,self.ora_env_dict["ORACLE_PDB"])
                        self.ocommon.log_info_message("Validating OS command return status via check_os_err()",self.file_name)
                        self._exec_cmd_checked(cmd,None)
                        self.ocommon.unset_mask_str()
                  else:
                     self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
                     self.ocommon.prog_exit("127")

           elif self.ocommon.check_key("ORACLE_PDB",self.ora_env_dict):
               msg='''Setting up catalog PDB'''
               self.ocommon.log_info_message(msg,self.file_name)
               sqlcmd='''
               alter pluggable database {0} close immediate;
               alter pluggable database {0} open services=All;
               ALTER PLUGGABLE DATABASE {0} SAVE STATE;
               alter system register;
               alter session set container={0};
               create user {1} identified by HIDDEN_STRING;
               alter user {1} account unlock;
               grant connect, create session, gsmadmin_role to {1};
               grant inherit privileges on user SYS to GSMADMIN_INTERNAL;
               execute dbms_xdb.sethttpport(8080);
               exec DBMS_SCHEDULER.SET_AGENT_REGISTRATION_PASS('HIDDEN_STRING');
               alter system register;
               exit;
               '''.format(self.ora_env_dict["ORACLE_PDB"],self.ora_env_dict["SHARD_ADMIN_USER"])

               output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)

           ### Unsetting the encrypt value to None
           self.ocommon.unset_mask_str()

      def update_catalog_setup(self):
           """
            Update catalog setup status table.
            * For RAC DB, runs from the first node as part of setup scripts.
           """
       #    systemStr='''{0}/bin/sqlplus {1}/{2}'''.format(self.ora_env_dict["ORACLE_HOME"],"system","HIDDEN_STRING")
      #     systemStr='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])
           
           self.ocommon.log_info_message("Running update_catalog_setup()",self.file_name)
           systemStr=self._get_sqlplus_sysdba_login()
           msg='''Updating shardsetup table'''
           self.ocommon.log_info_message(msg,self.file_name)
           sqlcmd='''
            set heading off
            set feedback off
            create table system.shardsetup (status varchar2(10));
            insert into system.shardsetup values('completed');
            commit;
            exit;
           '''
           output,error,retcode=self._run_sqlplus_checked(systemStr,sqlcmd,True)

           ### Reset File
           catalog_reset_dir='''{0}/.catalog'''.format(self.ora_env_dict["HOME"])
           catalog_reset_file='''{0}/.catalog/reset_catalog_completed'''.format(self.ora_env_dict["HOME"])

           self.ocommon.log_info_message("Creating reset file if it does not exist",self.file_name)
           if not os.path.isdir(catalog_reset_dir):
              self.ocommon.create_dir(catalog_reset_dir,True,None,None)

           if not os.path.isfile(catalog_reset_file):
              self.ocommon.create_file(catalog_reset_file,True,None,None)

#          self.ocommon.unset_mask_str()

       ########## SETUP_CDB_catalog FUNCTION ENDS HERE ###############################

          ###################################### Run custom scripts ##################################################
      def run_custom_scripts(self):
          """
           Execute custom shard script when configured.
           * For RAC DB, runs from the first node as part of setup scripts.
          """
          self.ocommon.log_info_message("Running run_custom_scripts()",self.file_name)
          if self.ocommon.check_key("CUSTOM_SHARD_SCRIPT_DIR",self.ora_env_dict):
             shard_dir=self.ora_env_dict["CUSTOM_SHARD_SCRIPT_DIR"]
             if self.ocommon.check_key("CUSTOM_SHARD_SCRIPT_FILE",self.ora_env_dict):
                shard_file=self.ora_env_dict["CUSTOM_SHARD_SCRIPT_FILE"]
                script_file = '''{0}/{1}'''.format(shard_dir,shard_file)
                if os.path.isfile(script_file):
                   msg='''Custom shard script exist {0}'''.format(script_file)
                   self.ocommon.log_info_message(msg,self.file_name)
                   cmd='''sh {0}'''.format(script_file)
                   output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                   self.ocommon.check_os_err(output,error,retcode,True)

      def set_primary_listener(self):
          """
           Configure listener static registration entries.
          """
          self.ocommon.log_info_message("Running set_primary_listener()",self.file_name)
          if self._is_racdb():
              # RAC DB Case
              if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
                  global_dbname=self.ocommon.get_global_dbdomain(self.ora_env_dict["ORACLE_HOSTNAME"],self.ora_env_dict["DB_UNIQUE_NAME"])
                  osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
                  dbname,osid,dbuname=self.ocommon.getdbnameinfo()
                  for node in self._require_cluster_nodes():
                      msg='''Calling set_db_listener_racdb for node {0} '''.format(node)
                      self.ocommon.log_info_message(msg,self.file_name)
                      inst_sid=self.ocommon.get_inst_sid(osuser,dbhome,osid,node)
                      self.set_db_listener_racdb(global_dbname,dbhome,inst_sid,node)
              else:
                  self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
                  self.ocommon.prog_exit("127")
          elif self._is_gpc():
              global_dbname=self.ocommon.get_global_dbdomain(self.ora_env_dict["ORACLE_HOSTNAME"],self.ora_env_dict["DB_UNIQUE_NAME"])
              osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
              dbname,osid,dbuname=self.ocommon.getdbnameinfo()
              msg='''Calling set_db_listener_racdb for GPC node {0} '''.format(self.ora_env_dict["ORACLE_HOSTNAME"])
              self.ocommon.log_info_message(msg,self.file_name)
              inst_sid=self.ocommon.get_inst_sid(osuser,dbhome,osid,self.ora_env_dict["ORACLE_HOSTNAME"])
              self.set_db_listener_racdb(global_dbname,dbhome,inst_sid,self.ora_env_dict["ORACLE_HOSTNAME"])
          else:
              global_dbname=self.ocommon.get_global_dbdomain(self.ora_env_dict["ORACLE_HOSTNAME"],self.ora_env_dict["DB_UNIQUE_NAME"] + "_DGMGRL")
              self.set_db_listener(global_dbname,self.ora_env_dict["DB_UNIQUE_NAME"])
              global_dbname=self.ocommon.get_global_dbdomain(self.ora_env_dict["ORACLE_HOSTNAME"],self.ora_env_dict["DB_UNIQUE_NAME"])
              self.set_db_listener(global_dbname,self.ora_env_dict["DB_UNIQUE_NAME"])

      def set_db_listener(self,gdbname,sid):
          """
           Set listener.ora static service entries for single-instance DB.
          """
          self.ocommon.log_info_message("Running set_db_listener()",self.file_name)
          start = 'SID_LIST_LISTENER'
          end = r'^\)$'
          oracle_home=self.ora_env_dict["ORACLE_HOME"]
          lisora='''{0}/network/admin/listener.ora'''.format(oracle_home)
          buffer = "SID_LIST_LISTENER=" + '\n'
          start_flag = False
          try:
            with open(lisora) as f:
              for line1 in f:
                if start_flag == False:
                   if (re.match(start, line1.strip())):
                      start_flag = True
                elif (re.match(end, line1.strip())):
                   line2 = next(f)
                   if (re.match(end, line2.strip())):
                      break
                   else:
                      buffer += line1
                      buffer += line2
                else:
                   if start_flag == True:
                      buffer += line1
          except:
            pass

          if start_flag == True:
              buffer +=  self.ocommon.get_sid_desc(gdbname,oracle_home,sid,"SID_DESC1")
              listener =  self.ocommon.get_lisora(1521)
              listener += '\n' + buffer
          else:
              buffer += self.ocommon.get_sid_desc(gdbname,oracle_home,sid,"SID_DESC")
              listener =  self.ocommon.get_lisora(1521)
              listener += '\n' + buffer

          with open(lisora, 'w') as wr:
             wr.write(listener)


      def set_db_listener_racdb(self,gdbname,ohome,sid,node):
          """
           Add listener static service entry for RAC/GPC node.
          """
          self.ocommon.log_info_message("Running set_db_listener_racdb()",self.file_name)
          giuser=self.ora_env_dict["GRID_USER"]
          static_services_entry='''
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = {0}_DGMGRL
      (ORACLE_HOME = {1})
      (SID_NAME = {2})
    )
  )'''.format(gdbname,ohome,sid)
          oracle_home=self.ora_env_dict["GRID_HOME"]
          lisora='''{0}/network/admin/listener.ora'''.format(oracle_home)
          #remote_cmd = f"ssh {giuser}@{node} 'echo \"{static_services_entry}\" >> {lisora}'"
          #cmd = f'sudo -u {giuser} {remote_cmd}'
          remote_cmd = """ssh {0}@{1} 'echo \"{2}\" >> {3}'""".format(giuser,node,static_services_entry,lisora)
          cmd = '''sudo -u {0} {1}'''.format(giuser,remote_cmd)
          self._exec_cmd_checked(cmd,True)
          msg='''Successfully added tns entry on {0}'''.format(node)
          self.ocommon.log_info_message(msg,self.file_name)

      def restart_listener(self):
          """
          Restart listener(s) based on deployment mode.
          """
          self.ocommon.log_info_message("Running restart_listener()",self.file_name)
          if self._is_racdb():
              # RAC DB Case
              if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
                  for node in self._require_cluster_nodes():
                      msg='''Stopping Listener on node {0}'''.format(node)
                      self.ocommon.log_info_message(msg,self.file_name)
                      self._run_remote_grid_listener_cmd(node,"stop",True)

                      msg='''Starting Listener on node {0}'''.format(node)
                      self.ocommon.log_info_message(msg,self.file_name)
                      self._run_remote_grid_listener_cmd(node,"start",True)
              else:
                  self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
                  self.ocommon.prog_exit("127")
          elif self._is_gpc():
              node=self.ora_env_dict["ORACLE_HOSTNAME"]
              msg='''Stopping Listener on GPC node {0}'''.format(node)
              self.ocommon.log_info_message(msg,self.file_name)
              self._run_remote_grid_listener_cmd(node,"stop",True)

              msg='''Starting Listener on GPC node {0}'''.format(node)
              self.ocommon.log_info_message(msg,self.file_name)
              self._run_remote_grid_listener_cmd(node,"start",True)
          else:
              self.ocommon.log_info_message("Stopping Listener",self.file_name)
              ohome=self.ora_env_dict["ORACLE_HOME"]
              cmd='''{0}/bin/lsnrctl stop'''.format(ohome)
              self._exec_cmd_checked(cmd,None)

              self.ocommon.log_info_message("Starting Listener",self.file_name)   
              ohome=self.ora_env_dict["ORACLE_HOME"]
              cmd='''{0}/bin/lsnrctl start'''.format(ohome)
              self._exec_cmd_checked(cmd,None)


      def register_services(self):
           """
            Register database services with listener(s).
           """
           #sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])
           # Assigning variable
           self.ocommon.log_info_message("Running register_services()",self.file_name)
           if self._is_racdb():
               # RAC DB Case
               if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
                     self.ocommon.log_info_message("Running alter system register for all instances of RAC DB",self.file_name)
                     osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
                     dbname,osid,dbuname=self.ocommon.getdbnameinfo()
                     for hostname in self._require_cluster_nodes():
                        self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
                        inst_sid=self.ocommon.get_inst_sid(osuser,dbhome,osid,hostname)
                        cmd='''ssh {0}@{1} "export ORACLE_SID={2}; $ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
set heading off;
set pagesize 0;
alter system register;
alter session set container={3};
alter system register;
exit;
EOF"
'''.format(osuser,hostname,inst_sid,self.ora_env_dict["ORACLE_PDB"])
                        self.ocommon.log_info_message("Validating OS command return status via check_os_err()",self.file_name)
                        self._exec_cmd_checked(cmd,None)
                        self.ocommon.unset_mask_str()
               else:
                  self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
                  self.ocommon.prog_exit("127")
           else:
               sqlpluslogincmd=self._get_sqlplus_sysdba_login()
               self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
               if self.ocommon.check_key("ORACLE_PDB",self.ora_env_dict):
                  msg='''Setting up catalog PDB'''
                  self.ocommon.log_info_message(msg,self.file_name)
                  sqlcmd='''
                  alter system register;
                  alter session set container={0};
                  alter system register;
                  exit;
                  '''.format(self.ora_env_dict["ORACLE_PDB"],self.ora_env_dict["SHARD_ADMIN_USER"])

                  output,error,retcode=self._run_sqlplus_checked(sqlpluslogincmd,sqlcmd,True)

           ### Unsetting the encrypt value to None
           self.ocommon.unset_mask_str()

      def list_services(self):
          """
          List listener services based on deployment mode.
          """
          self.ocommon.log_info_message("Running list_services()",self.file_name)
          if self._is_racdb():
              # RAC DB Case
              if self.ocommon.check_key("COMMA_SEPARATED_CLS_NODES",self.ora_env_dict):
                  for node in self._require_cluster_nodes():
                      msg='''Listing services on node {0}'''.format(node)
                      self.ocommon.log_info_message(msg,self.file_name)
                      self._run_remote_grid_listener_cmd(node,"services",True)
              else:
                  self.ocommon.log_error_message("Key COMMA_SEPARATED_CLS_NODES not found. Exiting!",self.file_name)
                  self.ocommon.prog_exit("127")
          elif self._is_gpc():
              node=self.ora_env_dict["ORACLE_HOSTNAME"]
              msg='''Listing services on GPC node {0}'''.format(node)
              self.ocommon.log_info_message(msg,self.file_name)
              self._run_remote_grid_listener_cmd(node,"services",True)
          else:
              self.ocommon.log_info_message("Listing Services",self.file_name)
              ohome=self.ora_env_dict["ORACLE_HOME"]
              cmd='''{0}/bin/lsnrctl services'''.format(ohome)
              self._exec_cmd_checked(cmd,None)


      def backup_files(self):
          """
           Back up key DB/network config files under `oradata/dbconfig`.
          """
          self.ocommon.log_info_message("Running backup_files()",self.file_name)
          if self._is_racdb():
              # RAC DB Case
              msg='''This is a RAC database. Skipping backup_files() step.'''
              self.ocommon.log_info_message(msg,self.file_name)
          else:
              ohome=self.ora_env_dict["ORACLE_HOME"]
              obase=self.ora_env_dict["ORACLE_BASE"]
              dbuname=self.ora_env_dict["DB_UNIQUE_NAME"]
              dbsid=self.ora_env_dict["ORACLE_SID"]

              version=self.ocommon.get_oraversion(ohome).strip()
              wallet_backup_cmd='''ls -ltr /bin'''
              self.ocommon.log_info_message("Check Version " + version,self.file_name)
              if int(version) >= 21:
                 obase1=self.ora_env_dict["ORACLE_BASE"]
                 wallet_backup_cmd='''cp -r {3}/admin/ {0}/oradata/{1}/{2}/'''.format(obase,"dbconfig",dbuname,ohome)
              cmd_names='''
                   mkdir -p {0}/oradata/{1}/{2}
                   cp {3}/dbs/spfile{2}.ora {0}/oradata/{1}/{2}/
                   cp {3}/dbs/orapw{2}   {0}/oradata/{1}/{2}/
                   cp {3}/network/admin/sqlnet.ora {0}/oradata/{1}/{2}/
                   cp {3}/network/admin/listener.ora {0}/oradata/{1}/{2}/
                   cp {3}/network/admin/tnsnames.ora {0}/oradata/{1}/{2}/
                   touch {0}/oradata/{1}/{2}/status_completed
              '''.format(obase,"dbconfig",dbuname,ohome)
              cmd_list = [y for y in (x.strip() for x in cmd_names.splitlines()) if y]
              for cmd in cmd_list:
                 msg='''Executing cmd {0}'''.format(cmd)
                 self.ocommon.log_info_message(msg,self.file_name)
                 output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)           

      ############################### GSM Completion Message #######################################################
      def gsm_completion_message(self):
          """
           Print setup completion message.
           * For RAC DB, runs from the first node as part of setup scripts.
          """
          self.ocommon.log_info_message("Running gsm_completion_message()",self.file_name)
          msg=[]
          msg.append('==============================================')
          msg.append('     GSM Catalog Setup Completed              ')
          msg.append('==============================================')

          for text in msg:
              self.ocommon.log_info_message(text,self.file_name)
