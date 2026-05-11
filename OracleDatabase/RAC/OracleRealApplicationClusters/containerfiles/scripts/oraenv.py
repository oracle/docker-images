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
from datetime import datetime


class OraEnv:
   __instance                                  = None
   __env_var_file                              = '/etc/rac_env_vars'
   __env_var_file_writable                     = '/etc/rac_env_vars_writable'
   __env_var_file_flag                         = None
   __env_var_dict                              = {}
   __ora_asm_diskgroup_name                    = '+DATA'
   __ora_gimr_flag                             = 'false'
   __ora_grid_user                             = 'grid'
   __ora_db_user                               = 'oracle'
   __ora_oinstall_group_name                   = 'oinstall'
   encrypt_str__                               = None
   original_str__                              = None
   logdir__                                    = '/var/tmp'
   archdir__                                   = '/var/tmp'
   __default_log_file                          = 'oracle_db_setup.log'
   __default_env_entries                       = (
      ('ORA_ASM_DISKGROUP_NAME', 'ORA_ASM_DISKGROUP_NAME', '+DATA'),
      ('ORA_GRID_USER', 'GRID_USER', 'grid'),
      ('ORA_DB_USER', 'DB_USER', 'oracle'),
      ('ORA_OINSTALL_GROUP_NAME', 'OINSTALL', 'oinstall'),
      ('LOG_DIR', 'LOG_DIR', '/var/tmp'),
      ('ARCHIVE_DIR', 'ARCHIVE_DIR', '/var/tmp'),
   )
   __log_file_map                              = {
      'NONE': 'oracle_db_setup.log',
      'DEL_PARAMS': 'oracle_db_del.log',
      'RESET_PASSWORD': 'oracle_db_reset_passwd.log',
      'ADD_TNS': 'oracle_db_populate_tns_file.log',
      'CHECK_RAC_INST': 'oracle_check_rac_inst_file.log',
      'CHECK_GI_LOCAL': 'oracle_check_gi_local_file.log',
      'CHECK_RAC_DB': 'oracle_check_rac_db_file.log',
      'CHECK_DB_ROLE': 'oracle_check_db_role.log',
      'CHECK_CONNECT_STR': 'oracle_check_conn_str_file.log',
      'CHECK_PDB_CONNECT_STR': 'oracle_check_pdb_conn_str_file.log',
      'SETUP_DB_LSNR': 'setup_db_lsnr.log',
      'SETUP_LOCAL_LSNR': 'setup_local_lsnr.log',
      'CHECK_DB_VERSION': 'check_db_version.log',
      'CHECK_DB_SVC': 'check_db_svc.log',
      'MODIFY_DB_SVC': 'modify_db_svc.log',
      'CHECK_RAC_STATUS': 'check_racdb_status.log',
      'MODIFY_SCAN': 'oracle_modify_scan_status.log',
      'UPDATE_ASMCOUNT': 'oracle_update_asmcount_status.log',
      'UPDATE_ASMDEVICES': 'oracle_update_asmdevices_status.log',
      'LIST_ASMDG': 'oracle_list_asmdg_status.log',
      'LIST_ASMDISKS': 'oracle_list_asmdisks_status.log',
      'LIST_ASMDGREDUNDANCY': 'oracle_list_asmdgredundancy_status.log',
      'LIST_ASMINSTNAME': 'oracle_list_asminstname_status.log',
      'LIST_ASMINSTSTATUS': 'oracle_list_amsinst_status.log',
      'UPDATE_LISTENERENDP': 'oracle_update_listenerendp_status.log',
      'UPDATE_CDP': 'oracle_update_cdp_status.log',
      'RUN_DATAPATCH': 'oracle_rundatapatch_status.log',
      'ONS': 'oracle_ons_status.log',
      'SIDPROFILEUPDATE': 'sid_profile_update_status.log',
   }

   def __init__(self):
      """ Virtually private constructor. """
      if OraEnv.__instance != None:
         raise Exception('This class is a singleton!')
      OraEnv.__instance = self
      OraEnv.read_variable()
      OraEnv.preload_log_path_vars()
      OraEnv.add_variable()
      OraEnv.__refresh_log_paths()
      OraEnv.__ensure_directories()

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
               name, var = line.partition('=')[::2]
               OraEnv.__env_var_dict[name.strip()] = var
      else:
         OraEnv.__env_var_dict = os.environ
      OraEnv.__refresh_log_paths()

   @staticmethod
   def __get_runtime_envfiles():
      envfiles = []
      for envdir in (OraEnv.__env_var_file, OraEnv.__env_var_file_writable):
         envfile = os.path.join(envdir, 'envfile')
         if os.path.isfile(envfile):
            envfiles.append(envfile)
      return envfiles

   @staticmethod
   def preload_log_path_vars():
      """
      Preload only log path variables from runtime env files before loggers start.
      """
      old_log_dir = OraEnv.logdir__
      for envfile in OraEnv.__get_runtime_envfiles():
         with open(envfile) as fp:
            for line in fp:
               newstr = line.replace('export ', '').strip()
               if '=' not in newstr:
                  continue
               key, value = newstr.split('=', 1)
               key = key.strip()
               if key not in ('LOG_DIR', 'ARCHIVE_DIR'):
                  continue
               OraEnv.__env_var_dict[key] = value.strip()
      OraEnv.__refresh_log_paths()
      # If a default logfile was already derived using the previous log dir,
      # recalculate it under the new LOG_DIR before the logger is configured.
      current_log_file = OraEnv.__env_var_dict.get('LOG_FILE_NAME')
      if current_log_file and os.path.dirname(current_log_file) == old_log_dir:
         OraEnv.__env_var_dict.pop('LOG_FILE_NAME', None)
      OraEnv.__ensure_directories()

   @staticmethod
   def __resolve_log_dir():
      return OraEnv.__env_var_dict.get('LOG_DIR', '/var/tmp')

   @staticmethod
   def __resolve_archive_dir():
      return OraEnv.__env_var_dict.get('ARCHIVE_DIR', '/var/tmp')

   @staticmethod
   def __refresh_log_paths():
      OraEnv.logdir__ = OraEnv.__resolve_log_dir()
      OraEnv.archdir__ = OraEnv.__resolve_archive_dir()
      # Keep archive path visible to oralogger.py without requiring callers to set it.
      os.environ['ORA_LOG_ARCHIVE_DIR'] = OraEnv.archdir__

   @staticmethod
   def __ensure_directories():
      for dirname in (OraEnv.logdir__, OraEnv.archdir__):
         try:
            os.makedirs(dirname, exist_ok=True)
         except OSError:
            pass

   @staticmethod
   def __timestamped_logfile(base_file):
      basename, ext = os.path.splitext(base_file)
      timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
      if ext:
         return '{0}_{1}{2}'.format(basename, timestamp, ext)
      return '{0}_{1}'.format(basename, timestamp)

   @staticmethod
   def __set_log_file_for_type(file_type):
      base_file = OraEnv.__log_file_map.get(file_type)
      if base_file is None:
         return
      OraEnv.__env_var_dict['LOG_FILE_NAME'] = os.path.join(
         OraEnv.logdir__, base_file
      )

   @staticmethod
   def add_variable():
      """ Add more variable ased on enviornment with default values in __env_var_dict"""
      for check_key, set_key, default_val in OraEnv.__default_env_entries:
         if check_key not in OraEnv.__env_var_dict:
            OraEnv.__env_var_dict[set_key] = default_val
      OraEnv.__refresh_log_paths()

   @staticmethod
   def add_custom_variable(key, val):
      """ Addcustom  more variable passed from main.py values in __env_var_dict"""
      if key not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict[key] = val
         if key in ('LOG_DIR', 'ARCHIVE_DIR'):
            OraEnv.__refresh_log_paths()
            OraEnv.__ensure_directories()

   @staticmethod
   def update_key(key, val):
      """ Updating key variable passed from main.py values in __env_var_dict"""
      OraEnv.__env_var_dict[key] = val
      if key in ('LOG_DIR', 'ARCHIVE_DIR'):
         OraEnv.__refresh_log_paths()
         OraEnv.__ensure_directories()

   @staticmethod
   def get_env_vars():
      """ Static access method to get the env vars. """
      return OraEnv.__env_var_dict

   @staticmethod
   def update_env_vars(env_dict):
      """ Static access method to get the env vars. """
      OraEnv.__env_var_dict = env_dict
      OraEnv.__refresh_log_paths()

   @staticmethod
   def get_env_dict():
      """ Static access method t return the dict. """
      return OraEnv.__env_var_dict

   @staticmethod
   def get_log_dir():
      """ Static access method to return the logdir. """
      return OraEnv.logdir__

   @staticmethod
   def get_archive_dir():
      """ Static access method to return the archive dir. """
      return OraEnv.archdir__

   @staticmethod
   def statelogfile_name():
      """ Static access method to return the state logfile name. """
      if 'STATE_LOGFILE_NAME' not in OraEnv.__env_var_dict:
         return OraEnv.logdir__ + '/.statefile'
      else:
         return OraEnv.__env_var_dict['STATE_LOGFILE_NAME']

   @staticmethod
   def logfile_name(file_type):
      """ Static access method to return the logfile name. """
      if 'LOGFILE_NAME' in OraEnv.__env_var_dict and 'LOG_FILE_NAME' not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict['LOG_FILE_NAME'] = OraEnv.__env_var_dict['LOGFILE_NAME']

      if file_type == 'NONE':
         if 'LOG_FILE_NAME' not in OraEnv.__env_var_dict:
            OraEnv.__set_log_file_for_type(file_type)
      else:
         OraEnv.__set_log_file_for_type(file_type)

      if 'LOG_FILE_NAME' not in OraEnv.__env_var_dict:
         OraEnv.__env_var_dict['LOG_FILE_NAME'] = os.path.join(
            OraEnv.logdir__,
            OraEnv.__timestamped_logfile(OraEnv.__default_log_file),
         )

      return OraEnv.__env_var_dict['LOG_FILE_NAME']
