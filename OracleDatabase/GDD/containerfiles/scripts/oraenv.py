#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

"""
 This file read the env variables from a file or using env command and populate them in  variable 
"""

import os

class OraEnv:
   __instance                                  = None
   __env_var_file                              = '/etc/rac_env_vars'
   __env_var_file_flag                         = None
   __env_var_dict                              = {}
   encrypt_str__                               = None
   original_str__                              = None
   logdir__                                    = "/var/tmp/gdd"
   tmpdir__                                    = "/tmp"

   __default_vars                              = {
      "ORA_ASM_DISKGROUP_NAME": "+DATA",
      "ORA_GRID_USER": "grid",
      "ORA_DB_USER": "oracle",
      "ORA_OINSTALL_GROUP_NAME": "oinstall",
   }

   __logfile_map                               = {
      "NONE": "oracle_sharding_setup.log",
      "ADD_SHARD": "shard_addition.log",
      "VALIDATE_SHARD": "shard_validation.log",
      "REMOVE_SHARD": "shard_remove.log",
      "CHECK_LIVENESS": "shard_checkliveness.log",
      "CHECK_READYNESS": "shard_checkreadyness.log",
      "RESET_LISTENER": "reset_listener.log",
      "RESTART_DB": "restart_db.log",
      "CREATE_DIR": "create_dir.log",
      "ADD_SGROUP_PARAMS": "add_sgroup.log",
      "DEPLOY_SHARD": "deploy_shard.log",
      "CANCEL_CHUNKS": "cancel_chunk.log",
      "MOVE_CHUNKS": "move_chunks.log",
      "CHECK_CHUNKS": "check_chunks.log",
      "CHECK_ONLINE_SHARD": "check_online_shard.log",
      "CHECK_GSM_SHARD": "check_gsm_shard.log",
      "INVITED_NODE_OP": "node_invited_op.log",
      "RESET_PASSWD": "reset_passwd_file.log",
      "TDE_KEY": "tde_key.log",
      "PRE_STANDBY_SETUP": "pre_standby_setup.log",
   }
   
   def __init__(self):
      """ Virtually private constructor. """
      if OraEnv.__instance != None:
         raise Exception("This class is a singleton!")
      else:
         OraEnv.__instance = self
         OraEnv.read_variable()
         OraEnv._initialize_logdir()
         OraEnv._initialize_tmpdir()
         OraEnv.add_variable()
         OraEnv._ensure_logdir()

   @staticmethod 
   def get_instance():
      """ Static access method. """
      if OraEnv.__instance == None:
         OraEnv()
      return OraEnv.__instance

   @staticmethod
   def _initialize_logdir():
      """
      Resolve log directory from env with fallback to /var/log/gdd.
      If /var/log/gdd does not exist, use /var/tmp/gdd.
      """
      env = OraEnv.__env_var_dict
      log_dir = None
      for key in ("LOG_DIR", "LOGDIR", "SHARDING_LOG_DIR"):
         if key in env and str(env[key]).strip():
            log_dir = str(env[key]).strip()
            break

      if not log_dir:
         if os.path.isdir("/var/log/gdd"):
            log_dir = "/var/log/gdd"
         else:
            log_dir = "/var/tmp/gdd"

      OraEnv.logdir__ = log_dir
      OraEnv.__env_var_dict["LOG_DIR"] = OraEnv.logdir__

   @staticmethod
   def _ensure_logdir():
      """
      Ensure only fallback log directory exists.
      """
      try:
         if OraEnv.logdir__ == "/var/tmp/gdd" and not os.path.isdir(OraEnv.logdir__):
            os.makedirs(OraEnv.logdir__)
      except OSError:
         pass

   @staticmethod
   def _initialize_tmpdir():
      """
      Resolve temporary directory from env with fallback to /tmp.
      """
      env = OraEnv.__env_var_dict
      tmp_dir = None
      for key in ("TMP_DIR", "TMPDIR"):
         if key in env and str(env[key]).strip():
            tmp_dir = str(env[key]).strip()
            break

      if not tmp_dir:
         # If explicit temp dir is not set, align with LOG_DIR when present.
         tmp_dir = OraEnv.logdir__ if OraEnv.logdir__ else "/tmp"

      OraEnv.tmpdir__ = tmp_dir if tmp_dir else "/tmp"
      OraEnv.__env_var_dict["TMP_DIR"] = OraEnv.tmpdir__

   @staticmethod
   def read_variable():
      """ Read the variables from a file into dict """
      if OraEnv.__env_var_file_flag:
         OraEnv.__env_var_dict = {}
         with open(OraEnv.__env_var_file) as envfile:
            for line in envfile:
               line = line.strip()
               if (not line) or line.startswith("#") or ("=" not in line):
                  continue
               name, var = line.split("=", 1)
               OraEnv.__env_var_dict[name.strip()] = var.strip()
      else:
         OraEnv.__env_var_dict = dict(os.environ)

   @staticmethod
   def add_variable():
      """ Add more variable ased on enviornment with default values in __env_var_dict"""
      for key, val in OraEnv.__default_vars.items():
         if key not in OraEnv.__env_var_dict:
            OraEnv.__env_var_dict[key] = val

      if "GSM_LOCK_STATUS_FILE" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["GSM_LOCK_STATUS_FILE"] = os.path.join(OraEnv.tmpdir__, ".gsm_status_lock_file")
      if "SHARD_LOCK_STATUS_FILE" not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict["SHARD_LOCK_STATUS_FILE"] = os.path.join(OraEnv.tmpdir__, ".shard_status_lock_file")

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
   def get_tmp_dir():
      """
      Static access method to return resolved temp directory.
      """
      return OraEnv.__env_var_dict.get("TMP_DIR", OraEnv.tmpdir__)

   @staticmethod
   def logfile_name(file_type):
      """ Static access method to return the logfile name. """
      if file_type == "NONE":
         # Preserve old behavior: keep current file if already initialized.
         if "LOG_FILE_NAME" not in OraEnv.__env_var_dict:
            OraEnv.__env_var_dict["LOG_FILE_NAME"] = os.path.join(
               OraEnv.logdir__,
               OraEnv.__logfile_map["NONE"]
            )
      elif file_type in OraEnv.__logfile_map:
         OraEnv.__env_var_dict["LOG_FILE_NAME"] = os.path.join(
            OraEnv.logdir__,
            OraEnv.__logfile_map[file_type]
         )

      return OraEnv.__env_var_dict["LOG_FILE_NAME"]
