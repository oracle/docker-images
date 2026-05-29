#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

import os
import sys
import time
import re
import socket
import random
from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *

class OraGSM:
      """
      This class sets up the GSM after DB installation.
      """
      CATALOG_SETUP_MISSING_MSG = (
          "No existing catalog and GDS setup found on this system. "
          "Setting up GDS and will configure catalog on this machine."
      )

      def __init__(self,oralogger,orahandler,oraenv,oracommon):
        """
        This constructor of OraGsm class to setup the Gsm on primary DB.

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

      def _catalog_not_ready_exit(self):
          """
          Log a consistent not-ready message and terminate.
          """
          self.ocommon.log_info_message(self.CATALOG_SETUP_MISSING_MSG,self.file_name)
          self.ocommon.log_result_message(False, "GSM check failed: catalog/GDS setup not ready", self.file_name)
          self.ocommon.prog_exit("127")

      def _require_catalog_ready(self):
          """
          Validate catalog and GSM setup preconditions for operation flows.
          """
          self.catalog_checks()
          status = self.catalog_setup_checks()
          if not status:
             self._catalog_not_ready_exit()
             return False
          return True

      def _debug_liveness_bypass_active(self):
          """
          Allow GSM liveness to succeed during explicit debug sessions after
          a startup failure marker has been written by runOracle.sh.
          """
          enable_debug = str(self.ora_env_dict.get("ENABLE_DEBUG", "false")).lower()
          marker_file = self.ora_env_dict.get("GSM_STARTUP_FAILURE_MARKER", "/tmp/gsm-startup.failed")
          if enable_debug == "true" and os.path.exists(marker_file):
             self.ocommon.log_info_message(
                 "ENABLE_DEBUG=true and startup failure marker " + marker_file +
                 " found; bypassing GSM liveness for debugging.",
                 self.file_name,
             )
             self.ocommon.log_result_message(
                 True,
                 "GSM liveness debug bypass active",
                 self.file_name,
             )
             return True
          return False

      def _exec_gsm_cmd(self, gsmcmd, flag=None):
          """
          Execute GSM command with the class environment context.
          """
          gsmctl='''{0}/bin/gdsctl'''.format(self.ora_env_dict["ORACLE_HOME"])
          gsmctl=self._with_wallet_tns_env(gsmctl)
          output,error,retcode=self.ocommon.run_sqlplus(gsmctl,gsmcmd,None)
          self.ocommon.log_info_message("Calling check_sql_err() to validate the gsm command return status",self.file_name)
          self.ocommon.check_sql_err(output,error,retcode,flag)
          return output,error,retcode

      def _build_add_or_modify_cmd(self,op_type,resource,name_opt,name_value):
          """
          Build normalized add/modify gdsctl statement prefix.
          """
          action='modify' if str(op_type).strip().lower() == 'modify' else 'add'
          return ''' {0} {1} -{2} {3} '''.format(action,resource,name_opt,name_value)

      def _run_admin_gsm_statement(self,statement,flag=None):
          """
          Execute one admin-scoped gdsctl statement with standard masking/connect flow.
          """
          stmt=str(statement).strip()
          if stmt.endswith(";"):
             stmt=stmt[:-1].rstrip()
          try:
             self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
             connect_cmd=self._get_admin_connect_cmd()

             # Calling set_mask_str() as the unset_mask_str() is executed while calling _get_admin_connect_cmd()
             self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
             gsmcmd='''
               {0}
               {1};
             exit;
              '''.format(connect_cmd,stmt)
             return self._exec_gsm_cmd(gsmcmd,flag)
          finally:
             self.ocommon.unset_mask_str()

      def _run_sqlplus_and_check(self, sqlpluslogin, sqlcmd, status=None):
          """
          Execute SQLPlus command and run common SQL error validation.
          """
          sqlpluslogin=self._with_wallet_tns_env(sqlpluslogin)
          output,error,retcode=self.ocommon.run_sqlplus(sqlpluslogin,sqlcmd,None)
          self.ocommon.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
          self.ocommon.check_sql_err(output,error,retcode,status)
          return output,error,retcode

      def _run_gsm_readonly_query(self,statement,flag=None):
          """
          Execute read-only gdsctl statements without admin connect preamble.
          """
          stmt=str(statement).strip()
          if stmt.endswith(";"):
             stmt=stmt[:-1].rstrip()
          gsmcmd='''
            {0};
            exit;
          '''.format(stmt)
          return self._exec_gsm_cmd(gsmcmd,flag)

      def _iter_matching_keys(self,reg_exp):
          """
          Yield env keys matching a compiled regex.
          """
          for key in self.ora_env_dict.keys():
              if reg_exp.match(key):
                 yield key

      ######################################## Input/Mode/Auth Section #################################
      def _is_true(self,value):
          """
          Return boolean value for user provided flag strings.
          """
          if value is None:
             return False
          return str(value).strip().lower() in ('1','true','yes','y','on')

      def _normalize_sharding_type(self,stype):
          """
          Normalize sharding type value and aliases.
          """
          if stype is None:
             return "system"
          sval=str(stype).strip().lower()
          alias_map={
             "coposite":"composite",
             "sys":"system",
          }
          sval=alias_map.get(sval,sval)
          if sval in ("system","user","composite"):
             return sval
          msg='''Invalid sharding_type value [{0}] detected. Allowed values: system,user,composite'''.format(stype)
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

      def _normalize_repl_type(self,repl_type):
          """
          Normalize replication type values to DG/NATIVE.
          """
          if repl_type is None or str(repl_type).strip() == "":
             return "DG"
          rval=str(repl_type).strip().lower()
          alias_map={
             "dataguard":"DG",
             "data_guard":"DG",
             "dg":"DG",
             "native":"NATIVE",
             "raft":"NATIVE",
             "raftreplication":"NATIVE",
             "raftreplicatin":"NATIVE",
          }
          normalized=alias_map.get(rval,rval.upper())
          if normalized in ("DG","NATIVE"):
             return normalized
          msg='''Invalid repl_type value [{0}] detected. Allowed values: DG,NATIVE/RAFT'''.format(repl_type)
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

      def _parse_kv_params(self,key):
          """
          Parse semicolon-separated key=value input into a dictionary.
          """
          if not self.ocommon.check_key(key,self.ora_env_dict):
             msg='''Required parameter key [{0}] is missing.'''.format(key)
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")
          raw_value=str(self.ora_env_dict[key]).strip()
          # Accept payloads accidentally wrapped in single/double quotes, e.g.
          # '"shard_host=a;shard_db=b"' or "'shard_host=a;shard_db=b'".
          while len(raw_value) >= 2 and (
             (raw_value[0] == "'" and raw_value[-1] == "'") or
             (raw_value[0] == '"' and raw_value[-1] == '"')
          ):
             raw_value=raw_value[1:-1].strip()
          params={}
          for item in raw_value.split(";"):
              token=item.strip()
              if not token:
                 continue
              if "=" not in token:
                 msg='''Invalid token [{0}] in [{1}]. Expected key=value format.'''.format(token,key)
                 self.ocommon.log_error_message(msg,self.file_name)
                 self.ocommon.prog_exit("127")
              pkey,pval=token.split("=",1)
              # Tolerate quoted keys/values from templating layers.
              pkey=pkey.strip().strip('"').strip("'")
              pval=pval.strip().strip('"').strip("'")
              if not pkey:
                 msg='''Empty parameter key found in [{0}] input.'''.format(key)
                 self.ocommon.log_error_message(msg,self.file_name)
                 self.ocommon.prog_exit("127")
              params[pkey]=pval
          return params

      def _validate_supported_keys(self,params,allowed_keys,key_name):
          """
          Validate unsupported keys in parameter dictionary.
          """
          unsupported=[k for k in params.keys() if k not in allowed_keys]
          if unsupported:
             msg='''Unsupported parameter(s) in [{0}]: {1}. Allowed keys: {2}'''.format(
                key_name,",".join(sorted(unsupported)),",".join(sorted(allowed_keys)))
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")

      def _require_param(self,params,param_name,key_name):
          """
          Return required parameter value or exit with clear message.
          """
          value=params.get(param_name)
          if value is None or str(value).strip() == "":
             msg='''Parameter [{0}] is required in [{1}] input.'''.format(param_name,key_name)
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")
          return value

      def _require_positive_int(self,param_name,param_value,key_name):
          """
          Validate numeric positive integer parameters.
          """
          if param_value is None or str(param_value).strip() == "":
             return None
          if not re.fullmatch(r'[0-9]+',str(param_value).strip()):
             msg='''Parameter [{0}] in [{1}] must be a positive integer.'''.format(param_name,key_name)
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")
          if int(str(param_value).strip()) <= 0:
             msg='''Parameter [{0}] in [{1}] must be greater than zero.'''.format(param_name,key_name)
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")
          return str(int(str(param_value).strip()))

      def _get_sharding_context(self):
          """
          Build normalized sharding context from env/catalog params.
          """
          stype=None
          rtype=None
          sspace=None
          repl_factor=None
          repl_unit=None
          reg_exp=self.catalog_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)):
                 catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor1,repl_unit1,stype1,sspace1,cfname=self.process_clog_vars(key)
                 if stype is None:
                    stype=stype1
                 if rtype is None:
                    rtype=repl_type
                 if sspace is None:
                    sspace=sspace1
                 if repl_factor is None:
                    repl_factor=repl_factor1
                 if repl_unit is None:
                    repl_unit=repl_unit1
                 break

          if stype is None and self.ocommon.check_key("SHARDING_TYPE",self.ora_env_dict):
             stype=self.ora_env_dict["SHARDING_TYPE"]
          if rtype is None and self.ocommon.check_key("REPL_TYPE",self.ora_env_dict):
             rtype=self.ora_env_dict["REPL_TYPE"]
          if sspace is None and self.ocommon.check_key("SHARD_SPACE",self.ora_env_dict):
             sspace=self.ora_env_dict["SHARD_SPACE"]

          stype_norm=self._normalize_sharding_type(stype)
          rtype_norm=self._normalize_repl_type(rtype)
          if not (rtype_norm == "NATIVE" and repl_factor is None and repl_unit is None):
             self.ora_env_dict["SHARDING_TYPE"]=stype_norm.upper()
          self.ora_env_dict["REPL_TYPE"]=rtype_norm
          if sspace:
             self.ora_env_dict["SHARD_SPACE"]=sspace
          return {
             "sharding_type":stype_norm,
             "repl_type":rtype_norm,
             "default_shardspace":sspace,
          }

      def _wallet_root(self):
          """
          Get wallet root path from input.
          """
          if self.ocommon.check_key("WALLET_ROOT",self.ora_env_dict):
             return self.ora_env_dict["WALLET_ROOT"]
          if self.ocommon.check_key("wallet_root",self.ora_env_dict):
             return self.ora_env_dict["wallet_root"]
          return None

      def _is_wallet_enabled(self):
          """
          Check if wallet mode is enabled for GSM.
          """
          use_wallet=False
          if self.ocommon.check_key("USE_GSM_WALLET",self.ora_env_dict):
             use_wallet=self._is_true(self.ora_env_dict["USE_GSM_WALLET"])
          elif self.ocommon.check_key("use_gsm_wallet",self.ora_env_dict):
             use_wallet=self._is_true(self.ora_env_dict["use_gsm_wallet"])
          return use_wallet and self._wallet_root() is not None

      def _wallet_paths(self):
          """
          Build wallet/TNS paths.
          """
          wallet_root=self._wallet_root()
          if wallet_root is None:
             return None,None,None,None
          tns_admin=os.path.join(wallet_root,"network","admin")
          wallet_dir=os.path.join(tns_admin,"gsmwallet")
          sqlnet_path=os.path.join(tns_admin,"sqlnet.ora")
          tns_path=os.path.join(tns_admin,"tnsnames.ora")
          return tns_admin,wallet_dir,sqlnet_path,tns_path

      def _with_wallet_tns_env(self,cmd):
          """
          Prefix command with TNS_ADMIN export when wallet mode is enabled.
          """
          if not self._is_wallet_enabled():
             return cmd
          tns_admin,wallet_dir,sqlnet_path,tns_path=self._wallet_paths()
          return '''export TNS_ADMIN={0}; {1}'''.format(tns_admin,cmd)

      def _wallet_password(self):
          """
          Resolve wallet password for mkstore operations.
          """
          if self.ocommon.check_key("GSM_WALLET_PWD",self.ora_env_dict):
             return self.ora_env_dict["GSM_WALLET_PWD"]
          if self.ocommon.check_key("ORACLE_PWD",self.ora_env_dict):
             return self.ora_env_dict["ORACLE_PWD"]
          self.ocommon.log_error_message("Wallet mode is enabled but no password source found (GSM_WALLET_PWD/ORACLE_PWD).",self.file_name)
          self.ocommon.prog_exit("127")

      def _ensure_wallet_initialized(self):
          """
          Create wallet directories and sqlnet.ora for wallet based auth.
          """
          if not self._is_wallet_enabled():
             return
          tns_admin,wallet_dir,sqlnet_path,tns_path=self._wallet_paths()
          os.makedirs(tns_admin,exist_ok=True)
          os.makedirs(wallet_dir,exist_ok=True)
          if not os.path.isfile(sqlnet_path):
             sqlnet_content='''WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY={0})))
SQLNET.WALLET_OVERRIDE=TRUE
NAMES.DIRECTORY_PATH=(TNSNAMES, EZCONNECT)
'''.format(wallet_dir)
             with open(sqlnet_path,'w') as fobj:
                fobj.write(sqlnet_content)
          if not os.path.isfile(tns_path):
             with open(tns_path,'w') as fobj:
                fobj.write("")

          mkstore='''{0}/bin/mkstore'''.format(self.ora_env_dict["ORACLE_HOME"])
          if not os.path.isfile(mkstore):
             self.ocommon.log_error_message("Wallet mode is enabled but mkstore binary not found in ORACLE_HOME/bin.",self.file_name)
             self.ocommon.prog_exit("127")
          cwallet=os.path.join(wallet_dir,"cwallet.sso")
          ewallet=os.path.join(wallet_dir,"ewallet.p12")
          if not os.path.isfile(cwallet) and not os.path.isfile(ewallet):
             wpwd="HIDDEN_STRING"
             self.ocommon.set_mask_str(self._wallet_password())
             cmd='''printf '%s\\n%s\\n' "{2}" "{2}" | {0} -wrl {1} -create'''.format(mkstore,wallet_dir,wpwd)
             output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
             self.ocommon.unset_mask_str()
             if retcode != 0:
                self.ocommon.log_error_message("Failed to initialize GSM wallet for wallet-based authentication.",self.file_name)
                self.ocommon.prog_exit("127")

      def _wallet_alias(self,prefix,host,port,service,dbuser):
          """
          Build deterministic alias names for wallet credentials.
          """
          base='''{0}_{1}_{2}_{3}_{4}'''.format(prefix,host,port,service,dbuser)
          return re.sub(r'[^A-Za-z0-9_]+','_',base).upper()

      def _wallet_upsert_tns_entry(self,alias,host,port,service):
          """
          Ensure tnsnames alias is present for wallet auth.
          """
          if not self._is_wallet_enabled():
             return
          tns_admin,wallet_dir,sqlnet_path,tns_path=self._wallet_paths()
          self._ensure_wallet_initialized()
          alias_upper=alias.upper()
          with open(tns_path,'r') as fobj:
             content=fobj.read()
          if re.search(r'(?m)^' + re.escape(alias_upper) + r'\s*=',content):
             return
          entry='''
{0}=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST={1})(PORT={2}))(CONNECT_DATA=(SERVICE_NAME={3})))
'''.format(alias_upper,host,port,service)
          with open(tns_path,'a') as fobj:
             fobj.write(entry)

      def _wallet_add_credential(self,alias,dbuser,dbpasswd):
          """
          Add wallet credential for net service alias.
          """
          if not self._is_wallet_enabled():
             return
          self._ensure_wallet_initialized()
          tns_admin,wallet_dir,sqlnet_path,tns_path=self._wallet_paths()
          mkstore='''{0}/bin/mkstore'''.format(self.ora_env_dict["ORACLE_HOME"])
          wpwd="HIDDEN_STRING"
          dpwd="HIDDEN_STRING"
          self.ocommon.set_mask_str(self._wallet_password())
#          self.ocommon.set_mask_str(dbpasswd)
          alias_upper=alias.upper()
          cmd='''printf '%s\\n' "{3}" | {0} -wrl {1} -createCredential {2} {4} "{5}"'''.format(mkstore,wallet_dir,alias_upper,wpwd,dbuser,dpwd)
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          if retcode != 0 and "already exists" in (output + error).lower() and self._is_wallet_refresh_requested():
             self.ocommon.log_info_message(
                "Refreshing wallet credential for alias " + alias_upper,
                self.file_name
             )
             mod_cmd='''printf '%s\\n' "{3}" | {0} -wrl {1} -modifyCredential {2} {4} "{5}"'''.format(
                mkstore,wallet_dir,alias_upper,wpwd,dbuser,wpwd
             )
             output,error,retcode=self.ocommon.execute_cmd(mod_cmd,None,None)
          self.ocommon.unset_mask_str()
          if retcode != 0 and "already exists" not in (output + error).lower():
             self.ocommon.log_error_message("Failed to add/refresh wallet credential for alias " + alias,self.file_name)
             self.ocommon.prog_exit("127")

      def _ensure_wallet_db_login(self,prefix,host,port,service,dbuser,dbpasswd):
          """
          Ensure wallet has both alias and credential entries.
          """
          alias=self._wallet_alias(prefix,host,port,service,dbuser)
          self._wallet_upsert_tns_entry(alias,host,port,service)
          self._wallet_add_credential(alias,dbuser,dbpasswd)
          return alias

      def _is_wallet_refresh_requested(self):
          """
          Check whether wallet credentials should be refreshed.
          """
          if self.ocommon.check_key("REFRESH_WALLET_CREDENTIALS",self.ora_env_dict):
             return self._is_true(self.ora_env_dict["REFRESH_WALLET_CREDENTIALS"])
          return False

      def _resolve_auth_mode(self):
          """
          Resolve preferred authentication mode.
          """
          if self._is_wallet_enabled():
             return "wallet"
          return "password"

      def _get_catalog_target(self):
          """
          Return first matched catalog endpoint details.
          """
          reg_exp=self.catalog_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)):
                 catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)
                 return catalog_db,catalog_pdb,catalog_port,catalog_host
          self.ocommon.log_error_message("Catalog parameters were not found in input environment.",self.file_name)
          self.ocommon.prog_exit("127")

      def _try_wallet_alias(self,prefix,host,port,service,dbuser,dbpasswd):
          """
          Try wallet alias provisioning and return alias; return None on fallback.
          """
          if self._resolve_auth_mode() != "wallet":
             return None
          try:
             alias=self._ensure_wallet_db_login(prefix,host,port,service,dbuser,dbpasswd)
             return alias
          except SystemExit:
             self.ocommon.log_warn_message(
                "Wallet authentication setup failed; falling back to password-based authentication.",
                self.file_name
             )
             return None
          except Exception:
             self.ocommon.log_warn_message(
                "Wallet authentication raised an unexpected error; falling back to password-based authentication.",
                self.file_name
             )
             return None

      def _build_sqlplus_login(self,dbuser,role,prefix,host,port,service):
          """
          Build sqlplus login using wallet alias with password fallback.
          """
          dbpasswd=self.ora_env_dict["ORACLE_PWD"]
          alias=self._try_wallet_alias(prefix,host,port,service,dbuser,dbpasswd)
          role_clause=""
          if role:
             role_clause=" {0}".format(role)
          if alias:
             return '''{0}/bin/sqlplus "/@{1}{2}"'''.format(self.ora_env_dict["ORACLE_HOME"],alias,role_clause)
          return '''{0}/bin/sqlplus "{1}/HIDDEN_STRING@{2}:{3}/{4}{5}"'''.format(
             self.ora_env_dict["ORACLE_HOME"],dbuser,host,port,service,role_clause
          )

      def _build_catalog_user_opt(self,dbuser,host,port,service):
          """
          Build create shardcatalog user option with wallet-first behavior.
          """
          #dbpasswd=self.ora_env_dict["ORACLE_PWD"]
          #alias=self._try_wallet_alias("CATALOG",host,port,service,dbuser,dbpasswd)
          #if alias:
          #   return "-user {0}".format(dbuser)
          return "-user {0}/HIDDEN_STRING".format(dbuser)

      def _get_admin_connect_cmd(self):
          """
          Build gdsctl connect command using wallet or password auth.
          """
          cadmin=self.ora_env_dict["SHARD_ADMIN_USER"]
          catalog_db,catalog_pdb,catalog_port,catalog_host=self._get_catalog_target()
          alias=self._try_wallet_alias("CATALOG",catalog_host,catalog_port,catalog_pdb,cadmin,self.ora_env_dict["ORACLE_PWD"])
          if alias:
             return '''connect /@{0};'''.format(alias)
          return '''connect {0}/HIDDEN_STRING;'''.format(cadmin)

      def setup(self):
          """
           This function setup the Gsm on Primary DB.
          """
          if self.ocommon.check_key("ADD_SHARD",self.ora_env_dict):
             if self._require_catalog_ready():
                self.add_gsm_shard()
                self.set_hostid_null()
                self.add_invited_node("ADD_SHARD")
                self.remove_invited_node("ADD_SHARD")
                sys.exit(0)
          if self.ocommon.check_key("DEPLOY_SHARD",self.ora_env_dict):
             if self._require_catalog_ready():
                self.deploy_shard()
                self.setup_gsm_service()
                sys.exit(0)
          elif self.ocommon.check_key("ADD_SGROUP_PARAMS",self.ora_env_dict):
             if self._require_catalog_ready():
                self.setup_gsm_shardg("ADD_SGROUP_PARAMS")
                sys.exit(0)
          elif self.ocommon.check_key("ADD_SSPACE_PARAMS",self.ora_env_dict):
             if self._require_catalog_ready():
                self.setup_gsm_sspace("ADD_SSPACE_PARAMS")
                sys.exit(0)
          elif self.ocommon.check_key("REMOVE_SHARD",self.ora_env_dict):
             if self._require_catalog_ready():
                status=self.remove_gsm_shard()
                
             if status:
                sys.exit(0)
             else:
                sys.exit(1)

          elif self.ocommon.check_key("MOVE_CHUNKS",self.ora_env_dict):
             if self._require_catalog_ready():
                self.move_shard_chunks()
                sys.exit(0)
          elif self.ocommon.check_key("TDE_KEY",self.ora_env_dict):
               self.ocommon.get_tde_key()
               sys.exit(0)
          elif self.ocommon.check_key("CANCEL_CHUNKS",self.ora_env_dict):
             if self._require_catalog_ready():
                self.cancel_move_chunks()
                sys.exit(0)
          elif self.ocommon.check_key("VALIDATE_NOCHUNKS",self.ora_env_dict):
             if self._require_catalog_ready():
                self.validate_nochunks()
                sys.exit(0)
          elif self.ocommon.check_key("CHECK_ONLINE_SHARD",self.ora_env_dict):
             if self._require_catalog_ready():
                self.verify_online_shard()
                sys.exit(0)
          elif self.ocommon.check_key("CHECK_GSM_SHARD",self.ora_env_dict):
             if self._require_catalog_ready():
                self.verify_gsm_shard()
                sys.exit(0)
          elif self.ocommon.check_key("VALIDATE_SHARD",self.ora_env_dict):
             if self._require_catalog_ready():
                self.validate_gsm_shard()
                sys.exit(0)
          elif self.ocommon.check_key("VALIDATE_GSM",self.ora_env_dict):
             if self._require_catalog_ready():
                sys.exit(0)
          elif self.ocommon.check_key("CHECK_LIVENESS",self.ora_env_dict):
             if self._debug_liveness_bypass_active():
                sys.exit(0)
             filename=self.ora_env_dict["GSM_LOCK_STATUS_FILE"]
             if os.path.exists(filename):
                self.ocommon.log_info_message("provisioning is still in progress as file " + filename + " still exists!",self.file_name)
                self.ocommon.log_result_message(True, "GSM liveness check: provisioning still in progress", self.file_name)
                sys.exit(0)
             status = self.catalog_setup_checks()
             if not status:
                self._catalog_not_ready_exit()
             status = self.check_gsm_director_status(None)
             if not status:
                self.ocommon.log_info_message("No GDS setup found on this system.",self.file_name)
                self.ocommon.log_result_message(False, "GSM liveness check failed: no GDS setup found", self.file_name)
                self.ocommon.prog_exit("127")
             self.ocommon.log_info_message("GSM liveness check completed successfully!",self.file_name)
             self.ocommon.log_result_message(True, "GSM liveness check completed successfully", self.file_name)
             sys.exit(0)
          elif self.ocommon.check_key("INVITED_NODE_OP",self.ora_env_dict):
             if self._require_catalog_ready():
                self.invited_node_op()      
                sys.exit(0)
          elif self.ocommon.check_key("CATALOG_SETUP",self.ora_env_dict):
             # If user pass env avariable CATALOG_SETUP true then it will just create gsm director and add catalog but will not add any shard
             # It will also add service
             status = self.catalog_setup_checks()
             if status == False:
                self.ocommon.log_info_message(self.CATALOG_SETUP_MISSING_MSG,self.file_name)
                self.setup_machine()
                self.catalog_checks()
                self.reset_gsm_setup()
                status1 = self.gsm_setup_check()
                if status1:
                   self.ocommon.log_info_message("Gsm Setup is already completed on this database",self.file_name)
                   self.start_gsm_director()
                   self.ocommon.log_info_message("Started GSM",self.file_name)
                else:
                   # Perform Catalog setup after check GSM_MASTER FLAG. IF GSM MASTER FLAG is set then only catalog will be added.
                   self.ocommon.log_info_message("No existing GDS found on this system. Setting up GDS on this machine.",self.file_name)
                   master_flag=self.gsm_master_flag_check()
                   if master_flag:
                     self.setup_gsm_catalog()
                     self.setup_gsm_director()
                     self.start_gsm_director()
                     self.status_gsm_director()
                     if self.ocommon.check_key("SHARDING_TYPE",self.ora_env_dict):
                       if self.ora_env_dict["SHARDING_TYPE"].upper() != 'USER':
                           self.setup_gsm_shardg("SHARD_GROUP")
                     else:
                        self.setup_gsm_shardg("SHARD_GROUP")
                     self.gsm_backup_file()
                     self.tns_bashrc_entry()
                     self.gsm_completion_message()
                   ### Running Custom Scripts
                     self.run_custom_scripts()
                   else:
                     self.add_gsm_director()
                     self.start_gsm_director() 
                     self.gsm_backup_file()
                     self.tns_bashrc_entry()
                     self.gsm_completion_message()
          else:
             # This block run shard addition, catalog addition and service creation
             # This block also verifies if master flag is not a GSM director then it will not create catalog but add GSM only
             self.setup_machine()
             self.gsm_checks()
             self.reset_gsm_setup()
             status = self.gsm_setup_check()
             if status:
                self.ocommon.log_info_message("Gsm Setup is already completed on this database",self.file_name)
                self.start_gsm_director()
                self.ocommon.log_info_message("Started GSM",self.file_name)
             else:
                # if the status = self.gsm_setup_check() return False then shard addition, catalog addition and service creation
                master_flag=self.gsm_master_flag_check()
                if master_flag:
                   self.ocommon.log_info_message("No existing GDS found on this system. Setting up GDS on this machine.",self.file_name)
                   self.setup_gsm_catalog()
                   self.setup_gsm_director()
                   self.start_gsm_director()
                   self.status_gsm_director()
                   if self.ocommon.check_key("SHARDING_TYPE",self.ora_env_dict):
                       if self.ora_env_dict["SHARDING_TYPE"].upper() != 'USER':
                           self.setup_gsm_shardg("SHARD_GROUP")
                       if self.ora_env_dict["SHARDING_TYPE"].upper() == 'USER':
                           self.setup_gsm_sspace("SHARD_SPACE")
                   else:
                      self.setup_gsm_shardg("SHARD_GROUP")
                   self.setup_gsm_shard()
                   self.set_hostid_null()
                   self.stop_gsm_director()
                   time.sleep(30)
                   self.start_gsm_director()
                   self.add_invited_node("SHARD")
                   self.remove_invited_node("SHARD")
                   self.stop_gsm_director()
                   time.sleep(30)
                   self.start_gsm_director()
                   self.deploy_shard()
                   self.setup_gsm_service()
                   self.setup_sample_schema()
                   self.gsm_backup_file()
                   self.tns_bashrc_entry()
                   self.gsm_completion_message()
                ### Running Custom Scripts
                   self.run_custom_scripts()   
                else:
                   self.add_gsm_director()
                   self.start_gsm_director()          
                   self.gsm_backup_file()
                   self.tns_bashrc_entry()
                   self.gsm_completion_message()
      
      ###########  SETUP_MACHINE begins here ####################
      ## Function to machine setup
      def setup_machine(self):
          """
           Perform compute prerequisites before GSM setup.
          """
          self.omachine.setup()
          filename = self.ora_env_dict["GSM_LOCK_STATUS_FILE"]
          touchfile = 'touch {0}'.format(filename)
          if not os.path.isfile(filename):
            self.ocommon.log_error_message("Setting file provisioning status file :" + filename ,self.file_name)
            output,error,retcode=self.ocommon.execute_cmd(touchfile,None,self.ora_env_dict)
            if retcode == 1:
                   self.ocommon.log_error_message("error occurred while creating the file :" + filename + ". Exiting!",self.file_name)
                   self.ocommon.prog_exit("127")

      ###########   ENDS here ####################

      def gsm_checks(self):
          """
          Run required DB checks before setup.
          """
          self.ohome_check()
          self.passwd_check()
          self.shard_user_check()
          self.gsm_hostname_check()
          self.director_params_checks()
          self.catalog_params_check()
          self.shard_params_check()
          self.sgroup_params_check()


      def catalog_checks(self):
          """
          Run required catalog checks before setup.
          """
          self.ohome_check()
          self.passwd_check()
          self.shard_user_check()
          self.gsm_hostname_check()
          self.director_params_checks()
          self.catalog_params_check()
          self.sgroup_params_check()

      def ohome_check(self):
                """
                   Validate `ORACLE_HOME` settings.
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
           Set the password
           """
           self.ocommon.get_password(None)
           if self.ocommon.check_key("ORACLE_PWD",self.ora_env_dict):
               msg='''ORACLE_PWD key is set. Check Passed!'''
               self.ocommon.log_info_message(msg,self.file_name)                 

      def shard_user_check(self):
                 """
                 Validate and set shard-related DB users.
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

      def director_params_checks(self):
                 """
                 Validate shard director parameters.
                 """
                 status=False
                 reg_exp= self.director_regex()
                 for key in self.ora_env_dict.keys():
                   if(reg_exp.match(key)):
                       msg='''SHARD Director PARAMS {0} is set to {1}'''.format(key,self.ora_env_dict[key])
                       self.ocommon.log_info_message(msg,self.file_name)
                       status=True

      def gsm_hostname_check(self):
                 """
                 Validate and set hostname for GSM.
                 """
                 if self.ocommon.check_key("ORACLE_HOSTNAME",self.ora_env_dict):
                    msg='''ORACLE_HOSTNAME {0} is passed as an env variable. Check Passed!'''.format(self.ora_env_dict["ORACLE_HOSTNAME"])
                    self.ocommon.log_info_message(msg,self.file_name)
                 else:
                    if self.ocommon.check_key("KUBE_SVC",self.ora_env_dict):
                       ## hostname='''{0}.{1}'''.format(socket.gethostname(),self.ora_env_dict["KUBE_SVC"])
                       hostname='''{0}'''.format(socket.getfqdn())
                    else:
                       hostname='''{0}'''.format(socket.gethostname())
                    msg='''ORACLE_HOSTNAME is not set, setting it to hostname {0} of the compute!'''.format(hostname)
                    self.ora_env_dict=self.ocommon.add_key("ORACLE_HOSTNAME",hostname,self.ora_env_dict)
                    self.ocommon.log_info_message(msg,self.file_name)

      def catalog_params_check(self):
                 """
                 Validate `CATALOG[1-9]_PARAMS` inputs.
                 """
                 status=False
                 reg_exp= self.catalog_regex()
                 ## Instead of directly using the ora_env_dict and modifying it during the iteration (which causes error "RuntimeError: dictionary changed size during iteration"),
                 ## iterating over a list of the keys of ora_env_dict
                 for key in list(self.ora_env_dict.keys()):
                     if(reg_exp.match(key)):
                        msg='''CATALOG PARAMS {0} is set to {1}'''.format(key,self.ora_env_dict[key])
                        self.ocommon.log_info_message(msg,self.file_name)
                        catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)
                        if stype:
                          if stype.lower() == 'user':
                              if not self.ocommon.check_key("SHARDING_TYPE",self.ora_env_dict):
                                 self.ora_env_dict=self.ocommon.add_key("SHARDING_TYPE","USER",self.ora_env_dict)
                              if not self.ocommon.check_key("SHARD_SPACE",self.ora_env_dict):
                                 self.ora_env_dict=self.ocommon.add_key("SHARD_SPACE",sspace,self.ora_env_dict)
                        status=True

                 if not status:
                     msg="CATALOG[1-9]_PARAMS such as CATALOG_PARAMS is not set, exiting!"
                     self.ocommon.log_error_message(msg,self.file_name)
                     self.ocommon.prog_exit("127")

      def shard_params_check(self):
                 """
                 Validate `SHARD[1-9]_PARAMS` inputs.
                 """
                 status=False
                 reg_exp= self.shard_regex()
                 for key in self.ora_env_dict.keys():
                     if(reg_exp.match(key)):
                        msg='''SHARD PARAMS {0} is set to {1}'''.format(key,self.ora_env_dict[key])
                        self.ocommon.log_info_message(msg,self.file_name)
                        status=True

                 if not status:
                     msg="SHARD[1-9]_PARAMS such as SHARD1_PARAMS is not set, exiting!"
                     self.ocommon.log_error_message(msg,self.file_name)
                     self.ocommon.prog_exit("127")

      def sgroup_params_check(self):
                 """
                 Validate `SHARD[1-9]_GROUP_PARAMS` inputs.
                 """
                 status=False
                 reg_exp= self.shardg_regex()
                 for key in self.ora_env_dict.keys():
                     if(reg_exp.match(key)):
                        msg='''SHARD GROUP PARAMS {0} is set to {1}'''.format(key,self.ora_env_dict[key])
                        self.ocommon.log_info_message(msg,self.file_name)
                        status=True
      def gsm_master_flag_check(self):
                 """
                 Check whether node is configured as MASTER_GSM.
                 """
                 status=False
                 if self.ocommon.check_key("MASTER_GSM",self.ora_env_dict):
                    msg='''MASTER_GSM is set. This machine will be configured with as master GSM director.'''
                    self.ocommon.log_info_message(msg,self.file_name)
                    return True 
                 else:
                    return False

      def catalog_setup_checks(self):
                 """
                 Check whether director setup is complete and connected.
                 """
                 status = False
                 gsm_status = self.check_gsm_director(None)
                 #catalog_status = self.check_gsm_catalog()

                 if gsm_status == 'completed':
                    status = True
                 else:
                    status = False

                 #if catalog_status == 'completed':
                 #   status = True
                 #else:
                 #   status = False

                 return status
             ###########  DB_CHECKS  Related Functions Begin Here  ####################


             ########## SETUP_CDB_catalog FUNCTION BEGIN HERE ###############################
      def reset_gsm_setup(self):
                 """
                  This function delete the GSM files.
                 """
                 self.ocommon.log_info_message("Inside reset_gsm_setup",self.file_name)
                 gsmdata_loc='/opt/oracle/gsmdata'
                 cmd_list=[]
                 if self.ocommon.check_key("RESET_ENV",self.ora_env_dict):
                    if self.ora_env_dict["RESET_ENV"]:
                       msg='''Deleting files from {0}'''.format(gsmdata_loc)
                       self.ocommon.log_info_message(msg,self.file_name)
                       cmd_list[0]='''rm -f {0}/gsm.ora'''.format(gsmdata_loc)
                       cmd_list[1]='''rm -f {0}/tnsnames.ora'''.format(gsmdata_loc)
                       cmd_list[2]='''rm -rf {0}/wallets'''.format(gsmdata_loc)
                    for cmd in cmd_list:
                        output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                        self.ocommon.check_os_err(output,error,retcode,True)

      def gsm_setup_check(self):
                 """
                  This function check if GSM is already setup on this
                 """
                 status=True
                 self.ocommon.log_info_message("Inside gsm_setup_check",self.file_name)
                 gsmdata_loc='/opt/oracle/gsmdata'
                 gsmfile_loc='''{0}/network/admin'''.format(self.ora_env_dict["ORACLE_HOME"])

                 gsmora='''{0}/gsm.ora'''.format(gsmdata_loc)
                 tnsnamesora='''{0}/tnsnames.ora'''.format(gsmdata_loc)
                 walletloc='''{0}/gsmwallet'''.format(gsmdata_loc)

                 if os.path.isfile(gsmora):
                    cmd='''cp -r -v -f {0} {1}/'''.format(gsmora,gsmfile_loc)
                    output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                    self.ocommon.check_os_err(output,error,retcode,True)
                 else:
                    status=False

                 if os.path.isfile(tnsnamesora):
                    cmd='''cp -r -v -f {0} {1}/'''.format(tnsnamesora,gsmfile_loc)
                    output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                    self.ocommon.check_os_err(output,error,retcode,True)
                 else:
                    status=False

                 if os.path.isdir(walletloc):
                    cmd='''cp -r -v -f {0} {1}/'''.format(walletloc,gsmfile_loc)
                    output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                    self.ocommon.check_os_err(output,error,retcode,True)
                 else:
                    status=False

                 if status:
                    return True
                 else:
                    return False

      ####################  Catalog related Functions BEGINS Here ###########################
      def setup_gsm_calog(self):
                 """
                  Set up the GSM catalog.
                 """
                 self.ocommon.log_info_message("Inside setup_gsm_catalog()",self.file_name)
                 status=False
                 reg_exp= self.catalog_regex()
                 counter=1
                 end_counter=60
                 catalog_db_status=None
                 while counter < end_counter:                 
                       for key in self.ora_env_dict.keys():
                           if(reg_exp.match(key)):
                              catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)
                              catalog_db_status=self.check_setup_status(catalog_host,catalog_db,catalog_pdb,catalog_port)
                              if catalog_db_status == 'completed':
                                 self.configure_gsm_clog(catalog_host,catalog_db,catalog_pdb,catalog_port,catalog_name,catalog_region,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname)
                                 break 
                              else:
                                 msg='''Catalog Status must return completed but returned value is {0}'''.format(status)
                                 self.ocommon.log_info_message(msg,self.file_name)
                       if catalog_db_status == 'completed':
                          break
                       else:
                         msg='''Catalog setup is still not completed in GSM. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
                         self.ocommon.log_info_message(msg,self.file_name)
                       time.sleep(60)
                       counter=counter+1

      def setup_gsm_catalog(self):
                 """
                  Backward-compatible alias with corrected naming.
                 """
                 return self.setup_gsm_calog()

      def process_clog_vars(self,key):
          """
          Process catalog params and enforce topology/replication gating.
          """
          self.ocommon.log_info_message("Inside process_clog_vars()",self.file_name)
          params=self._parse_kv_params(key)
          allowed_keys=set([
             'catalog_db','catalog_pdb','catalog_port','catalog_region','catalog_host','catalog_name',
             'catalog_chunks','repl_type','repl_factor','repl_unit','sharding_type','shard_space','shard_configname',
             'autovncr','agent_port','validate_network','force'
          ])
          self._validate_supported_keys(params,allowed_keys,key)

          catalog_db=self._require_param(params,'catalog_db',key)
          catalog_pdb=self._require_param(params,'catalog_pdb',key)
          catalog_host=self._require_param(params,'catalog_host',key)
          catalog_name=self._require_param(params,'catalog_name',key)
          catalog_region=self._require_param(params,'catalog_region',key)
          catalog_port=params.get('catalog_port') or 1521

          stype=self._normalize_sharding_type(params.get('sharding_type'))
          repl_type=self._normalize_repl_type(params.get('repl_type'))
          repl_factor=self._require_positive_int('repl_factor',params.get('repl_factor'),key)
          repl_unit=self._require_positive_int('repl_unit',params.get('repl_unit'),key)
          catalog_chunks=self._require_positive_int('catalog_chunks',params.get('catalog_chunks'),key)
          agent_port=self._require_positive_int('agent_port',params.get('agent_port'),key)
          sspace=params.get('shard_space')
          cfname=params.get('shard_configname')

          # Optional add catalog command flags
          clog_add_extra_opts=""
          if 'force' in params and self._is_true(params.get('force')):
             clog_add_extra_opts = clog_add_extra_opts + " -force"
          
          self.ora_env_dict['CLOG_ADD_EXTRA_OPTS']=clog_add_extra_opts

          autovncr=params.get('autovncr')
          if autovncr is None or str(autovncr).strip() == '':
             autovncr=None
          else:
             aval=str(autovncr).strip().lower()
             if aval in ('on','1'):
                autovncr='on'
             elif aval in ('off','0'):
                autovncr='off'
             else:
                self.ocommon.log_error_message("autovncr must be ON/OFF/0/1.",self.file_name)
                self.ocommon.prog_exit("127")

          validate_network=None
          if 'validate_network' in params:
             validate_raw=params.get('validate_network')
             if validate_raw is None or str(validate_raw).strip() == "":
                self.ocommon.log_error_message("validate_network must be true/false/0/1 when provided.",self.file_name)
                self.ocommon.prog_exit("127")
             vval=str(validate_raw).strip().lower()
             if vval in ('true','1'):
                validate_network='true'
             elif vval in ('false','0'):
                validate_network='false'
             else:
                self.ocommon.log_error_message("validate_network must be true/false/0/1.",self.file_name)
                self.ocommon.prog_exit("127")

          if agent_port is None:
             agent_port='8080'

          if autovncr is not None:
             self.ora_env_dict['CATALOG_AUTOVNCR']=autovncr
          elif self.ocommon.check_key("CATALOG_AUTOVNCR",self.ora_env_dict):
             del self.ora_env_dict["CATALOG_AUTOVNCR"]
          self.ora_env_dict['CATALOG_AGENT_PORT']=agent_port
          if validate_network is not None:
             self.ora_env_dict['CATALOG_VALIDATE_NETWORK']=validate_network
          elif self.ocommon.check_key("CATALOG_VALIDATE_NETWORK",self.ora_env_dict):
             del self.ora_env_dict["CATALOG_VALIDATE_NETWORK"]

          if stype in ('user','composite') and (sspace is None or str(sspace).strip() == ''):
             sspace="shardspace1,shardspace2"

          if stype == 'system' and sspace:
             self.ocommon.log_warn_message("Ignoring shard_space for system sharding catalog setup.",self.file_name)
             sspace=None

          if repl_type == 'DG':
             if repl_factor:
                self.ocommon.log_warn_message("Ignoring repl_factor for DG replication.",self.file_name)
                repl_factor=None
             if repl_unit:
                self.ocommon.log_warn_message("Ignoring repl_unit for DG replication.",self.file_name)
                repl_unit=None
          elif repl_type == 'NATIVE':
             # Native mode keeps repl_factor/repl_unit optional unless user passes them.
             pass

          if stype == 'user' and catalog_chunks:
             self.ocommon.log_warn_message("Ignoring catalog_chunks for user sharding.",self.file_name)
             catalog_chunks=None

          if not (repl_type == 'NATIVE' and repl_factor is None and repl_unit is None):
             self.ora_env_dict["SHARDING_TYPE"]=stype.upper()
          self.ora_env_dict["REPL_TYPE"]=repl_type
          if sspace:
             self.ora_env_dict["SHARD_SPACE"]=sspace

          return (
             catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,
             catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname
          )

      def check_gsm_catalog(self):
          """
           Check catalog status in GSM.
          """
          self.ocommon.log_info_message("Inside check_gsm_catalog()",self.file_name)
          #dtrname,dtrport,dtregion=self.process_director_vars()
          output,error,retcode=self._run_gsm_readonly_query("config",None)
          matched_output=re.findall("(?:GSMs\n)(?:.+\n)+",output)
          try:
             match=self.ocommon.check_substr_match(matched_output[0],"test")
          except:
             match=False
          return(self.ocommon.check_status_value(match))

        #  output,error,retcode=self._exec_gsm_cmd(gsmcmd,None)
        #  new_output=output[0].replace(" ","")
        #  self.ocommon.log_info_message(new_output,self.file_name)
        #  match=self.ocommon.check_substr_match(new_output,"Catalogconnectionisestablished")
        #  return(self.ocommon.check_status_value(match))

      def catalog_regex(self):
          """
            Return regex to search for `CATALOG_PARAMS`.
          """ 
          self.ocommon.log_info_message("Inside catalog_regex()",self.file_name)
          return re.compile('CATALOG_PARAMS') 

      
      def configure_gsm_clog(self,chost,ccdb,cpdb,cport,catalog_name,catalog_region,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname):
                 """
                  This function configure the GSM catalog.
                 """
                 self.ocommon.log_info_message("Inside configure_gsm_clog()",self.file_name)
                 cadmin=self.ora_env_dict["SHARD_ADMIN_USER"]
                 cpasswd="HIDDEN_STRING"

                 stype_norm=self._normalize_sharding_type(stype)
                 repl_norm=self._normalize_repl_type(repl_type)
                 if not (repl_norm == 'NATIVE' and repl_factor is None and repl_unit is None):
                    self.ora_env_dict["SHARDING_TYPE"]=stype_norm.upper()
                 self.ora_env_dict["REPL_TYPE"]=repl_norm

                 shardingtype=" -sharding {0}".format(stype_norm)
                 shardspace=""
                 if stype_norm in ('user','composite'):
                    if sspace:
                       shardspace=" -shardspace {0}".format(sspace)
                       self.ora_env_dict["SHARD_SPACE"]=sspace
                 elif sspace:
                    self.ocommon.log_warn_message("Ignoring shardspace for system sharding catalog.",self.file_name)

                 configname=""
                 if cfname:
                    configname=" -configname {0}".format(cfname)

                 chunks=""
                 if catalog_chunks:
                    if stype_norm == 'user':
                       self.ocommon.log_warn_message("Ignoring catalog_chunks for user sharding as per command semantics.",self.file_name)
                    else:
                       chunks=" -chunks {0}".format(catalog_chunks)

                 repl=" -repl {0}".format(repl_norm)
                 repfactor=""
                 repunits=""
                 if repl_norm == 'NATIVE':
                    if repl_factor:
                       repfactor=" -repfactor {0}".format(repl_factor)
                    if repl_unit:
                       repunits=" -repunits {0}".format(repl_unit)
                 else:
                    if repl_factor:
                       self.ocommon.log_warn_message("Ignoring repl_factor for DG replication.",self.file_name)
                    if repl_unit:
                       self.ocommon.log_warn_message("Ignoring repl_unit for DG replication.",self.file_name)

                 invited_subnet=""
                 add_invited_subnet=""
                 if self.ocommon.check_key("INVITED_NODE_SUBNET_FLAG",self.ora_env_dict):
                    if self.ocommon.check_key("INVITED_NODE_SUBNET",self.ora_env_dict):
                       invited_subnet=self.ora_env_dict["INVITED_NODE_SUBNET"]
                    else:
                       chost_ip=self.ocommon.get_ip(chost,None)
                       ip_parts=chost_ip.split('.')
                       invited_subnet=ip_parts[0] + "." + ip_parts[1] + '.*' + '.*'
                    add_invited_subnet='''add invitedsubnet {0};'''.format(invited_subnet)
                 else:
                    chost_ip=self.ocommon.get_ip(chost,None)
                    ip_parts=chost_ip.split('.')
                    invited_subnet=ip_parts[0] + "." + ip_parts[1] + '.*' + '.*'
                    add_invited_subnet='''add invitedsubnet {0};'''.format(invited_subnet)

                 user_opt=self._build_catalog_user_opt(cadmin,chost,cport,cpdb)

                 agent_port=self.ora_env_dict["CATALOG_AGENT_PORT"] if self.ocommon.check_key("CATALOG_AGENT_PORT",self.ora_env_dict) else '8080'
                 autovncr_opt=""
                 if self.ocommon.check_key("CATALOG_AUTOVNCR",self.ora_env_dict):
                    autovncr_opt=" -autovncr {0}".format(self.ora_env_dict["CATALOG_AUTOVNCR"])
                 validate_network=""
                 if self.ocommon.check_key("CATALOG_VALIDATE_NETWORK",self.ora_env_dict):
                    if self._is_true(self.ora_env_dict["CATALOG_VALIDATE_NETWORK"]):
                       validate_network=" -validate_network"

                 clog_add_extra_opts=self.ora_env_dict["CLOG_ADD_EXTRA_OPTS"] if self.ocommon.check_key("CLOG_ADD_EXTRA_OPTS",self.ora_env_dict) else ""

                 cmd='''
                  create shardcatalog -database "(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST={0})(PORT={1}))(CONNECT_DATA=(SERVICE_NAME={2})))" {7} {3} -sdb {4} -region {5} -agent_port {16} -agent_password {6} {8} {9} {10} {11} {12} {13} {17} {15} {18};
                  add invitednode {0};
                  {14}
                  '''.format(chost,cport,cpdb,user_opt,catalog_name,catalog_region,cpasswd,chunks,repl,repfactor,repunits,shardingtype,shardspace,configname,add_invited_subnet,validate_network,agent_port,autovncr_opt,clog_add_extra_opts)

                 counter=1
                 while counter < 5:
                    output,error,retcode=self._run_admin_gsm_statement(cmd,None)
                    #status=self.check_gsm_catalog()
                    #if status == 'completed':
                    #   break
                    #counter=counter+1
                    #time.sleep(10)
                    if retcode != 0:
                      self.ocommon.log_info_message("Error occurred while creating the shard catalog, sleeping for 60 seconds",self.file_name)
                      counter = counter + 1
                      time.sleep(60)
                    else:
                      break


      def check_gsm_director(self,dname):
          """
          Check GSM director status.
          """  
          self.ocommon.log_info_message("Inside check_gsm_director()",self.file_name)
          status=False
          if dname:
            output,error,retcode=self._run_gsm_readonly_query("config",None)
            matched_output=re.findall("(?:GSMs\n)(?:.+\n)+",output)
            try:
              if self.ocommon.check_substr_match(matched_output[0],dname):
                 status=True   
            except:
              status=False 
          else:
            reg_exp= self.director_regex()
            for key in self._iter_matching_keys(reg_exp):
                dname,dtrport,dtregion=self.process_director_vars(key)
                output,error,retcode=self._run_gsm_readonly_query("config",None)
                matched_output=re.findall("(?:GSMs\n)(?:.+\n)+",output)
                try:
                  if self.ocommon.check_substr_match(matched_output[0],dname):
                     status=True
                except:
                     status=False

          return(self.ocommon.check_status_value(status))

      def check_gsm_region(self,region):
          """
          Check GSM region status.
          """  
          self.ocommon.log_info_message("Inside check_gsm_region()",self.file_name)
          output,error,retcode=self._run_gsm_readonly_query("config",None)
          matched_output=re.findall("(?:Regions\n)(?:.+\n)+",output)
          status=False
          try:
            if self.ocommon.check_substr_match(matched_output[0],region):
              status=True   
          except:
             status=False 
          return(self.ocommon.check_status_value(status))

      def check_gsm_shardspace(self,sspace):
          """
          Check GSM shardspace status.
          """  
          self.ocommon.log_info_message("Inside check_gsm_shardspace()",self.file_name)
          output,error,retcode=self._run_gsm_readonly_query("config",None)
          matched_output=re.findall("(?:Shard spaces\n)(?:.+\n)+",output)
          status=False
          try:
            if self.ocommon.check_substr_match(matched_output[0],sspace):
              status=True   
          except:
             status=False 
          return(self.ocommon.check_status_value(status))
       
      def check_gsm_director_status(self,dname):
          """
          Check GSM director status using `gdsctl status`.
          """
          self.ocommon.log_info_message("Inside check_gsm_director_status()",self.file_name)
          status=False
          output,error,retcode=self._run_gsm_readonly_query("status",None)
          if "Connected to GDS catalog      Y".replace(" ","").lower() in output.replace(" ","").lower():
             return True
          else:
            return False

      def add_gsm_director(self):
          """ 
           Add GSM director(s).
          """
          status=False
          counter=1
          end_counter=60
          gsmhost=self.ora_env_dict["ORACLE_HOSTNAME"]
          cadmin=self.ora_env_dict["SHARD_ADMIN_USER"]
          cpasswd="HIDDEN_STRING"
          gsm_trace_level=self.get_gsm_trace_level()
          reg_exp= self.director_regex()

          while counter < end_counter:
             for key in self.ora_env_dict.keys():
                 if(reg_exp.match(key)):
                     shard_director_status=None
                     dtrname,dtrport,dtregion=self.process_director_vars(key)
                     shard_director_status=self.check_gsm_director(dtrname)
                     if shard_director_status != 'completed':
                         self.configure_gsm_director(dtrname,dtrport,dtregion,gsmhost,cadmin,gsm_trace_level)
                     status = self.check_gsm_director(None)
                     if status == 'completed':
                          break
                     
             if status == 'completed':
               break
             else:             
               msg='''GSM shard director setup is still not completed in GSM. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
               self.ocommon.log_info_message(msg,self.file_name)
               time.sleep(60)
               counter=counter+1

          status = self.check_gsm_director(None)
          if status == 'completed':
             msg='''Shard director setup completed in GSM.'''
             self.ocommon.log_info_message(msg,self.file_name)
          else:
             msg='''Waited 60 minutes for shard director setup in GSM, but setup did not complete or failed. Exiting...'''
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")
             
      def setup_gsm_director(self):
                 """
                 Set up GSM directors.
                 """
                 self.ocommon.log_info_message("Inside setup_gsm_director()",self.file_name)
                 status=False
                 reg_exp= self.director_regex()
                 counter=1
                 end_counter=3
                 gsmhost=self.ora_env_dict["ORACLE_HOSTNAME"]
                 cadmin=self.ora_env_dict["SHARD_ADMIN_USER"]
                 cpasswd="HIDDEN_STRING"
                 gsm_trace_level=self.get_gsm_trace_level()
                 while counter < end_counter:
                     for key in self.ora_env_dict.keys():
                         if(reg_exp.match(key)):
                            shard_director_status=None
                            dtrname,dtrport,dtregion=self.process_director_vars(key)
                            shard_director_status=self.check_gsm_director(dtrname)
                            if shard_director_status != 'completed':
                               self.configure_gsm_director(dtrname,dtrport,dtregion,gsmhost,cadmin,gsm_trace_level)
                     status = self.check_gsm_director(None)
                     if status == 'completed':
                        break
                     else:
                        msg='''GSM shard director setup is still not completed in GSM. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
                     time.sleep(60)
                     counter=counter+1                              
                      
                 status = self.check_gsm_director(None)
                 if status == 'completed':
                   msg='''Shard director setup completed in GSM.'''
                   self.ocommon.log_info_message(msg,self.file_name)
                 else:
                   msg='''Waited 3 minutes for shard director setup in GSM, but setup did not complete or failed. Exiting...'''
                   self.ocommon.log_error_message(msg,self.file_name)
                   self.ocommon.prog_exit("127") 

      def configure_gsm_director(self,dtrname,dtrport,dtregion,gsmhost,cadmin,gsmtr):
                 """
                 This function configure GSM director
                 """
                 ## Getting the values of catalog_port,catalog_pdb,catalog_host
                 cpasswd="HIDDEN_STRING"
                 reg_exp= self.catalog_regex()
                 for key in self.ora_env_dict.keys():
                     if(reg_exp.match(key)):
                        catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)
                 sregionFlag=self.check_gsm_region(dtregion)
                 if sregionFlag != 'completed':
                    self.configure_gsm_region(dtregion)
                 if not self._is_wallet_enabled():   
                    cmd='''add gsm -gsm {0}  -listener {1} -pwd {2} -catalog {3}:{4}/{5}  -region {6} -trace_level {8}'''.format(
                       dtrname,dtrport,cpasswd,catalog_host,catalog_port,catalog_pdb,dtregion,gsmhost,gsmtr)
                 else:
                    wpwd="HIDDEN_STRING"
                    cmd='''add gsm -gsm {0}  -listener {1} -pwd {2} -wpwd {3} -catalog {4}:{5}/{6}  -region {7} -trace_level {9}'''.format(
                       dtrname,dtrport,cpasswd,wpwd,catalog_host,catalog_port,catalog_pdb,dtregion,gsmhost,gsmtr)
                 output,error,retcode=self._run_admin_gsm_statement(cmd,None)
                
      def start_gsm_director(self):
                 """
                 This function start the director in the GSM
                 """
                 status='noval'
                 self.ocommon.log_info_message("Inside start_gsm_director() function",self.file_name)
                 reg_exp= self.director_regex()
                 counter=1
                 end_counter=10
                 while counter < end_counter:
                   for key in self._iter_matching_keys(reg_exp):
                      dtrname,dtrport,dtregion=self.process_director_vars(key)
                      cmd='''start gsm -gsm {0}'''.format(dtrname)
                      output,error,retcode=self._run_admin_gsm_statement(cmd,None)
                      status=self.check_gsm_director(dtrname)
                      if status == 'completed':
                         break;
                   if status == 'completed':
                      filename=self.ora_env_dict["GSM_LOCK_STATUS_FILE"]
                      remfile='''rm -f {0}'''.format(filename)
                      if os.path.isfile(filename):
                         output,error,retcode=self.ocommon.execute_cmd(remfile,None,self.ora_env_dict)
                      break
                   else:
                      msg='''GSM shard director failed to start. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
                      self.ocommon.log_error_message(msg,self.file_name)
                      time.sleep(30)

                   counter=counter+1 
                                             

                 if status != 'completed':
                      msg='''GSM shard director failed to start. Exiting!'''
                      self.ocommon.log_error_message(msg,self.file_name)
                      self.ocommon.prog_exit("127")
                     
      def stop_gsm_director(self):
                 """
                 This function stop the director in the GSM
                 """
                 status=False
                 self.ocommon.log_info_message("Inside stop_gsm_director() function",self.file_name)
                 reg_exp= self.director_regex()
                 counter=1
                 end_counter=2
                 while counter < end_counter:
                   for key in self._iter_matching_keys(reg_exp):
                      dtrname,dtrport,dtregion=self.process_director_vars(key)
                      cmd='''stop gsm -gsm {0}'''.format(dtrname)
                      output,error,retcode=self._run_admin_gsm_statement(cmd,None)
                   counter=counter+1

      def status_gsm_director(self):
                 """
                 Check GSM director status.
                 """
                 gsm_status = self.check_gsm_director(None)
                 #catalog_status = self.check_gsm_catalog()

                 if gsm_status == 'completed':
                    msg='''Director setup completed in GSM and catalog is connected'''
                    self.ocommon.log_info_message(msg,self.file_name)
                 else:
                    msg='''Shard director in GSM did not complete or not connected to catalog. Exiting...'''
                    self.ocommon.log_error_message(msg,self.file_name)
                    self.ocommon.prog_exit("127")

      ######################################## Shard Group Setup Begins Here ############################
      def _validate_shardgroup_input_constraints(self,reg_exp):
                 """
                 Validate shardgroup input against sharding/replication rules.
                 """
                 ctx=self._get_sharding_context()
                 entries=[]
                 for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       group_name,deploy_as,group_region,shardspace,repfactor=self.process_shardg_vars(key)
                       entries.append({
                          "group_name":group_name,
                          "deploy_role":(str(deploy_as).strip().lower() if deploy_as else ""),
                          "shardspace":(str(shardspace).strip() if shardspace else "")
                       })

                 if entries == []:
                    return

                 # Shardgroup names must be unique across shardspaces.
                 seen={}
                 duplicate_names=[]
                 for item in entries:
                    gkey=item["group_name"].lower()
                    if gkey in seen and item["group_name"] not in duplicate_names:
                       duplicate_names.append(item["group_name"])
                    else:
                       seen[gkey]=True
                 if duplicate_names:
                    msg='''Duplicate shardgroup name(s) in input [{0}]. Shardgroup names must be unique across shardspaces.'''.format(
                       ",".join(duplicate_names))
                    self.ocommon.log_error_message(msg,self.file_name)
                    self.ocommon.prog_exit("127")

                 if ctx["repl_type"] != 'DG':
                    return

                 primary_entries=[item for item in entries if item["deploy_role"] == 'primary']
                 if primary_entries == []:
                    self.ocommon.log_error_message(
                       "DG replication requires at least one PRIMARY shardgroup in shardgroup input.",
                       self.file_name)
                    self.ocommon.prog_exit("127")

                 if ctx["sharding_type"] == 'system' and len(primary_entries) > 1:
                    msg='''System sharding allows only one PRIMARY shardgroup. Found PRIMARY in shardgroups [{0}].'''.format(
                       ",".join([item["group_name"] for item in primary_entries]))
                    self.ocommon.log_error_message(msg,self.file_name)
                    self.ocommon.prog_exit("127")

                 if ctx["sharding_type"] == 'system':
                    # Region uniqueness constraints:
                    # 1) one shardgroup must map to only one region
                    # 2) one region can map to only one shardgroup
                    group_region_map={}
                    region_group_map={}
                    for key in self.ora_env_dict.keys():
                       if reg_exp.match(key):
                          group_name,deploy_as,group_region,shardspace,repfactor=self.process_shardg_vars(key)
                          gkey=str(group_name).strip().lower()
                          rkey=str(group_region).strip().lower()
                          if gkey in group_region_map and group_region_map[gkey] != rkey:
                             msg='''System sharding: shardgroup [{0}] cannot span multiple regions [{1},{2}].'''.format(
                                group_name,group_region_map[gkey],rkey)
                             self.ocommon.log_error_message(msg,self.file_name)
                             self.ocommon.prog_exit("127")
                          group_region_map[gkey]=rkey
                          if rkey in region_group_map and region_group_map[rkey] != gkey:
                             msg='''System sharding: region [{0}] is already mapped to shardgroup [{1}] and cannot be reused by shardgroup [{2}].'''.format(
                                group_region,region_group_map[rkey],group_name)
                             self.ocommon.log_error_message(msg,self.file_name)
                             self.ocommon.prog_exit("127")
                          region_group_map[rkey]=gkey

                    # Cardinality constraints at shard DB level:
                    # - primary shardgroup must be unique (checked above)
                    # - per standby shardgroup, standby DB count must be <= primary DB count
                    primary_group_name=str(primary_entries[0]["group_name"]).strip().lower()
                    shard_counts=self._collect_shard_db_count_by_group()
                    primary_db_count=shard_counts.get(primary_group_name,0)
                    standby_groups=[item["group_name"] for item in entries if item["deploy_role"] in ('standby','active_standby')]
                    for standby_group in sorted(set([x.strip().lower() for x in standby_groups if x])):
                       standby_db_count=shard_counts.get(standby_group,0)
                       if standby_db_count > primary_db_count:
                          msg='''System sharding: standby shardgroup [{0}] has {1} standby databases but primary shardgroup [{2}] has only {3} primary databases.'''.format(
                             standby_group,standby_db_count,primary_group_name,primary_db_count)
                          self.ocommon.log_error_message(msg,self.file_name)
                          self.ocommon.prog_exit("127")

                    # Defensive guard: primary shardgroup must not appear as standby role.
                    primary_as_standby=[item for item in entries if item["group_name"].strip().lower() == primary_group_name and item["deploy_role"] in ('standby','active_standby')]
                    if primary_as_standby:
                       msg='''System sharding: PRIMARY shardgroup [{0}] must not be declared as STANDBY/ACTIVE_STANDBY.'''.format(primary_group_name)
                       self.ocommon.log_error_message(msg,self.file_name)
                       self.ocommon.prog_exit("127")

                 if ctx["sharding_type"] == 'composite':
                    # Composite requires explicit shardspace mapping for each shardgroup.
                    missing_group_shardspace=[item["group_name"] for item in entries if item["shardspace"] == ""]
                    if missing_group_shardspace:
                       msg='''Composite sharding requires shardspace in SHARD_GROUP params. Missing shardspace for group(s) [{0}].'''.format(
                          ",".join(missing_group_shardspace))
                       self.ocommon.log_error_message(msg,self.file_name)
                       self.ocommon.prog_exit("127")

                    # Validate group shardspace names against catalog shard_space list when provided.
                    catalog_spaces_raw=ctx["default_shardspace"] if ctx["default_shardspace"] else ""
                    catalog_spaces=[x.strip().lower() for x in str(catalog_spaces_raw).split(",") if x.strip() != ""]
                    if catalog_spaces:
                       invalid_spaces=[]
                       for item in entries:
                          if item["shardspace"].lower() not in catalog_spaces:
                             invalid_spaces.append(item["shardspace"])
                       if invalid_spaces:
                          msg='''Composite shardgroup shardspace must be present in SHARD_SPACE catalog list. Invalid shardspace(s) [{0}].'''.format(
                             ",".join(sorted(set(invalid_spaces))))
                          self.ocommon.log_error_message(msg,self.file_name)
                          self.ocommon.prog_exit("127")

                    shardspaces=sorted(set([item["shardspace"] for item in entries]))
                    if shardspaces == []:
                       self.ocommon.log_error_message(
                          "Composite sharding requires at least one shardspace mapped in SHARD_GROUP params.",
                          self.file_name)
                       self.ocommon.prog_exit("127")

                    missing_primary_shardspaces=[]
                    multi_primary_shardspaces=[]
                    missing_standby_shardspaces=[]
                    standby_roles=set(["standby","active_standby"])
                    for sspace in shardspaces:
                       primary_count=0
                       standby_count=0
                       group_count=0
                       for item in entries:
                          if item["shardspace"] == sspace:
                             group_count=group_count+1
                             if item["deploy_role"] == 'primary':
                                primary_count=primary_count+1
                             if item["deploy_role"] in standby_roles:
                                standby_count=standby_count+1
                       if group_count < 1:
                          continue
                       if primary_count < 1:
                          missing_primary_shardspaces.append(sspace)
                       if primary_count > 1:
                          multi_primary_shardspaces.append(sspace)
                       if standby_count < 1:
                          missing_standby_shardspaces.append(sspace)

                    if missing_primary_shardspaces:
                       msg='''Composite DG requires at least one PRIMARY shardgroup per shardspace. Missing PRIMARY for shardspace(s) [{0}].'''.format(
                          ",".join(missing_primary_shardspaces))
                       self.ocommon.log_error_message(msg,self.file_name)
                       self.ocommon.prog_exit("127")

                    if multi_primary_shardspaces:
                       msg='''Composite DG requires exactly one PRIMARY shardgroup per shardspace. Multiple PRIMARY shardgroups found for shardspace(s) [{0}].'''.format(
                          ",".join(multi_primary_shardspaces))
                       self.ocommon.log_error_message(msg,self.file_name)
                       self.ocommon.prog_exit("127")

                    if missing_standby_shardspaces:
                       msg='''Composite DG warning: no STANDBY shardgroup in shardspace(s) [{0}]. This is allowed, but physical standby is strongly recommended.'''.format(
                          ",".join(missing_standby_shardspaces))
                       self.ocommon.log_warn_message(msg,self.file_name)

      def _collect_shard_db_count_by_group(self):
                 """
                 Collect shard DB counts per shard_group from shard input keys.
                 Counts SHARDn_PARAMS and ADD_SHARD style keys.
                 """
                 counts={}
                 shard_patterns=[self.shard_regex(),self.add_shard_regex()]
                 for key in self.ora_env_dict.keys():
                    if not any([pat.match(key) for pat in shard_patterns]):
                       continue
                    params=self._parse_kv_params(key)
                    sgroup=params.get('shard_group')
                    if sgroup is None or str(sgroup).strip() == '':
                       continue
                    gkey=str(sgroup).strip().lower()
                    counts[gkey]=counts.get(gkey,0)+1
                 return counts

      def _collect_shardgroup_role_space_map(self,reg_exp):
                 """
                 Collect shardgroup role/shardspace metadata from shardgroup input keys.
                 """
                 role_by_group={}
                 space_by_group={}
                 for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       group_name,deploy_as,group_region,shardspace,repfactor=self.process_shardg_vars(key)
                       gkey=str(group_name).strip().lower()
                       role=(str(deploy_as).strip().lower() if deploy_as else "standby")
                       sspace=(str(shardspace).strip().lower() if shardspace else "")
                       role_by_group[gkey]=role
                       space_by_group[gkey]=sspace
                 return role_by_group,space_by_group

      def _validate_composite_shard_cardinality(self,reg_exp):
                 """
                 For COMPOSITE+DG shard input, enforce per-shardspace standby cardinality:
                 standby count in each standby shardgroup must be <= primary count in that shardspace.
                 """
                 ctx=self._get_sharding_context()
                 if ctx["sharding_type"] != 'composite' or ctx["repl_type"] != 'DG':
                    return

                 role_by_group,space_by_group=self._collect_shardgroup_role_space_map(self.shardg_regex())
                 if role_by_group == {}:
                    return

                 shard_count_by_group={}
                 for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       params=self._parse_kv_params(key)
                       sgroup=params.get('shard_group')
                       if sgroup is None or str(sgroup).strip() == '':
                          continue
                       gkey=str(sgroup).strip().lower()
                       shard_count_by_group[gkey]=shard_count_by_group.get(gkey,0)+1

                 if shard_count_by_group == {}:
                    return

                 primary_count_by_space={}
                 standby_count_by_space_group={}
                 for gkey,count in shard_count_by_group.items():
                    role=role_by_group.get(gkey,"")
                    sspace=space_by_group.get(gkey,"")
                    if sspace == "":
                       continue
                    if role == "primary":
                       primary_count_by_space[sspace]=primary_count_by_space.get(sspace,0)+count
                    elif role in ("standby","active_standby"):
                       if sspace not in standby_count_by_space_group:
                          standby_count_by_space_group[sspace]={}
                       standby_count_by_space_group[sspace][gkey]=standby_count_by_space_group[sspace].get(gkey,0)+count

                 for sspace,standby_map in standby_count_by_space_group.items():
                    primary_count=primary_count_by_space.get(sspace,0)
                    for gkey,standby_count in standby_map.items():
                       if standby_count > primary_count:
                          msg='''Composite sharding: standby shardgroup [{0}] in shardspace [{1}] has {2} standby databases but primary shardgroup has only {3} primary databases.'''.format(
                             gkey,sspace,standby_count,primary_count)
                          self.ocommon.log_error_message(msg,self.file_name)
                          self.ocommon.prog_exit("127")

      def _reject_unsupported_external_primary_source_params(self,reg_exp):
                 """
                 Explicitly reject unsupported external-primary source list params in this workflow.
                 """
                 unsupported_keys=set([
                    'standbyconfig',
                    'primaryconnectstrings',
                    'primarydatabaserefs',
                    'primaryendpoints',
                    'primary_connect_strings',
                    'primary_database_refs',
                    'primary_endpoints',
                 ])
                 for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       params=self._parse_kv_params(key)
                       for pkey in params.keys():
                          if str(pkey).strip().lower() in unsupported_keys:
                             msg='''Parameter [{0}] in [{1}] is not supported in this oragsm workflow. Use shardgroup/shard model only.'''.format(
                                pkey,key)
                             self.ocommon.log_error_message(msg,self.file_name)
                             self.ocommon.prog_exit("127")

      def _ordered_shard_keys(self,reg_exp):
                 """
                 Return deterministic shard-key order.
                 For COMPOSITE+DG: shardspace, PRIMARY first, then standby groups, then natural key.
                 Other modes: natural key order.
                 """
                 matched=[k for k in self.ora_env_dict.keys() if reg_exp.match(k)]
                 matched=sorted(matched, key=self.natural_key)
                 ctx=self._get_sharding_context()
                 if ctx["sharding_type"] != 'composite' or ctx["repl_type"] != 'DG':
                    return matched

                 role_by_group,space_by_group=self._collect_shardgroup_role_space_map(self.shardg_regex())

                 def role_rank(role):
                    r=(role or "").strip().lower()
                    if r == "primary":
                       return 0
                    if r in ("standby","active_standby"):
                       return 1
                    return 9

                 decorated=[]
                 for key in matched:
                    params=self._parse_kv_params(key)
                    gkey=str(params.get('shard_group') or "").strip().lower()
                    sspace=space_by_group.get(gkey,"")
                    role=role_by_group.get(gkey,"")
                    decorated.append((sspace,role_rank(role),gkey,self.natural_key(key),key))

                 decorated=sorted(decorated, key=lambda x: (x[0],x[1],x[2],x[3]))
                 return [item[4] for item in decorated]

      def setup_gsm_shardg(self,restype):
                 """
                  This function setup the shard group.
                 """
                 self.ocommon.log_info_message("Inside setup_gsm_shardg()",self.file_name)
                 ctx=self._get_sharding_context()
                 stype=ctx["sharding_type"]
                 if stype == 'user':
                    self.ocommon.log_error_message("Shardgroup operation is not supported for user sharding.",self.file_name)
                    self.ocommon.prog_exit("127")

                 if restype == 'ADD_SGROUP_PARAMS':
                    reg_exp=self.add_shardg_regex()
                 elif restype == 'SHARD_GROUP':
                    reg_exp=self.shardg_regex()
                 else:
                    self.ocommon.log_warn_message("No key specified for shardgroup setup. Skipping explicit shardgroup setup.",self.file_name)
                    return

                 self._validate_shardgroup_input_constraints(reg_exp)

                 completed=[]
                 pending=[]
                 for key in self._ordered_shard_keys(reg_exp):
                    group_name,deploy_as,group_region,shardspace,repfactor=self.process_shardg_vars(key)
                    sg_status=self.check_shardg_status(group_name,None)
                    if sg_status != 'completed':
                       self.configure_gsm_shardg(group_name,deploy_as,group_region,shardspace,repfactor,'add')
                       sg_status=self.check_shardg_status(group_name,None)
                    if sg_status == 'completed':
                       completed.append(group_name)
                    else:
                       pending.append(group_name)

                 if pending == []:
                    msg='''Shard group setup completed in GSM'''
                    self.ocommon.log_info_message(msg,self.file_name)
                 else:
                    msg='''Shard group setup did not complete for [{0}]'''.format(",".join(pending))
                    self.ocommon.log_error_message(msg,self.file_name)
                    self.ocommon.prog_exit("127")

      def get_shardg_region_name(self,sgname):
          """
          Get region name for a shard group.
          """
          self.ocommon.log_info_message("Inside get_shardg_region_name()",self.file_name)
          patterns=[self.shardg_regex(),self.add_shardg_regex()]
          for pattern in patterns:
              for key in self.ora_env_dict.keys():
                  if pattern.match(key):
                     group_name,deploy_as,group_region,shardspace,repfactor=self.process_shardg_vars(key)
                     if sgname == group_name:
                        return group_region
          self.ocommon.log_error_message("No such shard group exists! Exiting!",self.file_name)
          self.ocommon.prog_exit("127")

      def process_shardg_vars(self,key):
          """
          Process shardgroup params based on key.
          """
          self.ocommon.log_info_message("Inside process_shardg_vars()",self.file_name)
          ctx=self._get_sharding_context()
          if ctx["sharding_type"] == 'user':
             self.ocommon.log_error_message("Shardgroup params are not valid for user sharding.",self.file_name)
             self.ocommon.prog_exit("127")

          params=self._parse_kv_params(key)
          allowed_keys=set(['group_name','group_region','deploy_as','shardspace','repfactor'])
          self._validate_supported_keys(params,allowed_keys,key)

          group_name=self._require_param(params,'group_name',key)
          group_region=self._require_param(params,'group_region',key)
          deploy_as=params.get('deploy_as')
          shardspace=params.get('shardspace')
          repfactor=self._require_positive_int('repfactor',params.get('repfactor'),key)
          if ctx["sharding_type"] == 'composite' and (shardspace is None or str(shardspace).strip() == ''):
             self.ocommon.log_error_message("shardspace is required for composite shardgroup operations.",self.file_name)
             self.ocommon.prog_exit("127")

          repl_type=ctx["repl_type"]
          if repl_type == 'NATIVE' and deploy_as:
             self.ocommon.log_error_message("deploy_as is not supported for NATIVE replication shardgroup operations.",self.file_name)
             self.ocommon.prog_exit("127")
          if repl_type == 'DG' and (deploy_as is None or str(deploy_as).strip() == ''):
             deploy_as='standby'
          if repl_type == 'DG' and repfactor:
             self.ocommon.log_error_message("repfactor is supported only with NATIVE replication shardgroup operations.",self.file_name)
             self.ocommon.prog_exit("127")

          # In current DG/NATIVE-only flow, shardgroup repfactor is not consumed by backend.
          # Keep user input accepted and pass-through for command rendering if needed.
          return group_name,deploy_as,group_region,shardspace,repfactor

      def check_shardg_status(self,group_name,dname):
         """
         Check shard group status in GSM.
         """
         self.ocommon.log_info_message("Inside check_shardg_status()",self.file_name)
         status=False

         output,error,retcode=self._run_gsm_readonly_query("config",None)
         matched_output=re.findall("(?:Shard Groups\n)(?:.+\n)+",output)
         if self.ocommon.check_substr_match(matched_output[0],group_name):
            status=True
         else:
            status=False
            
         '''
          else:   
             reg_exp= self.shardg_regex()
             for key in self.ora_env_dict.keys():
                 if(reg_exp.match(key)):
                     group_name,deploy_as,group_region,shardspace,repfactor=self.process_shardg_vars(key)
                     dname=self.get_director_name(group_region)
                     gsmcmd=self.get_gsm_config_cmd(dname)
                     output,error,retcode=self._exec_gsm_cmd(gsmcmd,None)
                     matched_output=re.findall("(?:Shard Groups\n)(?:.+\n)+",output)  
                   #  match=re.search("(?i)(?m)"+group_name,matched_output)
                     if self.ocommon.check_substr_match(matched_output[0],group_name):
                          status=True
                     else:
                          status=False
         '''
         
         return(self.ocommon.check_status_value(status))

############################################# Director Related Block ############
      def get_director_name(self,region_name):
          """
          Get director name for a region.
          """
          self.ocommon.log_info_message("Inside get_director_name()",self.file_name)
          status=False
          director_name=None
          reg_exp= self.director_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)): 
                 dtrname,dtrport,dtregion=self.process_director_vars(key)
                 director_name=dtrname
                 gsm_status = self.check_gsm_director(dtrname)
                 if gsm_status == 'completed':
                    status = True
                 else:
                    status = False
                 if dtregion == region_name:
                    break
          if status:
             if director_name:
                return director_name
             else:
                self.ocommon.log_error_message("No director exist to match the region",self.file_name)
                self.ocommon.prog_exit("127")
          else:
             self.ocommon.log_error_message("Shard Director is not running!",self.file_name)
             self.ocommon.prog_exit("127")

########

      def get_gsm_config_cmd(self,dname):
          """
            Get the GSM config command
          """
          self.ocommon.log_info_message("Inside get_gsm_config_cmd()",self.file_name)
          gsmcmd='''
            config;
            exit;
          '''.format("test")
          return gsmcmd

      def process_director_vars(self,key):
          """
          Process GSM director vars and return validated values.
          """
          self.ocommon.log_info_message("Inside process_director_vars()",self.file_name)
          params=self._parse_kv_params(key)
          allowed_keys=set(['director_name','director_port','director_region'])
          self._validate_supported_keys(params,allowed_keys,key)

          dtrname=self._require_param(params,'director_name',key)
          dtrport_raw=self._require_param(params,'director_port',key)
          dtrport=self._require_positive_int('director_port',dtrport_raw,key)
          dtregion=self._require_param(params,'director_region',key)

          return dtrname,dtrport,dtregion
      
      def director_regex(self):
          """
            Return regex to search for shard director params.
          """
          self.ocommon.log_info_message("Inside director_regex()",self.file_name)
          return re.compile('SHARD_DIRECTOR_PARAMS')

      def shardg_regex(self):
          """
            Return regex to search for shard group params.
          """
          self.ocommon.log_info_message("Inside shardg_regex()",self.file_name)
          return re.compile('SHARD[0-9]+_GROUP_PARAMS')

      def add_shardg_regex(self):
          """
            Return regex to search for add shard group params.
          """
          self.ocommon.log_info_message("Inside shardg_regex()",self.file_name)
          return re.compile('ADD_SGROUP_PARAMS')

      def shardspace_regex(self):
          """
            Regex for named shardspace parameter keys.
          """
          self.ocommon.log_info_message("Inside shardspace_regex()",self.file_name)
          return re.compile('SHARD[0-9]+_SPACE_PARAMS')

      def add_shardspace_regex(self):
          """
            Regex for explicit add shardspace parameter key.
          """
          self.ocommon.log_info_message("Inside add_shardspace_regex()",self.file_name)
          return re.compile('ADD_SSPACE_PARAMS')

      def configure_gsm_shardg(self,group_name,deploy_as,group_region,shardspace,repfactor,type):
                 """
                  This function configure the Shard Group.
                 """
                 self.ocommon.log_info_message("Inside configure_gsm_shardg()",self.file_name)
                 ctx=self._get_sharding_context()
                 if ctx["sharding_type"] == 'user':
                    self.ocommon.log_error_message("Shardgroup is not supported for user sharding.",self.file_name)
                    self.ocommon.prog_exit("127")

                 cmd=self._build_add_or_modify_cmd(type,'shardgroup','shardgroup',group_name)

                 cmd=cmd + " -region {0} ".format(group_region)
                 if shardspace:
                    cmd=cmd + " -shardspace {0} ".format(shardspace)
                 if ctx["repl_type"] == 'DG' and deploy_as:
                    cmd=cmd + " -deploy_as {0} ".format(deploy_as)
                 if ctx["repl_type"] == 'NATIVE' and repfactor:
                    cmd=cmd + " -repfactor {0} ".format(repfactor)

                 output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def configure_gsm_region(self,region):
                 """
                  This function configure the Shard region.
                 """
                 self.ocommon.log_info_message("Inside configure_gsm_region()",self.file_name)
                 cmd=''' add region -region {0}'''.format(region)
                 output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def process_sspace_vars(self,key):
          """
          Process shardspace vars based on key.
          """
          self.ocommon.log_info_message("Inside process_sspace_vars()",self.file_name)
          ctx=self._get_sharding_context()
          stype=ctx["sharding_type"]
          repl_type=ctx["repl_type"]
          if stype == 'system':
             self.ocommon.log_error_message("Shardspace creation is not supported for system sharding in this workflow.",self.file_name)
             self.ocommon.prog_exit("127")

          params=self._parse_kv_params(key)
          allowed_keys=set(['sspace_name','chunks','repfactor','repunits','protectedmode','protectmode'])
          self._validate_supported_keys(params,allowed_keys,key)

          sspace=self._require_param(params,'sspace_name',key)
          chunks=self._require_positive_int('chunks',params.get('chunks'),key)
          repfactor=self._require_positive_int('repfactor',params.get('repfactor'),key)
          repunits=self._require_positive_int('repunits',params.get('repunits'),key)
          protectedmode=params.get('protectedmode')
          if protectedmode is None:
             protectedmode=params.get('protectmode')

          if repl_type == 'DG':
             if repfactor or repunits:
                self.ocommon.log_error_message("repfactor/repunits are supported only with NATIVE replication.",self.file_name)
                self.ocommon.prog_exit("127")
          elif repl_type == 'NATIVE':
             if protectedmode:
                self.ocommon.log_error_message("protectmode is supported only with DG replication.",self.file_name)
                self.ocommon.prog_exit("127")
          return sspace,chunks,repfactor,repunits,protectedmode

      def _guard_system_default_shardspace(self,reg_exp):
                 """
                 Block explicit shardspace operations for system sharding.

                 This workflow preserves Oracle default shardspace `SHARDSPACEORA`
                 for system sharding and prevents accidental regressions.
                 """
                 ctx=self._get_sharding_context()
                 if ctx["sharding_type"] != 'system':
                    return
                 for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       self.ocommon.log_error_message(
                          "Explicit shardspace setup is blocked for system sharding in this workflow to preserve default SHARDSPACEORA.",
                          self.file_name)
                       self.ocommon.prog_exit("127")

      def tns_bashrc_entry(self):
          """
          Add the TNS_ADMIN path to .bashrc for default user(oracle)
          """
          if self._is_wallet_enabled():
             self.ocommon.log_info_message("Inside tns_bashrc_entry()")
             tns_admin,wallet_dir,sqlnet_path,tns_path=self._wallet_paths()
          
             bashrc_path = "/home/oracle/.bashrc"
             add_line = '''export TNS_ADMIN={0}
'''.format(tns_admin)
             if os.path.exists(bashrc_path):
                with open(bashrc_path,'a') as fobj:
                   fobj.write(add_line)

      def setup_gsm_sspace(self,restype):
                 """
                  This function setup the shardspace.
                 """
                 self.ocommon.log_info_message("Inside setup_gsm_sspace()",self.file_name)
                 if restype == 'ADD_SSPACE_PARAMS':
                    reg_exp=self.add_shardspace_regex()
                 elif restype == 'SHARD_SPACE':
                    reg_exp=self.shardspace_regex()
                 else:
                    self.ocommon.log_warn_message("No key specified for shardspace setup. Skipping explicit shardspace setup.",self.file_name)
                    return

                 self._guard_system_default_shardspace(reg_exp)

                 completed=[]
                 pending=[]
                 for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       sspace,chunks,repfactor,repunits,protectedmode=self.process_sspace_vars(key)
                       ss_status=self.check_gsm_shardspace(sspace)
                       if ss_status != 'completed':
                          self.configure_gsm_sspace(sspace,chunks,repfactor,repunits,protectedmode,'add')
                          ss_status=self.check_gsm_shardspace(sspace)
                       if ss_status == 'completed':
                          completed.append(sspace)
                       else:
                          pending.append(sspace)

                 if pending == []:
                    self.ocommon.log_info_message("Shard space setup completed in GSM",self.file_name)
                 else:
                    msg='''Shard space setup did not complete for [{0}]'''.format(",".join(pending))
                    self.ocommon.log_error_message(msg,self.file_name)
                    self.ocommon.prog_exit("127")

      def configure_gsm_sspace(self,sspace,chunks,repfactor,repunits,protectedmode,type):
                 """
                  This function configure the shardspace.
                 """
                 self.ocommon.log_info_message("Inside configure_gsm_sspace()",self.file_name)
                 ctx=self._get_sharding_context()
                 repl_type=ctx["repl_type"]

                 cmd=self._build_add_or_modify_cmd(type,'shardspace','shardspace',sspace)

                 if chunks is not None:
                    cmd = cmd + ''' -chunks {0}'''.format(chunks)

                 if repl_type == 'NATIVE':
                    if repfactor:
                       cmd = cmd + ''' -repfactor {0}'''.format(repfactor)
                    if repunits is not None:
                       cmd = cmd + ''' -repunits {0}'''.format(repunits)
                 else:
                    if repfactor or repunits:
                       self.ocommon.log_error_message("repfactor/repunits are only valid for NATIVE replication.",self.file_name)
                       self.ocommon.prog_exit("127")
                    if protectedmode is not None:
                       cmd = cmd + ''' -protectmode {0}'''.format(protectedmode)

                 output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      #########################################Shard Function Begins Here ##############################
      def _validate_user_shard_input_constraints(self,reg_exp):
                """
                Validate USER+DG shard input so each shardspace in the request has
                at least one explicit PRIMARY shard.
                """
                ctx=self._get_sharding_context()
                if ctx["sharding_type"] != 'user' or ctx["repl_type"] != 'DG':
                   return

                shardspace_primary_map={}
                for key in self.ora_env_dict.keys():
                    if reg_exp.match(key):
                       params=self._parse_kv_params(key)
                       shard_space=params.get('shard_space')
                       if shard_space is None or str(shard_space).strip() == '':
                          # process_shard_vars() will raise a specific required-field error.
                          continue
                       shard_space_norm=str(shard_space).strip().lower()
                       deploy_as=params.get('deploy_as')
                       deploy_as_norm=(str(deploy_as).strip().lower() if deploy_as else "standby")
                       if shard_space_norm not in shardspace_primary_map:
                          shardspace_primary_map[shard_space_norm]=False
                       if deploy_as_norm == "primary":
                          shardspace_primary_map[shard_space_norm]=True

                missing_primary=[sspace for sspace,has_primary in shardspace_primary_map.items() if not has_primary]
                if missing_primary:
                   msg='''USER DG requires at least one explicit deploy_as=primary per shardspace in shard input. Missing PRIMARY for shardspace(s) [{0}].'''.format(
                      ",".join(sorted(missing_primary)))
                   self.ocommon.log_error_message(msg,self.file_name)
                   self.ocommon.prog_exit("127")

      def setup_gsm_shard(self):
                """
                This function setup and add shard in the GSM
                """
                self.ocommon.log_info_message("Inside setup_gsm_shard()",self.file_name)
                status=False
                reg_exp= self.shard_regex()
                self._validate_user_shard_input_constraints(reg_exp)
                self._reject_unsupported_external_primary_source_params(reg_exp)
                self._validate_composite_shard_cardinality(reg_exp)
                counter=1
                end_counter=60
                while counter < end_counter:                 
                      # Iterate over keys in natural-sorted order
                      for key in self._ordered_shard_keys(reg_exp):
                             shard_db_status=None
                             shard_db,shard_pdb,shard_port,shard_group,shard_host,sregion,sspace=self.process_shard_vars(key)
                             shard_db_status=self.check_setup_status(shard_host,shard_db,shard_pdb,shard_port)
                             if shard_db_status == 'completed':
                                self.configure_gsm_shard(shard_host,shard_db,shard_pdb,shard_port,shard_group,sregion,sspace)
                             else:
                                msg='''Shard db status must return completed but returned value is {0}'''.format(status)
                                self.ocommon.log_info_message(msg,self.file_name)
                                
                      status = self.check_shard_status(None) 
                      if status == 'completed':
                         break
                      else:
                         msg='''Shard DB setup is still not completed in GSM. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
                         self.ocommon.log_info_message(msg,self.file_name)
                      time.sleep(60)
                      counter=counter+1

                status = self.check_shard_status(None)
                if status == 'completed':
                   msg='''Shard DB setup completed in GSM'''
                   self.ocommon.log_info_message(msg,self.file_name)
                else:
                   msg='''Waited 60 minutes to complete shard db setup in GSM but setup did not complete or failed. Exiting...'''
                   self.ocommon.log_error_message(msg,self.file_name)
                   self.ocommon.prog_exit("127")     

      def add_gsm_shard(self):
                """
                This function add the shard in the GSM
                """
                self.ocommon.log_info_message("Inside add_gsm_shard()",self.file_name)
                status=False
                reg_exp= self.add_shard_regex()
                self._validate_user_shard_input_constraints(reg_exp)
                self._reject_unsupported_external_primary_source_params(reg_exp)
                self._validate_composite_shard_cardinality(reg_exp)
                counter=1
                end_counter=3
                shard_name="none"
                while counter < end_counter:
                      for key in self._ordered_shard_keys(reg_exp):
                             shard_db_status=None
                             shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space=self.process_shard_vars(key)
                             shard_name='''{0}_{1}'''.format(shard_db,shard_pdb)
                             shard_db_status=self.check_setup_status(shard_host,shard_db,shard_pdb,shard_port)
                             self.ocommon.log_info_message("Shard Status : " + shard_db_status,self.file_name)
                             if shard_db_status == 'completed':
                                self.configure_gsm_shard(shard_host,shard_db,shard_pdb,shard_port,shard_group,shard_region,shard_space)
                                counter2=1
                                end_counter2=5
                                while counter2 < end_counter2:
                                       status1 = self.check_shard_status(shard_name)
                                       if status1 == 'completed':
                                          msg='''Shard DB setup completed in GSM'''
                                          self.ocommon.log_info_message(msg,self.file_name)
                                          break
                                       else:
                                          msg='''Shard DB is still not added in GSM. Sleeping for 60 seconds'''
                                          self.ocommon.log_info_message(msg,self.file_name)
                                          time.sleep(60)
                                          counter2=counter2+1
                             else:
                                msg='''Shard db status must return completed but returned value is {0}'''.format(status)
                                self.ocommon.log_info_message(msg,self.file_name)
                      
                      status = self.check_shard_status(None)
                      if status == 'completed':
                         break
                      else:
                         msg='''Shard DB setup is still not completed in GSM. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
                         self.ocommon.log_info_message(msg,self.file_name)
                      time.sleep(60)
                      counter=counter+1
                status = self.check_shard_status(shard_name)
                if status == 'completed':
                   msg='''Shard DB setup completed in GSM'''
                   self.ocommon.log_info_message(msg,self.file_name)
                else:
                   msg='''Waited 3 minutes to complete shard db setup in GSM but setup did not complete or failed. Exiting...'''
                   self.ocommon.log_error_message(msg,self.file_name)
                   self.ocommon.prog_exit("127")

      def remove_gsm_shard(self):
                """
                This function remove the shard in the GSM
                """
                self.ocommon.log_info_message("Inside remove_gsm_shard()",self.file_name)
                catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars("CATALOG_PARAMS")
                numOfShards=self.count_online_shards()
                status=False
                reg_exp=self.remove_shard_regex()
                for key in list(self.ora_env_dict.keys()):
                    if(reg_exp.match(key)):
                          shard_db_status=None
                          shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space=self.process_shard_vars(key)
                          shardname_to_delete=shard_db + "_" + shard_pdb
                          if repl_type is not None:
                            if(repl_type.upper() == 'NATIVE'):
                               self.move_shards_leader_rus(shardname_to_delete)
                               leaderCount=self.count_leader_shards(shardname_to_delete)
                               if(numOfShards < 4 or leaderCount > 0):
                                  msg='''ruType=[{0}]. NumofShards=[{1}]. LeaderCount=[{2}]. Ignoring remove of shard [{3}]'''.format(repl_type,numOfShards,leaderCount,shardname_to_delete)
                                  self.ocommon.log_info_message(msg,self.file_name)
                                  break

                               self.move_shard_rus(shardname_to_delete,None,None)
                               while self.count_shard_rus(shardname_to_delete) > 0:
                                   self.ocommon.log_info_message("Waiting for all the shard chunks to be moved.",self.file_name)
                                   time.sleep(15)

                          shard_db_status=self.check_setup_status(shard_host,shard_db,shard_pdb,shard_port)
                          if shard_db_status == 'completed':
                             self.delete_gsm_shard(shard_host,shard_db,shard_pdb,shard_port,shard_group)
                             status=True
                          else:
                             msg='''Shard db status must return completed but returned value is {0}'''.format(status)
                             self.ocommon.log_info_message(msg,self.file_name)

                return status

      def move_shards_leader_rus(self,shardname_to_delete):
          """
          This function move the shard leader RUs
          """
          shards=self.get_online_shards()
          leader_ru=self.get_rus(shardname_to_delete)
          all_ru=self.get_rus(None)
          count=0
          target_shards=[]
          value=0
          
          if len(shards) == 0:
            msg="""No Shard is online so no RU is available to be moved"""
            self.ocommon.log_info_message(msg,self.file_name)
          else:
            for line in leader_ru:
                value=None
                count += 1
                cols=line.split()
                if len(cols) > 0:
                  if cols[0].lower() == shardname_to_delete.lower():
                    if cols[1].isdigit():
                       value = int(cols[1])
                    else:
                       continue
             
                  target_shards.clear()
                  for line1 in all_ru:
                    cols1=line1.split()
                    if len(cols1) > 5:
                      if cols1[0].lower() != shardname_to_delete.lower() and cols1[1].isdigit() and cols1[2].lower() == 'follower':
                        if value is not None:
                          if int(cols1[1]) == value:
                             target_shards.append(cols1[0])
                             break

                  for shard in shards:
                    if shard.lower() != shardname_to_delete.lower():
                      if shard in target_shards:
                        msg="Shard_name= " + shard + " Status=True"  + "  Value = " + str(value)
                        self.ocommon.log_info_message(msg,self.file_name)
                        self.move_shard_rus(shardname_to_delete,shard,value)
                    
      def move_shard_chunks(self):
                """
                This function move the shard chunks
                """
                self.ocommon.log_info_message("Inside move_shard_chunks()",self.file_name)
                reg_exp= self.move_chunks_regex()
                for key in self.ora_env_dict.keys():
                    if(reg_exp.match(key)):
                          shard_db,shard_pdb=self.process_chunks_vars(key) 
                          shard_name = '''{0}_{1}'''.format(shard_db,shard_pdb)
                          shard_num = self.count_online_shards()
                          online_shard = self.check_online_shard(shard_name)      
                          if shard_num > 1 and online_shard == 0 :
                             cmd='''
                              MOVE CHUNK -CHUNK ALL -SOURCE {0};
                              config shard
                             '''.format(shard_name)
                             output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def validate_nochunks(self):
                """
                Validate that shard has no remaining chunks.
                """
                self.ocommon.log_info_message("Inside validate_nochunks()",self.file_name)
                reg_exp= self.move_nochunks_regex()
                for key in self.ora_env_dict.keys():
                    if(reg_exp.match(key)):
                          shard_db,shard_pdb=self.process_chunks_vars(key)
                          shard_name = '''{0}_{1}'''.format(shard_db,shard_pdb)
                          shard_num = self.count_online_shards()
                          online_shard = self.check_online_shard(shard_name)
                          if shard_num > 1 and online_shard == 0 :
                             cmd='''config chunks -shard {0}'''.format(shard_name)
                             output,error,retcode=self._run_admin_gsm_statement(cmd,None)
                             matched_output=re.findall("(?:Chunks\n)(?:.+\n)+",output)  
                             if self.ocommon.check_substr_match(matched_output[0].lower(),shard_name.lower()):
                                self.ocommon.prog_exit("127")

      def move_chunks_regex(self):
          """
            Return regex for chunk-move trigger keys.
          """
          self.ocommon.log_info_message("Inside move_chunks_regex()",self.file_name)
          return re.compile('MOVE_CHUNKS')

      def move_nochunks_regex(self):
          """
            Return regex for no-chunks validation trigger keys.
          """
          self.ocommon.log_info_message("Inside move_nochunks_regex()",self.file_name)
          return re.compile('VALIDATE_NOCHUNKS')

      def check_shard_chunks(self):
                """
                Check shard chunk assignment details.
                """
                self.ocommon.log_info_message("Inside check_shard_chunks()",self.file_name)
                reg_exp= self.check_chunks_regex()
                for key in self.ora_env_dict.keys():
                    if(reg_exp.match(key)):
                          shard_db,shard_pdb=self.process_chunks_vars(key)
                          shard_name = '''{0}_{1}'''.format(shard_db,shard_pdb)
                          online_shard = self.check_online_shard(shard_name)
                          if online_shard == 0 :
                             cmd='''
                              config chunks -shard {0};
                              config shard
                             '''.format(shard_name)
                             output,error,retcode=self._run_admin_gsm_statement(cmd,None)


      def check_chunks_regex(self):
          """
            Return regex for chunk-check trigger keys.
          """
          self.ocommon.log_info_message("Inside check_chunks_regex()",self.file_name)
          return re.compile('CHECK_CHUNKS')

      def cancel_move_chunks(self):
                """
                Cancel chunk movement for target shards.
                """
                self.ocommon.log_info_message("Inside cancel_move_chunks()",self.file_name)
                reg_exp= self.cancel_chunks_regex()
                for key in self.ora_env_dict.keys():
                    if(reg_exp.match(key)):
                          shard_db,shard_pdb=self.process_chunks_vars(key)
                          shard_name = '''{0}_{1}'''.format(shard_db,shard_pdb)
                          online_shard = self.check_online_shard(shard_name)
                          if online_shard == 1:
                             self.ocommon.log_info_message("Shard is not online. Performing chunk cancellation in GSM to set the shard chunk status.",self.file_name)
                             cmd='''
                              ALTER MOVE -cancel -SHARD {0};
                              config shard
                             '''.format(shard_name)
                             output,error,retcode=self._run_admin_gsm_statement(cmd,None)
                          else: 
                             self.ocommon.log_info_message("Shard "  + shard_name  + "  is online. Unable to perform chunk cancellation.",self.file_name)

      def cancel_chunks_regex(self):
          """
            Return regex for chunk-cancel trigger keys.
          """
          self.ocommon.log_info_message("Inside cancel_chunks_regex()",self.file_name)
          return re.compile('CANCEL_CHUNKS')

      def verify_online_shard(self):
          """
           Verify that target shard(s) are online.
          """
          self.ocommon.log_info_message("Inside verify_online_shard()",self.file_name)
          status=False
          reg_exp= self.online_shard_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)):
                  shard_db,shard_pdb=self.process_chunks_vars(key)
                  shard_name = '''{0}_{1}'''.format(shard_db,shard_pdb)
                  online_shard = self.check_online_shard(shard_name)
                  if online_shard == 0:
                     msg='''Shard {0} is online.'''.format(shard_name)
                     self.ocommon.log_info_message(msg,self.file_name)
                  else:
                     msg='''Shard {0} is not online.'''.format(shard_name)
                     self.ocommon.log_info_message(msg,self.file_name)
                     self.ocommon.prog_exit("157")


      def online_shard_regex(self):
          """
            Return regex for online-shard verification keys.
          """
          self.ocommon.log_info_message("Inside online_shard_regex()",self.file_name)
          return re.compile('CHECK_ONLINE_SHARD')

      def check_online_shard(self,shard_name):
               """
               Check whether a shard is online and healthy.
               """
               self.ocommon.log_info_message("Inside check_online_shard()",self.file_name)
               name_flag = False
               availability_flag = False
               state_flag = False
               status_flag = False

               cmd='''config shard -shard {0}'''.format(shard_name)
               output,error,retcode=self._run_admin_gsm_statement(cmd,None)
               lines = output.split("\n")
               for line in lines:
                  list1 = line.split(":")
                  if list1[0].strip() == 'Name' and list1[1].strip().lower() == shard_name.lower():
                     name_flag = True
                  if list1[0].strip().lower() == 'Availability'.lower() and list1[1].strip().lower() == 'ONLINE'.lower():
                     availability_flag = True
                  if list1[0].strip().lower() == 'STATUS'.lower() and list1[1].strip().lower() == 'OK'.lower():
                     status_flag = True
                  if list1[0].strip().lower() == 'STATE'.lower() and list1[1].strip().lower() == 'DEPLOYED'.lower():
                     state_flag = True

                  del list1[:]

               if name_flag and availability_flag and state_flag and status_flag:
                  return 0
               else:
                  return 1

      def verify_gsm_shard(self):
          """
           Verify shard presence in GSM.
          """
          self.ocommon.log_info_message("Inside verify_gsm_shard()",self.file_name)
          status=False
          reg_exp= self.check_shard_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)):
                  shard_db,shard_pdb=self.process_chunks_vars(key)
                  shard_name = '''{0}_{1}'''.format(shard_db,shard_pdb)
                  gsm_shard = self.check_gsm_shard(shard_name)
                  if gsm_shard == 0:
                     msg='''Shard {0} is present in GSM.'''.format(shard_name)
                     self.ocommon.log_info_message(msg,self.file_name)
                  else:
                     msg='''Shard {0} is not present in GSM.'''.format(shard_name)
                     self.ocommon.log_info_message(msg,self.file_name)
                     self.ocommon.prog_exit("157")

      def check_shard_regex(self):
          """
            Return regex for GSM shard verification keys.
          """
          self.ocommon.log_info_message("Inside check_shard_regex()",self.file_name)
          return re.compile('CHECK_GSM_SHARD')

      def check_gsm_shard(self,shard_name):
               """
               Check shard presence in GSM.
               """
               self.ocommon.log_info_message("Inside check_gsm_shard()",self.file_name)
               name_flag = False

               cmd='''config shard -shard {0}'''.format(shard_name)
               output,error,retcode=self._run_admin_gsm_statement(cmd,None)
               lines = output.split("\n")
               for line in lines:
                  list1 = line.split(":")
                  if list1[0].strip() == 'Name' and list1[1].strip().lower() == shard_name.lower():
                     name_flag = True

                  del list1[:]

               if name_flag:
                  return 0
               else:
                  return 1

      def count_online_shards(self):
          """
            Return count of online shards.
          """   
          self.ocommon.log_info_message("Inside count_online_shards()",self.file_name)
          cmd='''config shard'''
          output,error,retcode=self._run_admin_gsm_statement(cmd,None)

          online_shard = 0
          lines = output.split("\n")
          for line in lines:
              if re.search('ok', line, re.IGNORECASE):
                 if re.search('deployed', line, re.IGNORECASE):
                    if re.search('online', line, re.IGNORECASE):
                       online_shard = online_shard + 1          

          return online_shard

      def get_online_shards(self):
          """
            Return list of online shards.
          """
          self.ocommon.log_info_message("Inside get_online_shards()",self.file_name)
          cmd='''config shard'''
          output,error,retcode=self._run_admin_gsm_statement(cmd,None)

          shards=[]
          online_shard = 0
          for line in output.split("\n"):
             cols=line.split()
             if len(cols) >= 5:
               if cols[5].lower() == "online" and cols[2].lower() == "ok":
                 shards.append(cols[0])

          return shards

      def get_rus(self,shardname_to_delete):
          """
            Return replication unit status lines.
          """
          self.ocommon.log_info_message("Inside get_rus()",self.file_name)
          wpwd="HIDDEN_STRING"
          cmd=None
          if shardname_to_delete is not None:
              cmd='''status ru -leaders -shard {0} -wpwd {1}'''.format(shardname_to_delete,wpwd)
          else:
              cmd='''status ru -wpwd {0}'''.format(wpwd)

          output,error,retcode=self._run_admin_gsm_statement(cmd,None)

          return output.split('\n')

      def move_shard_rus(self,sshard,tshard,runum):
                """
                Move or switchover shard replication units.
                """
                self.ocommon.log_info_message("Inside move_shard_rus()",self.file_name)
                cmd1=""
                shardname=sshard
                if tshard is not None and runum is not None:
                   cmd1='''switchover ru -RU {0} -shard {1}'''.format(runum,tshard)
                else:
                   cmd1='''MOVE RU -RU ALL -SOURCE {0}'''.format(shardname)

                wpwd="HIDDEN_STRING"
                cmd='''
                       configure -verbose off -save_config;
                       {0};
                       status RU -shard {1} -wpwd {2}
                '''.format(cmd1,shardname,wpwd)
                output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def count_shard_rus(self,shardname):
          """
            Return count of RUs for a shard.
          """   
          self.ocommon.log_info_message("Inside count_shard_rus()",self.file_name)
          wpwd="HIDDEN_STRING"
          cmd='''status ru -shard {0} -wpwd {1}'''.format(shardname,wpwd)
          output,error,retcode=self._run_admin_gsm_statement(cmd,None)

          ru_count = 0
          lines = output.split("\n")
          for line in lines:
              if re.search(shardname, line, re.IGNORECASE):
                       ru_count = ru_count + 1          

          return ru_count

      def count_leader_shards(self,shardName):
          """
            Return count of leader RUs for a shard.
          """   
          self.ocommon.log_info_message("Inside count_leader_shards()",self.file_name)
          wpwd="HIDDEN_STRING"
          cmd='''status ru -shard {0} -leaders -wpwd {1}'''.format(shardName,wpwd)
          output,error,retcode=self._run_admin_gsm_statement(cmd,None)

          leader_shard = 0
          lines = output.split("\n")
          for line in lines:
              if re.search('ok', line, re.IGNORECASE):
                 if re.search('Leader', line, re.IGNORECASE):
                       leader_shard = leader_shard + 1          

          return leader_shard

      def validate_gsm_shard(self):
                """
                Validate shard presence in GSM.
                """
                self.ocommon.log_info_message("Inside validate_gsm_shard()",self.file_name)
                status=False
                reg_exp= self.validate_shard_regex()
                for key in self.ora_env_dict.keys():
                    if(reg_exp.match(key)):
                          shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space=self.process_shard_vars(key)
                          shard_name='''{0}_{1}'''.format(shard_db,shard_pdb)
                          status = self.check_shard_status(shard_name)
                          if status == 'completed':
                             msg='''Shard DB setup completed in GSM.'''
                             self.ocommon.log_info_message(msg,self.file_name)
                          else:
                             msg='''Shard {0} info does not exist in GSM.'''.format(shard_name)
                             self.ocommon.log_info_message(msg,self.file_name)
                             self.ocommon.prog_exit("157")

      def process_shard_vars(self,key):
          """
          Process shard vars and enforce sharding/replication mode checks.
          """
          self.ocommon.log_info_message("Inside process_shard_vars()",self.file_name)
          ctx=self._get_sharding_context()
          stype=ctx["sharding_type"]
          repl_type=ctx["repl_type"]

          params=self._parse_kv_params(key)
          allowed_keys=set([
             'shard_db','shard_pdb','shard_port','shard_group','shard_host','shard_region','deploy_as','shard_space',
             'validate_network','force','savename','rack','cpu_threshold','disk_threshold',
             'cdb','gg_service','replace','pwd','connect'
          ])
          self._validate_supported_keys(params,allowed_keys,key)

          shard_db=self._require_param(params,'shard_db',key)
          shard_pdb=self._require_param(params,'shard_pdb',key)
          shard_host=self._require_param(params,'shard_host',key)
          shard_port=self._require_positive_int('shard_port',params.get('shard_port'),key)
          if shard_port is None:
             shard_port='1521'

          shard_group=params.get('shard_group')
          shard_region=params.get('shard_region')
          shard_space=params.get('shard_space')
          shard_deploy_as=params.get('deploy_as')
          shard_cdb=params.get('cdb')
          shard_gg_service=params.get('gg_service')
          shard_replace=params.get('replace')
          shard_pwd=params.get('pwd')
          shard_connect=params.get('connect')

          if shard_cdb is not None and str(shard_cdb).strip() != '':
             self.ora_env_dict['SHARD_CDB_OVERRIDE']=str(shard_cdb).strip()
          elif self.ocommon.check_key("SHARD_CDB_OVERRIDE",self.ora_env_dict):
             del self.ora_env_dict["SHARD_CDB_OVERRIDE"]

          if shard_gg_service is not None and str(shard_gg_service).strip() != '':
             self.ora_env_dict['SHARD_GG_SERVICE']=str(shard_gg_service).strip()
          elif self.ocommon.check_key("SHARD_GG_SERVICE",self.ora_env_dict):
             del self.ora_env_dict["SHARD_GG_SERVICE"]

          if shard_replace is not None and str(shard_replace).strip() != '':
             self.ora_env_dict['SHARD_REPLACE']=str(shard_replace).strip()
          elif self.ocommon.check_key("SHARD_REPLACE",self.ora_env_dict):
             del self.ora_env_dict["SHARD_REPLACE"]

          if shard_pwd is not None and str(shard_pwd).strip() != '':
             self.ora_env_dict['SHARD_PWD_OVERRIDE']=str(shard_pwd).strip()
          elif self.ocommon.check_key("SHARD_PWD_OVERRIDE",self.ora_env_dict):
             del self.ora_env_dict["SHARD_PWD_OVERRIDE"]

          if shard_connect is not None and str(shard_connect).strip() != '':
             self.ora_env_dict['SHARD_CONNECT_OVERRIDE']=str(shard_connect).strip()
          elif self.ocommon.check_key("SHARD_CONNECT_OVERRIDE",self.ora_env_dict):
             del self.ora_env_dict["SHARD_CONNECT_OVERRIDE"]

          # Optional add shard command flags
          shard_add_extra_opts=""
          if 'force' in params and self._is_true(params.get('force')):
             shard_add_extra_opts = shard_add_extra_opts + " -force"
          if 'savename' in params and self._is_true(params.get('savename')):
             shard_add_extra_opts = shard_add_extra_opts + " -savename"
          rack=params.get('rack')
          if rack:
             shard_add_extra_opts = shard_add_extra_opts + " -rack {0}".format(rack)

          cpu_threshold=params.get('cpu_threshold')
          if cpu_threshold is not None and str(cpu_threshold).strip() != '':
             cpu_threshold=self._require_positive_int('cpu_threshold',cpu_threshold,key)
             shard_add_extra_opts = shard_add_extra_opts + " -cpu_threshold {0}".format(cpu_threshold)

          disk_threshold=params.get('disk_threshold')
          if disk_threshold is not None and str(disk_threshold).strip() != '':
             disk_threshold=self._require_positive_int('disk_threshold',disk_threshold,key)
             shard_add_extra_opts = shard_add_extra_opts + " -disk_threshold {0}".format(disk_threshold)

          self.ora_env_dict['SHARD_ADD_EXTRA_OPTS']=shard_add_extra_opts

          if 'validate_network' in params:
             self.ora_env_dict['SHARD_VALIDATE_NETWORK']='true' if self._is_true(params.get('validate_network')) else 'false'
          else:
             self.ora_env_dict['SHARD_VALIDATE_NETWORK']='false'

          if repl_type == 'NATIVE' and shard_deploy_as:
             self.ocommon.log_error_message("deploy_as is not supported with NATIVE replication.",self.file_name)
             self.ocommon.prog_exit("127")

          if stype == 'user':
             if shard_group:
                self.ocommon.log_error_message("shard_group is not valid for user sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")
             if not shard_space:
                self.ocommon.log_error_message("shard_space is required for user sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")
             shard_group='nogrp'
             if repl_type == 'DG':
                if not shard_deploy_as:
                   shard_deploy_as='standby'
                self.ora_env_dict=self.ocommon.add_key("SHARD_DEPLOY_AS",shard_deploy_as,self.ora_env_dict)

          elif stype == 'system':
             if not shard_group:
                self.ocommon.log_error_message("shard_group is required for system sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")
             if shard_space:
                self.ocommon.log_error_message("shard_space cannot be used directly in system sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")
             if shard_deploy_as:
                self.ocommon.log_error_message("deploy_as cannot be combined with shard_group for system sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")

          elif stype == 'composite':
             if not shard_group:
                self.ocommon.log_error_message("shard_group is required for composite sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")
             if shard_deploy_as:
                self.ocommon.log_error_message("deploy_as cannot be combined with shard_group for composite sharding add shard.",self.file_name)
                self.ocommon.prog_exit("127")

          return shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space

      def validate_shard_param(self,param_type,value):
         """
         Validate shard parameter values such as region and shardspace.
         """
         status=False
         reg_exp= self.catalog_regex()
         stype=None
         sspace=None
         catalog_region=None
         self.ocommon.log_info_message("Processing GSM params to verify the region and shardspace",self.file_name)
         for key in self.ora_env_dict.keys():
             if(reg_exp.match(key)):
                 catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)

         if param_type == 'region':
            if stype:
               status=self.ocommon.find_str_in_string(catalog_region,'comma',value)
               if status:
                  
                  return value
               else:
                  return ""
         
         if param_type == 'shardspace':
            if sspace:
               status=self.ocommon.find_str_in_string(sspace,'comma',value)
               if status:
                  return value
               else:
                  return ""
            
         return False
         
      def process_chunks_vars(self,key):
         """
           Process chunk operation parameters.
         """
         shard_db=None
         shard_pdb=None
         self.ocommon.log_info_message("Inside process_chunks_vars()",self.file_name)
         cvar_str=self.ora_env_dict[key]
         cvar_str=cvar_str.replace('"', '')
         cvar_dict=dict(item.split("=") for item in cvar_str.split(";"))
         for ckey in cvar_dict.keys():
             if ckey == 'shard_db':
                shard_db = cvar_dict[ckey]
             if ckey == 'shard_pdb':
                shard_pdb = cvar_dict[ckey]

         if shard_pdb and shard_db:
             return shard_db,shard_pdb
         else:
             msg1='''shard_db={0},shard_pdb={1}'''.format((shard_db or "Missing Value"),(shard_pdb or "Missing Value"))
             self.ocommon.log_info_message(msg1,self.file_name)
             self.ocommon.prog_exit("Error occurred")

      def check_shard_status(self,shard_name):
          """
           Check shard status in GSM.
          """
          self.ocommon.log_info_message("Inside check_shard_status()",self.file_name)
          counter=1
          end_counter=3
          status=False
          while counter < end_counter:
             output,error,retcode=self._run_gsm_readonly_query("config",None)
             error_check=re.findall("(?:GSM-45034\n)(?:.+\n)+",output)
             try: 
                if self.ocommon.check_substr_match(error_check[0],"GSM-45034"):
                   count = counter + 1
                   self.ocommon.log_info_message("Issue in catalog connection, retrying to connect to catalog in 30 seconds!",self.file_name)
                   time.sleep(20)
                   status=False
                   continue 
             except:
                status=False
             matched_output=re.findall("(?:Databases\n)(?:.+\n)+",output)
             if shard_name:
                try:
                  if self.ocommon.check_substr_match(matched_output[0],shard_name.lower()):
                     status=True
                     break
                  else:
                     status=False
                except:
                  status=False
             else:
                reg_exp= self.shard_regex()
                for key in self.ora_env_dict.keys():
                    if(reg_exp.match(key)):
                      shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space=self.process_shard_vars(key)
                      shard_name='''{0}_{1}'''.format(shard_db,shard_pdb)
                      try:
                        if self.ocommon.check_substr_match(matched_output[0],shard_name.lower()):
                           status=True
                        else:
                          status=False
                      except:
                        status=False
                if status:
                   break;
             counter = counter + 1

          return(self.ocommon.check_status_value(status))

      def shard_regex(self):
          """
            Return regex for shard parameter keys.
          """
          self.ocommon.log_info_message("Inside shard_regex()",self.file_name)
          return re.compile('SHARD[0-9]+_PARAMS') 

      def natural_key(self,s):
          """
            Use natural (human) sort for all keys so SHARDn_PARAMS are ordered by n
          """
          return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", s)]          

      def add_shard_regex(self):
          """
            Return regex for add-shard parameter keys.
          """
          self.ocommon.log_info_message("Inside add_shard_regex()",self.file_name)
          return re.compile('ADD_SHARD')

      def remove_shard_regex(self):
          """
            Return regex for remove-shard parameter keys.
          """
          self.ocommon.log_info_message("Inside remove_shard_regex()",self.file_name)
          return re.compile('REMOVE_SHARD')

      def validate_shard_regex(self):
          """
            Return regex for validate-shard parameter keys.
          """
          self.ocommon.log_info_message("Inside validate_shard_regex()",self.file_name)
          return re.compile('VALIDATE_SHARD')

      def configure_gsm_shard(self,shost,scdb,spdb,sdbport,sgroup,sregion,sspace):
         """
         Configure shard database in GSM.
         """
         spasswd="HIDDEN_STRING"
         if self.ocommon.check_key("SHARD_PWD_OVERRIDE",self.ora_env_dict):
            spasswd=self.ora_env_dict["SHARD_PWD_OVERRIDE"]

         ctx=self._get_sharding_context()
         stype=ctx["sharding_type"]

         shard_region=""
         shard_space=""
         shard_group=""
         shard_cdb=scdb
         connect_value='''(DESCRIPTION = (ADDRESS = (PROTOCOL = tcp)(HOST = {0})(PORT = {1})) (CONNECT_DATA = (SERVICE_NAME = {2}) (SERVER = DEDICATED)))'''.format(shost,sdbport,spdb)
         deploy_as=""
         validate_network=""
         replace_opt=""
         gg_service_opt=""
         shard_add_extra_opts=self.ora_env_dict["SHARD_ADD_EXTRA_OPTS"] if self.ocommon.check_key("SHARD_ADD_EXTRA_OPTS",self.ora_env_dict) else ""

         if self.ocommon.check_key("SHARD_CDB_OVERRIDE",self.ora_env_dict):
            shard_cdb=self.ora_env_dict["SHARD_CDB_OVERRIDE"]
         if self.ocommon.check_key("SHARD_CONNECT_OVERRIDE",self.ora_env_dict):
            connect_value=self.ora_env_dict["SHARD_CONNECT_OVERRIDE"]
         if self.ocommon.check_key("SHARD_REPLACE",self.ora_env_dict):
            replace_opt=" -replace {0}".format(self.ora_env_dict["SHARD_REPLACE"])
         if self.ocommon.check_key("SHARD_GG_SERVICE",self.ora_env_dict):
            gg_service_opt=" -gg_service {0}".format(self.ora_env_dict["SHARD_GG_SERVICE"])

         if self.ocommon.check_key("SHARD_VALIDATE_NETWORK",self.ora_env_dict):
            if self._is_true(self.ora_env_dict["SHARD_VALIDATE_NETWORK"]):
               validate_network=" -validate_network"

         if sregion and stype == 'user':
            regionFlag=self.check_gsm_region(sregion)
            if regionFlag != 'completed':
               self.configure_gsm_region(sregion)
            shard_region=" -region {0}".format(sregion)

         if sspace:
            shard_space=" -shardspace {0}".format(sspace)

         if stype == 'user':
            sspaceFlag=self.check_gsm_shardspace(sspace)
            if sspaceFlag != 'completed':
               self.configure_gsm_sspace(sspace,None,None,None,None,'add')
            deploy_as,deploy_type=self.get_shard_deploy()
         else:
            shard_group,deploy_as=self.get_shardg_cmd(sgroup,sregion)
            shard_region=""
            deploy_as=""
            # For system/composite add shard, shardgroup path is authoritative.
            # Allow incoming shard_space input but do not pass both flags together.
            shard_space=""

         cmd='''
         add cdb -connect {0}:{1}/{11} -pwd {3};
         add shard -cdb {11} -connect "{12}" {5} -pwd {3} {6} {7} {8}{9}{10}{13}{14};
         config vncr
         '''.format(shost,sdbport,scdb,spasswd,spdb,shard_group,shard_region,shard_space,deploy_as,validate_network,shard_add_extra_opts,shard_cdb,connect_value,replace_opt,gg_service_opt)
         output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def get_shard_deploy(self):
         """
         Get shard deploy clause for add shard.
         """
         ctx=self._get_sharding_context()
         if ctx["repl_type"] == 'NATIVE':
            return "",None

         deploy_type='primary'
         if self.ocommon.check_key("SHARD_DEPLOY_AS",self.ora_env_dict):
            deploy_type=self.ora_env_dict["SHARD_DEPLOY_AS"]
         deploy_as="-deploy_as {0}".format(deploy_type)
         return deploy_as,deploy_type

      def get_shardg_cmd(self,sgroup,sregion):
         """
         Ensure shardgroup exists and return add-shard group clause.
         """
         if not sgroup:
            self.ocommon.log_error_message("shard_group is required for system/composite add shard.",self.file_name)
            self.ocommon.prog_exit("127")

         group_region=sregion
         if not group_region:
            group_region=self.get_shardg_region_name(sgroup)

         sgFlag=self.check_shardg_status(sgroup,None)
         if sgFlag != 'completed':
            self.configure_gsm_shardg(sgroup,None,group_region,None,None,'add')
         else:
            self.ocommon.log_info_message("Shardgroup exists " + sgroup,self.file_name)

         cmd=''' -shardgroup {0}'''.format(sgroup)
         return cmd,""

      def delete_gsm_shard(self,shost,scdb,spdb,sdbport,sgroup):
         """
         Delete shard database from GSM.
         """
         shard_name='''{0}_{1}'''.format(scdb,spdb)
         cmd='''
         remove shard -shard {0};
         remove cdb -cdb {1};
         remove invitednode {2};
         config vncr
         '''.format(shard_name,scdb,shost)
         output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def set_hostid_null(self):
          """
           Set host ID to NULL in catalog metadata.
          """
          spasswd="HIDDEN_STRING"
          admuser= self.ora_env_dict["SHARD_ADMIN_USER"]
          reg_exp= self.catalog_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)):
                 catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)
                 sqlpluslogin=self._build_sqlplus_login("sys","as sysdba","CATALOG",catalog_host,catalog_port,catalog_pdb)
                 self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
                 msg='''Setting host Id null in catalog as auto vncr is disabled'''
                 self.ocommon.log_info_message(msg,self.file_name)
                 sqlcmd='''
                  set echo on
                  set termout on
                  set time on
                  update gsmadmin_internal.database set hostid=NULL;
                 '''
                 output,error,retcode=self._run_sqlplus_and_check(sqlpluslogin,sqlcmd,None)
                 self.ocommon.unset_mask_str()

      def invited_node_op(self):
         """
         Perform invited node remove/add cycle.
         """
         self.ocommon.log_info_message("Inside invited_node_op()",self.file_name)
         shard_host=self.ora_env_dict["INVITED_NODE_OP"]
         cmd='''remove invitednode {0}'''.format(shard_host)
         output,error,retcode=self._run_admin_gsm_statement(cmd,None)

         time.sleep(240)

         cmd='''add invitednode {0}'''.format(shard_host)
         output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def add_invited_node(self,op_str):
         """
         Add invited node(s) in GSM configuration.
         """
         self.ocommon.log_info_message("Inside add_invited_node()",self.file_name)
         if op_str == "SHARD":
            reg_exp = self.shard_regex()
         else:
            reg_exp = self.add_shard_regex()

         for key in self.ora_env_dict.keys():
            if(reg_exp.match(key)):
               shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space=self.process_shard_vars(key)
               cmd='''add invitednode {0}'''.format(shard_host)
               output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def remove_invited_node(self,op_str):
         """
         Remove invited node(s) in GSM configuration.
         """
         self.ocommon.log_info_message("Inside remove_invited_node()",self.file_name)
         if op_str == "SHARD":
            reg_exp = self.shard_regex()
         else:
            reg_exp = self.add_shard_regex()

         if self.ocommon.check_key("KUBE_SVC",self.ora_env_dict):
            for key in self.ora_env_dict.keys():
               if(reg_exp.match(key)):
                  shard_db,shard_pdb,shard_port,shard_group,shard_host,shard_region,shard_space=self.process_shard_vars(key)
                  temp_host= shard_host.split('.',1)[0]
                  cmd='''remove invitednode {0}'''.format(temp_host)
                  output,error,retcode=self._run_admin_gsm_statement(cmd,None)
         else:
            self.ocommon.log_info_message("KUBE_SVC is not set. No need to remove invited node!",self.file_name)


      def deploy_shard(self):
         """
         Trigger shard deploy in GSM.
         """
         self.ocommon.log_info_message("Inside deploy_shard()",self.file_name)
         ctx=self._get_sharding_context()
         if ctx["sharding_type"] == 'user':
            shardg_shardspace="config shardspace"
         else:
            shardg_shardspace="config shardgroup"

         cmd='''
            {0};
            config vncr;
            deploy;
            config shard
         '''.format(shardg_shardspace)
         output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      def check_setup_status(self,host,ccdb,svc,port):
         """
            Check shard setup status in CDB and PDB.
         """
         systemStr=self._build_sqlplus_login("system",None,"CATALOG_CDB",host,port,ccdb)
         
         tmp_dir = self.ora_env_dict["TMP_DIR"]
         fname='''{0}/{1}'''.format(tmp_dir,"shard_setup.txt")
         self.ocommon.remove_file(fname)
         self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
         msg='''Checking shardsetup table in CDB'''
         self.ocommon.log_info_message(msg,self.file_name)
         sqlcmd='''
         set heading off
         set feedback off
         set  term off
         SET NEWPAGE NONE
         spool {0}
         select * from shardsetup WHERE ROWNUM = 1;
         spool off
         exit;
         '''.format(fname)
         output,error,retcode=self._run_sqlplus_and_check(systemStr,sqlcmd,None)

         if os.path.isfile(fname): 
            fdata=self.ocommon.read_file(fname)
         else:
            fdata='nosetup'

         ### Unsetting the encrypt value to None
         self.ocommon.unset_mask_str()

         if re.search('completed',fdata):
            status = self.catalog_pdb_setup_check(host,ccdb,svc,port)
            if status == 'completed':
               return 'completed'
            else:
               return 'notcompleted'
         else:
            return 'notcompleted'


      def catalog_pdb_setup_check(self,host,ccdb,svc,port):
         """
            Check PDB readiness for shard setup.
         """
         systemStr=self._build_sqlplus_login("pdbadmin",None,"CATALOG_PDB",host,port,svc)

         tmp_dir = self.ora_env_dict["TMP_DIR"]
         fname='''{0}/{1}'''.format(tmp_dir,"pdb_setup_check.txt")
         self.ocommon.remove_file(fname)
         self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
         msg='''Checking setup status in PDB'''
         self.ocommon.log_info_message(msg,self.file_name)
         sqlcmd='''
         set heading off
         set feedback off
         set  term off
         SET NEWPAGE NONE
         spool {0}
         select count(*) from dual;
         spool off
         exit;
         '''.format(fname)
         output,error,retcode=self._run_sqlplus_and_check(systemStr,sqlcmd,None)

         if os.path.isfile(fname):
            fdata=self.ocommon.read_file(fname)
         else:
            fdata='nosetup'

         ### Unsetting the encrypt value to None
         self.ocommon.unset_mask_str()

         if re.search('1',fdata):
            return 'completed'
         else:
            return 'notcompleted'

      ############################# Setup GSM Service ###############################################
      def setup_gsm_service(self):
         """
         Set up shard service(s).
         """
         self.ocommon.log_info_message("Inside setup_gsm_service()",self.file_name)
         status=False
         service_value="service_name=oltp_rw_svc;service_role=primary;service_mode=readwrite"
   #     self.ora_env_dict=self.ocommon.add_key("SERVICE1_PARAMS",service_value,self.ora_env_dict)
         reg_exp= self.service_regex()
         counter=1
         end_counter=3
         while counter < end_counter:
               for key in self.ora_env_dict.keys():
                  if(reg_exp.match(key)):
                     shard_service_status=None
                     service_name,service_role,service_mode=self.process_service_vars(key)
                     shard_service_status=self.check_service_status(service_name)
                     if shard_service_status != 'completed':
                        self.configure_gsm_service(service_name,service_role,service_mode)
               status = self.check_service_status(None)
               if status == 'completed':
                  break
               else:
                  msg='''GSM service setup is still not completed in GSM. Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
               time.sleep(60)
               counter=counter+1

         status = self.check_service_status(None)
         if status == 'completed':
            msg='''Shard service setup completed in GSM'''
            self.ocommon.log_info_message(msg,self.file_name)
         else:
            msg='''Waited 2 minutes to complete catalog setup in GSM but setup did not complete or failed. Exiting...'''
            self.ocommon.log_error_message(msg,self.file_name)
            self.ocommon.prog_exit("127")

      def process_service_vars(self,key):
          """
          Process shard service parameters from input key.
          """
          service_name=None
          service_role=None
          service_mode=None

          self.ocommon.log_info_message("Inside process_service_vars()",self.file_name)

          cvar_str=self.ora_env_dict[key]
          cvar_dict=dict(item.split("=") for item in cvar_str.split(";"))
          for ckey in cvar_dict.keys():
              if ckey == 'service_name':
                 service_name = cvar_dict[ckey]
              if ckey == 'service_role':
                 service_role = cvar_dict[ckey]
              if ckey == 'service_mode':
                 service_mode = cvar_dict[ckey]

              ### Check values must be set
          if service_name and service_role:
             return service_name,service_role,service_mode
          else:
             msg1='''service_name={0},service_role={1}'''.format((service_name or "Missing Value"),(service_role or "Missing Value"))
             msg='''Shard service params {0} is not set correctly. One or more value is missing {1} {2}'''.format(key,msg1)
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("Error occurred")

      def check_service_status(self,service_name):
          """
           Check service status in GSM.
          """
          self.ocommon.log_info_message("Inside check_service_status()",self.file_name)
          #dtrname,dtrport,dtregion=self.process_director_vars()
          output,error,retcode=self._run_gsm_readonly_query("config",None)
          matched_output=re.findall("(?:Services\n)(?:.+\n)+",output)
          status=False
          if service_name:
            try:
              if self.ocommon.check_substr_match(matched_output[0],service_name):
                 status=True
              else:
                 status=False
            except:
              status=False
          else:
            reg_exp= self.service_regex()
            for key in self.ora_env_dict.keys():
               if(reg_exp.match(key)):
                  service_name,service_role,service_mode=self.process_service_vars(key)
               #  match=re.search("(?i)(?m)"+service_name,matched_output)
                  try:
                    if self.ocommon.check_substr_match(matched_output[0],service_name):
                      status=True
                    else:
                      status=False
                  except:
                      status=False
          
          return(self.ocommon.check_status_value(status))

      def service_regex(self):
          """
            Return regex for service parameter keys.
          """
          self.ocommon.log_info_message("Inside service_regex()",self.file_name)
          return re.compile('SERVICE[0-9]+_PARAMS')
		  
      def configure_gsm_service(self,service_name,service_role,service_mode):
         """
         Configure service creation in GSM.
         """
         self.ocommon.log_info_message("Inside configure_gsm_service()",self.file_name)
         catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars("CATALOG_PARAMS")

         #dtrname,dtrport,dtregion=self.process_director_vars()
         cmd='''
            add service -service {0} -role {1};
            start service -service {0}
         '''.format(service_name,service_role)

         if repl_type is not None:
            if(repl_type.upper() == 'NATIVE'):
              if service_mode is None:
                 msg='''Shard service params {0} is not set correctly. Native type. Missing service_mode parameter.'''.format(service_name)
                 self.ocommon.log_error_message(msg,self.file_name)
                 self.ocommon.prog_exit("Error occurred")
              cmd='''
                add service -service {0} -ru_mode {1};
                start service -service {0}
              '''.format(service_name,service_mode)
         output,error,retcode=self._run_admin_gsm_statement(cmd,None)

      ############################## GSM backup fIle function Begins Here #############################
      def gsm_backup_file(self):
          """
            Back up GSM network admin files.
          """
          self.ocommon.log_info_message("Inside gsm_backup_file()",self.file_name)
          gsmdata_loc='/opt/oracle/gsmdata'
          gsmfile_loc='''{0}/network/admin'''.format(self.ora_env_dict["ORACLE_HOME"])

          if os.path.isdir(gsmdata_loc):
             msg='''Directory {0} exit'''.format(gsmdata_loc)
             self.ocommon.log_info_message(msg,self.file_name)

          cmd='''cp -r -v {0}/* {1}/'''.format(gsmfile_loc,gsmdata_loc)
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,True)

      ############### Deploy Sample Function Begins Here ##########################
      def setup_sample_schema(self):
          """
            Deploy sample application schema.
          """
          s = "abcdefghijklmnopqrstuvwxyz01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()?"
          passlen = 8
          passwd  =  "".join(random.sample(s,passlen )) 
          self.ocommon.log_info_message("Inside deploy_sample_schema()",self.file_name)
          reg_exp= self.catalog_regex()
          for key in self.ora_env_dict.keys():
              if(reg_exp.match(key)):
                 catalog_db,catalog_pdb,catalog_port,catalog_region,catalog_host,catalog_name,catalog_chunks,repl_type,repl_factor,repl_unit,stype,sspace,cfname=self.process_clog_vars(key)
          sqlpluslogin=self._build_sqlplus_login("sys","as sysdba","CATALOG_CDB",catalog_host,catalog_port,catalog_db)
          if self.ocommon.check_key("SAMPLE_SCHEMA",self.ora_env_dict):
             if self.ora_env_dict["SAMPLE_SCHEMA"] == 'DEPLOY':
                tmp_dir = self.ora_env_dict["TMP_DIR"]
                self.ocommon.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
                msg='''Deploying sample schema'''
                self.ocommon.log_info_message(msg,self.file_name)
                sqlcmd='''
                 set echo on
                 set termout on
                 set time on
                 spool {4}/create_app_schema.lst
                 REM
                 REM Connect to the Shard Catalog and Create Schema
                 REM
                 alter session enable shard ddl;
                 alter session set container={2};
                 alter session enable shard ddl;
                 create user app_schema identified by {3};
                 grant connect, resource, alter session to app_schema;
                 grant execute on dbms_crypto to app_schema;
                 grant create table, create procedure, create tablespace, create materialized view to app_schema;
                 grant unlimited tablespace to app_schema;
                 grant select_catalog_role to app_schema;
                 grant all privileges to app_schema; 
                 grant gsmadmin_role to app_schema;
                 grant dba to app_schema;
                 CREATE TABLESPACE SET tbsset1 IN SHARDSPACE shd1;
                 CREATE TABLESPACE SET tbsset2 IN SHARDSPACE shd2;
                 connect app_schema/{3}@{0}:{1}/{2}
                 alter session enable shard ddl;

                 /* Customer shard table */

                 CREATE SHARDED TABLE customer
                 ( cust_id NUMBER NOT NULL,
                  cust_passwd VARCHAR2(20) NOT NULL,
                  cust_name VARCHAR2(60) NOT NULL,
                  cust_type VARCHAR2(10) NOT NULL,
                  cust_email VARCHAR2(100) NOT NULL)
                  partitionset by list (cust_type)
                  partition by consistent hash (cust_id) partitions auto
                  (partitionset individual values ('individual') tablespace set tbsset1,
                  partitionset  business values ('business') tablespace set tbsset2
                  );
                 /* Invoice shard table */

                 CREATE SHARDED TABLE invoice 
                 ( invoice_id  NUMBER NOT NULL,
                 cust_id  NUMBER NOT NULL,
                 cust_type VARCHAR2(10) NOT NULL,
                 vendor_name VARCHAR2(60) NOT NULL,
                 balance FLOAT(10) NOT NULL,
                 total FLOAT(10) NOT NULL,    
                 status VARCHAR2(20),  
                 CONSTRAINT InvoicePK PRIMARY KEY (cust_id, invoice_id))
                 PARENT customer
                 partitionset by list (cust_type)
                 partition by consistent hash (cust_id) partitions auto
                 (partitionset individual values ('individual') tablespace set tbsset1,
                 partitionset  business values ('business') tablespace set tbsset2
                 );
                 /* Data */
                 insert into customer values (999, 'pass', 'Customer 999', 'individual', 'customer999@gmail.com');
                 insert into customer values (250251, 'pass', 'Customer 250251', 'individual', 'customer250251@yahoo.com');
                 insert into customer values (350351, 'pass', 'Customer 350351', 'individual', 'customer350351@gmail.com');
                 insert into customer values (550551, 'pass', 'Customer 550551', 'business', 'customer550551@hotmail.com');
                 insert into customer values (650651, 'pass', 'Customer 650651', 'business', 'customer650651@live.com');
                 insert into invoice values (1001, 999, 'individual', 'VendorA', 10000, 20000, 'Due');
                 insert into invoice values (1002, 999, 'individual', 'VendorB', 10000, 20000, 'Due');
                 insert into invoice values (1001, 250251, 'individual', 'VendorA', 10000, 20000, 'Due');
                 insert into invoice values (1002, 250251, 'individual', 'VendorB', 0, 10000, 'Paid');
                 insert into invoice values (1003, 250251, 'individual', 'VendorC', 14000, 15000, 'Due');
                 insert into invoice values (1001, 350351, 'individual', 'VendorD', 10000, 20000, 'Due');
                 insert into invoice values (1002, 350351, 'individual', 'VendorE', 0, 10000, 'Paid');
                 insert into invoice values (1003, 350351, 'individual', 'VendorF', 14000, 15000, 'Due');
                 insert into invoice values (1004, 350351, 'individual', 'VendorG', 12000, 15000, 'Due');
                 insert into invoice values (1001, 550551, 'business', 'VendorH', 10000, 20000, 'Due');
                 insert into invoice values (1002, 550551, 'business', 'VendorI', 0, 10000, 'Paid');
                 insert into invoice values (1003, 550551, 'business', 'VendorJ', 14000, 15000, 'Due');
                 insert into invoice values (1004, 550551, 'business', 'VendorK', 10000, 20000, 'Due');
                 insert into invoice values (1005, 550551, 'business', 'VendorL', 10000, 20000, 'Due');
                 insert into invoice values (1006, 550551, 'business', 'VendorM', 0, 10000, 'Paid');
                 insert into invoice values (1007, 550551, 'business', 'VendorN', 14000, 15000, 'Due');
                 insert into invoice values (1008, 550551, 'business', 'VendorO', 10000, 20000, 'Due');
                 insert into invoice values (1001, 650651, 'business', 'VendorT', 10000, 20000, 'Due');
                 insert into invoice values (1002, 650651, 'business', 'VendorU', 0, 10000, 'Paid');
                 insert into invoice values (1003, 650651, 'business', 'VendorV', 14000, 15000, 'Due');
                 insert into invoice values (1004, 650651, 'business', 'VendorW', 10000, 20000, 'Due');
                 insert into invoice values (1005, 650651, 'business', 'VendorX', 0, 20000, 'Paid');
                 insert into invoice values (1006, 650651, 'business', 'VendorY', 0, 30000, 'Paid');
                 insert into invoice values (1007, 650651, 'business', 'VendorZ', 0, 10000, 'Paid');
                 commit;
                 select table_name from user_tables;
                 spool off
                '''.format(catalog_host,catalog_port,catalog_pdb,passwd,tmp_dir)
                output,error,retcode=self._run_sqlplus_and_check(sqlpluslogin,sqlcmd,None)
          ### Unsetting the encrypt value to None
                self.ocommon.unset_mask_str()

                #dtrname,dtrport,dtregion=self.process_director_vars()
                cmd='''show ddl'''
                output,error,retcode=self._run_admin_gsm_statement(cmd,None)

          ###################################### Run custom scripts ##################################################
      def run_custom_scripts(self):
          """
           Custom script to be executed on every restart of environment
          """
          self.ocommon.log_info_message("Inside run_custom_scripts()",self.file_name)
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

      ############################### GSM Completion Message #######################################################
      def gsm_completion_message(self):
          """
           Print setup completion message.
          """
          self.ocommon.log_info_message("Inside gsm_completion_message()",self.file_name)
          msg=[]
          msg.append('==============================================')
          msg.append('     GSM Setup Completed                      ')
          msg.append('==============================================')

          for text in msg:
              self.ocommon.log_info_message(text,self.file_name)



      ############################### GET GSM Trace Level ###############################################
      def get_gsm_trace_level(self):
          """
           Get validated GSM trace level.
          """
          self.ocommon.log_info_message("Inside get_gsm_trace_level()",self.file_name)
          if self.ocommon.check_key("GSM_TRACE_LEVEL",self.ora_env_dict):
             gsm_trace_level = self.ora_env_dict["GSM_TRACE_LEVEL"]
             if gsm_trace_level in {'USER','ADMIN','SUPPORT','OFF'}:
                msg='''GSM Trace Level is Passed and is set to {0}'''.format(gsm_trace_level)
                self.ocommon.log_info_message(msg,self.file_name)
             else:
                self.ocommon.log_info_message("INVALID value passed for parameter GSM_TRACE_LEVEL.",self.file_name)
                self.ocommon.prog_exit("127")
          else:
             self.ocommon.log_info_message("No value passed for parameter GSM_TRACE_LEVEL. It will be set to OFF.",self.file_name)
             gsm_trace_level='OFF'
          return gsm_trace_level
