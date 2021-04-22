#!/usr/bin/python

#############################
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
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
   logdir__                                    = "/tmp/sharding"
   
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
         OraEnv.__env_var_dict["ORA_GRID_USER"] = "grid"

      if "ORA_DB_USER" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["ORA_DB_USER"] = "oracle"
 
      if "ORA_OINSTALL_GROUP_NAME" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["ORA_OINSTALL_GROUP_NAME"] = "oinstall"

   @staticmethod
   def add_custom_variable(key,val):
      """ Addcustom  more variable passed from main.py values in __env_var_dict"""
      if key not in OraEnv.__env_var_dict:
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
   def logfile_name(file_type):
      """ Static access method to return the logfile name. """
      if file_type == "NONE":
         if "LOGFILE_NAME"  not in OraEnv.__env_var_dict:
             OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/oracle_sharding_setup.log"
      elif file_type == "ADD_SHARD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/shard_addition.log"
      elif file_type == "VALIDATE_SHARD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/shard_validation.log"
      elif file_type == "REMOVE_SHARD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/shard_remove.log"
      elif file_type == "CHECK_LIVENESS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/shard_checkliveness.log"
      elif file_type == "RESET_LISTENER":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/reset_listener.log"
      elif file_type == "RESTART_DB":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/restart_db.log"
      elif file_type == "CREATE_DIR":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/create_dir.log"
      elif file_type == "ADD_SGROUP_PARAMS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/add_sgroup.log"
      elif file_type == "DEPLOY_SHARD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/deploy_shard.log"
      elif file_type == "CANCEL_CHUNKS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/cancel_chunk.log"
      elif file_type == "MOVE_CHUNKS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/move_chunks.log"
      elif file_type == "CHECK_CHUNKS":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/check_chunks.log"
      elif file_type == "CHECK_ONLINE_SHARD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/check_online_shard.log"
      elif file_type == "CHECK_GSM_SHARD":
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = OraEnv.logdir__ + "/check_gsm_shard.log"
      else:
        pass

      return OraEnv.__env_var_dict["LOG_FILE_NAME"]
