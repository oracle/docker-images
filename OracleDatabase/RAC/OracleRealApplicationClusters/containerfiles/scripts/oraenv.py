#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file read the env variables from a file or using env command and populate them in  variable 
"""

import os

class OraEnv:
   __instance                                  = None
   __env_var_file                              = '/etc/rac_env_vars'
   __env_var_file_flag                         = None
   __env_var_dict                              = {}
   __ora_asm_diskgroup_name                    = '+DATA'
   __ora_gimr_flag                             = 'false' 
   __ora_grid_user                             = 'grid'
   __ora_db_user                               = 'oracle'
   __ora_oinstall_group_name                   = 'oinstall'
   encrypt_str__                               = None
   original_str__                              = None
   logdir__                                    = "/tmp/orod"
   
   def __init__(self):
      """ Virtually private constructor. """
      if OraEnv.__instance != None:
         raise Exception("This class is a singleton!")
      else:
         OraEnv.__instance = self
         OraEnv.read_variable()
         OraEnv.add_variable()
         try:  
          os.mkdir(OraEnv.logdir__)  
         except OSError as error:
          pass

   @staticmethod 
   def get_instance():
      """ Static access method. """
      if OraEnv.__instance == None:
         OraEnv()
      return OraEnv.__instance

   @staticmethod
   def read_variable():
      """ Read the variables from a file into dict """
      if OraEnv.__env_var_file_flag:
        with open(OraEnv.__env_var_file) as envfile:
           for line in envfile:
               name, var = line.partition("=")[::2]
               OraEnv.__env_var_dict[name.strip()] = var 
      else:
         OraEnv.__env_var_dict = os.environ

   @staticmethod
   def add_variable():
      """ Add more variable ased on enviornment with default values in __env_var_dict"""
      if "ORA_ASM_DISKGROUP_NAME" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["ORA_ASM_DISKGROUP_NAME"] = "+DATA"
 
      if "ORA_GRID_USER" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["GRID_USER"] = "grid"

      if "ORA_DB_USER" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["DB_USER"] = "oracle"
 
      if "ORA_OINSTALL_GROUP_NAME" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["OINSTALL"] = "oinstall"

   @staticmethod
   def add_custom_variable(key,val):
      """ Addcustom  more variable passed from main.py values in __env_var_dict"""
      if key not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict[key] = val

   @staticmethod
   def update_key(key,val):
      """ Updating key variable passed from main.py values in __env_var_dict"""
      OraEnv.__env_var_dict[key] = val

   @staticmethod
   def get_env_vars():
      """ Static access method to get the env vars. """
      return OraEnv.__env_var_dict

   @staticmethod
   def update_env_vars(env_dict):
      """ Static access method to get the env vars. """
      OraEnv.__env_var_dict = env_dict

   @staticmethod
   def get_env_dict():
      """ Static access method t return the dict. """
      return OraEnv.__env_var_dict

   @staticmethod
   def get_log_dir():
      """ Static access method to return the logdir. """
      return OraEnv.logdir__
   
   @staticmethod
   def statelogfile_name():
      """ Static access method to return the state logfile name. """
      if "STATE_LOGFILE_NAME" not in OraEnv.__env_var_dict:
         return OraEnv.logdir__ + "/.statefile"
      else:
         return OraEnv.__env_var_dict["STATE_LOGFILE_NAME"]
      
   @staticmethod
   def logfile_name(file_type):
      """ Static access method to return the logfile name. """
      if file_type == "NONE":
         if "LOGFILE_NAME"  not in OraEnv.__env_var_dict:
             OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_db_setup.log"
      elif file_type == "DEL_PARAMS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_db_del.log"
      elif file_type == "RESET_PASSWORD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_db_reset_passwd.log"
      elif file_type == "ADD_TNS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_db_populate_tns_file.log"
      elif file_type == "CHECK_RAC_INST":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_check_rac_inst_file.log"
      elif file_type == "CHECK_GI_LOCAL":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_check_gi_local_file.log"
      elif file_type == "CHECK_RAC_DB":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_check_rac_db_file.log"
      elif file_type == "CHECK_DB_ROLE":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_check_db_role.log"
      elif file_type == "CHECK_CONNECT_STR":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_check_conn_str_file.log"
      elif file_type == "CHECK_PDB_CONNECT_STR":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_check_pdb_conn_str_file.log"
      elif file_type == "SETUP_DB_LSNR":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/setup_db_lsnr.log"
      elif file_type == "SETUP_LOCAL_LSNR":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/setup_local_lsnr.log"
      elif file_type == "CHECK_DB_VERSION":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/check_db_version.log"
      elif file_type == "CHECK_DB_SVC":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/check_db_svc.log"
      elif file_type == "MODIFY_DB_SVC":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/modify_db_svc.log"
      elif file_type == "CHECK_RAC_STATUS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/check_racdb_status.log"
      elif file_type == "MODIFY_SCAN":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_modify_scan_status.log"
      elif file_type == "UPDATE_ASMCOUNT":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_update_asmcount_status.log"
      elif file_type == "UPDATE_ASMDEVICES":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_update_asmdevices_status.log"
      elif file_type == "UPDATE_LISTENERENDP":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_update_listenerendp_status.log"
      elif file_type == "LIST_ASMDG":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_list_asmdg_status.log"
      elif file_type == "LIST_ASMDISKS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_list_asmdisks_status.log"
      elif file_type == "LIST_ASMDGREDUNDANCY":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_list_asmdgredundancy_status.log"
      elif file_type == "LIST_ASMINSTNAME":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_list_asminstname_status.log"
      elif file_type == "LIST_ASMINSTSTATUS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_list_amsinst_status.log"         
      elif file_type == "UPDATE_LISTENERENDP":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_update_listenerendp_status.log"
      elif file_type == "RUN_DATAPATCH":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_rundatapatch_status.log"
      elif file_type == "ONS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_ons_status.log"
      else:
        pass

      return OraEnv.__env_var_dict["LOG_FILE_NAME"]