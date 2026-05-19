#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

from oralogger import *
from oraenv import *
import subprocess
import sys
import time
import datetime
import os
import getopt
import shlex
import json
import logging
import socket
import re
import os.path
import stat
import itertools
import string
import random
import glob
import pathlib


class OraCommon:
    def __init__(self, oralogger, orahandler, oraenv):
        """
        Initialize shared logger, handler, and environment references.
        """
        self.ologger = oralogger
        self.ohandler = orahandler
        self.oenv = oraenv.get_instance()
        self.ora_env_dict = oraenv.get_env_vars()
        self.file_name = os.path.basename(__file__)

    def _decode_stream(self, stream_data):
        """
        Decode subprocess stream data safely.
        """
        if stream_data is None:
            return ""
        if isinstance(stream_data, bytes):
            return stream_data.decode(errors="replace")
        return str(stream_data)

    def _normalize_cwd(self, cwd):
        """
        Keep backward compatibility: only valid path-like cwd is used.
        """
        if isinstance(cwd, (str, bytes, os.PathLike)):
            return cwd
        return None

    def _oracle_env_paths(self, home):
        """
        Return PATH and LD_LIBRARY_PATH values derived from an Oracle home.
        """
        path = '/usr/bin:/bin:/sbin:/usr/local/sbin:{0}/bin'.format(home)
        ldpath = '{0}/lib:/lib:/usr/lib'.format(home)
        return path, ldpath

    def _prepare_command(self, cmd, use_shell):
        """
        Prepare command for logging/masking and subprocess execution.
        """
        if use_shell:
            if isinstance(cmd, (list, tuple)):
                cmd = " ".join([str(x) for x in cmd])
            cmd = str(cmd)
            log_cmd = self.mask_str(cmd)
            exec_cmd = self.unmask_str(cmd)
            return log_cmd, exec_cmd

        if isinstance(cmd, (list, tuple)):
            cmd_parts = [str(x) for x in cmd]
        else:
            cmd_parts = shlex.split(str(cmd))

        log_parts = [self.mask_str(part) for part in cmd_parts]
        exec_parts = [self.unmask_str(part) for part in cmd_parts]
        return " ".join(log_parts), exec_parts

    def _execute_process(self, cmd, env=None, cwd=None, use_shell=True, stdin_data=None):
        """
        Unified subprocess execution helper for shell and noshell runs.
        """
        try:
            log_cmd, exec_cmd = self._prepare_command(cmd, use_shell)
            self.log_info_message("Received Command : {0}".format(log_cmd), self.file_name)

            popen_stdin = subprocess.PIPE if stdin_data is not None else None
            normalized_cwd = self._normalize_cwd(cwd)

            out = subprocess.Popen(
                exec_cmd,
                shell=use_shell,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=popen_stdin,
                env=env,
                cwd=normalized_cwd
            )

            if stdin_data is not None and not isinstance(stdin_data, bytes):
                stdin_data = str(stdin_data).encode()

            output, error = out.communicate(stdin_data)
            retcode = out.returncode
        except Exception:
            error_msg = sys.exc_info()
            self.log_error_message(error_msg, self.file_name)
            self.prog_exit(self)

        return self._decode_stream(output), self._decode_stream(error), retcode

    def run_sqlplus(self, cmd, sql_cmd, dbenv):
        """
        This function execute the ran sqlplus or rman script and return the output
        """
        message = "Received Command : {0}\n{1}".format(self.mask_str(cmd), self.mask_str(sql_cmd))
        self.log_info_message(message, self.file_name)
        return self._execute_process(cmd, env=dbenv, cwd=None, use_shell=True, stdin_data=sql_cmd)

    def execute_cmd(self, cmd, env, dir, use_shell=True):
        """
        Execute an OS command with shell or without shell.
        `dir` is kept for backward compatibility and treated as cwd.
        """
        cwd = dir
        return self._execute_process(cmd, env=env, cwd=cwd, use_shell=use_shell, stdin_data=None)

    def execute_cmd_noshell(self, cmd_list, env=None, cwd=None):
        """
        Backward-compatible wrapper for non-shell command execution.
        """
        return self.execute_cmd(cmd_list, env, cwd, use_shell=False)

    def execute_cmd_checked(self, cmd, env=None, cwd=None, use_shell=True, exit_on_error=True):
        """
        Execute a command and run standard OS error handling.
        """
        output, error, retcode = self.execute_cmd(cmd, env, cwd, use_shell=use_shell)
        self.check_os_err(output, error, retcode, exit_on_error)
        return output, error, retcode

    def mask_str(self, mstr):
        """
         Function to mask the string.
        """
        newstr = None
        if self.oenv.encrypt_str__:
            newstr = mstr.replace('HIDDEN_STRING', '********')
#            self.log_info_message(newstr,self.file_name)
        if newstr:
           #        message = "Masked the string as encryption flag is set in the singleton class"
           #        self.log_info_message(message,self.file_name)
            return newstr
        else:
            return mstr

    def unmask_str(self, mstr):
        """
        Function to unmask the string.
        """
        newstr = None
        if self.oenv.encrypt_str__:
            newstr = mstr.replace(
                'HIDDEN_STRING', self.oenv.original_str__.rstrip())
    #       self.log_info_message(newstr,self.file_name)
        if newstr:
            #       message = "Unmasked the encrypted string and returning original string from singleton class"
            #       self.log_info_message(message,self.file_name)
            return newstr
        else:
            return mstr

    def set_mask_str(self, mstr):
        """
        Function to unmask the string.
        """
        if mstr:
           #        message = "Setting encrypted String flag to True and original string in singleton class"
           #        self.log_info_message(message,self.file_name)
            self.oenv.encrypt_str__ = True
            self.oenv.original_str__ = mstr
        else:
            message = "Masked String is empty so no change required in encrypted string flag and original string in singleton class"
            self.log_info_message(message, self.file_name)

    def unset_mask_str(self):
        """
        Function to unmask the string.
        """
  #      message = "Un-setting encrypted String flag and original string to None in Singleton class"
  #      self.log_info_message(message,self.file_name)
        self.oenv.encrypt_str__ = None
        self.oenv.original_str__ = None

    def prog_exit(self, message):
        """
        This function exit the program because of some error
        """
        self.update_statefile("failed")
        sys.exit(127)

    def update_statefile(self, message):
        """
        This function update the state file
        """
        file = self.oenv.statelogfile_name()
        if self.check_file(file, "local", None, None):
            self.write_file(file, message)

    def log_info_message(self, lmessage, fname):
        """
        Print the INFO message in the logger
        """
        funcname = sys._getframe(1).f_code.co_name
        message = '''{:^15}-{:^20}:{}'''.format(fname.split(
            '.', 1)[0], funcname.replace("_", ""), lmessage)
        self.ologger.msg_ = message
        self.ologger.logtype_ = "INFO"
        self.ohandler.handle(self.ologger)

    def log_error_message(self, lmessage, fname):
        """
        Print the Error message in the logger
        """
        funcname = sys._getframe(1).f_code.co_name
        message = '''{:^15}-{:^20}:{}'''.format(fname.split(
            '.', 1)[0], funcname.replace("_", ""), lmessage)
        self.ologger.msg_ = message
        self.ologger.logtype_ = "ERROR"
        self.ohandler.handle(self.ologger)

    def log_warn_message(self, lmessage, fname):
        """
        Print the Error message in the logger
        """
        funcname = sys._getframe(1).f_code.co_name
        message = '''{:^15}-{:^20}:{}'''.format(fname.split(
            '.', 1)[0], funcname.replace("_", ""), lmessage)
        self.ologger.msg_ = message
        self.ologger.logtype_ = "WARN"
        self.ohandler.handle(self.ologger)

    def log_step(self, component, action, status, detail=None, fname=None):
        """
        Log standardized operation-step messages without changing logger backend behavior.
        """
        file_name = fname if fname else self.file_name
        c = str(component).strip() if component else "common"
        a = str(action).strip() if action else "step"
        s = str(status).strip() if status else "info"
        d = (" | " + str(detail).strip()) if detail else ""
        msg = "[{0}] {1} :: {2}{3}".format(c, a, s, d)
        self.log_info_message(msg, file_name)

    def check_sql_err(self, output, err, retcode, status):
        """
        Check if there are any error in sql command output
        """
        match = None
        msg2 = '''Sql command  failed.Flag is set not to ignore this error.Please Check the logs,Exiting the Program!'''
        msg3 = '''Sql command  failed.Flag is set to ignore this error!'''
        self.log_info_message(
            "output : " + str(output or "no Output"), self.file_name)

        if status:
            if (retcode != 0):
                self.log_info_message(
                    "Error  : " + str(err or "no Error"), self.file_name)
                self.log_error_message(
                    "Sql Login Failed.Please Check the logs,Exiting the Program!", self.file_name)
                self.prog_exit(self)

        match = re.search("(?i)(?m)error", output)
        if status:
            if (match):
                self.log_error_message(msg2, self.file_name)
                self.prog_exit("error")
            else:
                self.log_info_message(
                    "Sql command completed successfully", self.file_name)
        else:
            if (match):
                self.log_warn_message(
                    "Sql command failed. Flag is set to ignore the error.", self.file_name)
            else:
                self.log_info_message(
                    "Sql command completed sucessfully.", self.file_name)

    def check_dgmgrl_err(self, output, err, retcode, status):
        """
        Check if there are any error in sql command output
        """
        match = None
        msg2 = '''DGMGRL command  failed.Flag is set not to ignore this error.Please Check the logs,Exiting the Program!'''
        msg3 = '''DGMGRL  command  failed.Flag is set to ignore this error!'''
        self.log_info_message(
            "output : " + str(output or "no Output"), self.file_name)

        if status:
            if (retcode != 0):
                self.log_info_message(
                    "Error  : " + str(err or "no Error"), self.file_name)
                self.log_error_message(
                    "DGMGRL Login Failed.Please Check the logs,Exiting the Program!", self.file_name)
                self.prog_exit(self)

        match = re.search("(?i)(?m)failed", output)
        if status:
            if (match):
                self.log_error_message(msg2, self.file_name)
                self.prog_exit("error")
            else:
                self.log_info_message(
                    "DGMGRL command completed successfully", self.file_name)
        else:
            if (match):
                self.log_warn_message(
                    "DGMGRL command failed. Flag is set to ignore the error.", self.file_name)
            else:
                self.log_info_message(
                    "DGGRL command completed sucessfully.", self.file_name)

    def check_os_err(self, output, err, retcode, status):
        """
        Check if there are any error in OS command execution
        """
        msg1 = '''OS command returned code : {0} and returned output : {1}'''.format(
            str(retcode), str(output or "no Output"))
        msg2 = '''OS command returned code : {0}, returned error : {1} and returned output : {2}'''.format(
            str(retcode), str(err or "no returned error"), str(output or "no retruned output"))
        msg3 = '''OS command  failed. Flag is set to ignore this error!'''

        if status:
            if (retcode != 0):
                self.log_error_message(msg2, self.file_name)
                self.prog_exit(self)
            else:
                self.log_info_message(msg1, self.file_name)
        else:
            if (retcode != 0):
                self.log_warn_message(msg2, self.file_name)
                self.log_warn_message(msg3, self.file_name)
            else:
                self.log_info_message(msg1, self.file_name)

    def check_key(self, key, env_dict):
        """
          Check the key if it exist in dictionary.
          Attributes:
             key (string): String to check if key exist in dictionary
             env_dict (dict): Contains the env variable related to seup
        """
        if key in env_dict:
            return True
        else:
            return False

    def empty_key(self, key):
        """
           key is empty and print failure message.
          Attributes:
             key (string): String is empty
        """
        msg = '''Variable {0} is not defilned. Exiting!'''.format(key)
        self.log_error_message(msg, self.file_name)
        self.prog_exit(self)

    def add_key(self, key, value, env_dict):
        """
          Add the key in the dictionary.
          Attributes:
             key (string): key String to add in the dictionary
             value (String): value String to add in dictionary

          Return:
             dict
        """
        if self.check_key(key, env_dict):
            msg = '''Variable {0} already exists in the env variables'''.format(
                key)
            self.log_info_message(msg, self.file_name)
        else:
            if value:
                env_dict[key] = value
                self.oenv.update_env_vars(env_dict)
            else:
                msg = '''Variable {0} value is not defined to add in the env variables. Exiting!'''.format(
                    key)
                self.log_error_message(msg, self.file_name)
                self.prog_exit(self)

        return env_dict

    def update_key(self, key, value, env_dict):
        """
          update the key in the dictionary.
          Attributes:
             key (string): key String to update in the dictionary
             value (String): value String to update in dictionary

          Return:
             dict
        """
        if self.check_key(key, env_dict):
            if value:
                env_dict[key] = value
                self.oenv.update_env_vars(env_dict)
            else:
                msg = '''Variable {0} value is not defined to update in the env variables!'''.format(
                    key)
                self.log_warn_message(msg, self.file_name)
        else:
            msg = '''Variable {0} does not exist in the env variables'''.format(
                key)
            self.log_info_message(msg, self.file_name)

        return env_dict

    def upsert_env(self, key, value, env_dict):
        """
        Set env key value by updating existing entry or adding a new one.
        """
        if self.check_key(key, env_dict):
            return self.update_key(key, value, env_dict)
        return self.add_key(key, value, env_dict)

    def validate_response_file(self, rsp_path, rsp_label):
        """
        Validate response file path and existence and return normalized path.
        """
        if rsp_path and os.path.isfile(rsp_path):
            return rsp_path

        label = rsp_label if rsp_label else "response"
        self.log_error_message(
            "{0} response file does not exist at location: {1}. Exiting...".format(
                str(label).capitalize(), str(rsp_path)
            ),
            self.file_name
        )
        self.prog_exit("127")

    def get_first_active_crs_node(self, existing_crs_nodes, ocvu):
        """
        Return first cluster node where cluvfy clumgr passes.
        """
        if not existing_crs_nodes:
            return None

        for cnode in str(existing_crs_nodes).split(","):
            cnode = cnode.strip()
            if not cnode:
                continue
            retcode3 = ocvu.check_clu(cnode, True, None)
            if retcode3 == 0:
                return cnode
        return None

    def validate_operation_env(self, op_type, env_dict):
        """
        Validate operation env keys and set operation defaults where applicable.
        """
        op = (op_type or "").lower()
        required_keys_by_op = {
            "setupgrid": ["OP_TYPE"],
            "setuprac": ["OP_TYPE"],
            "gridaddnode": ["OP_TYPE"],
            "racaddnode": ["OP_TYPE"],
            "racdelnode": ["OP_TYPE"],
            "miscops": ["OP_TYPE"],
        }
        defaults_by_op = {
            "setupgrid": {"ORASETUPENV_TIMEOUT_MINUTES": "15"},
            "setuprac": {"ORASETUPENV_TIMEOUT_MINUTES": "15"},
            "gridaddnode": {"ORASETUPENV_TIMEOUT_MINUTES": "15"},
            "racaddnode": {"ORASETUPENV_TIMEOUT_MINUTES": "15"},
        }

        for key, value in defaults_by_op.get(op, {}).items():
            if not self.check_key(key, env_dict):
                env_dict = self.upsert_env(key, value, env_dict)
                self.log_info_message(
                    "{0} not set for operation {1}. Defaulting to {2}".format(key, op, value),
                    self.file_name
                )

        for req_key in required_keys_by_op.get(op, []):
            if not self.check_key(req_key, env_dict):
                self.log_error_message(
                    "Required env variable {0} is not set for operation {1}. Exiting...".format(
                        req_key, op
                    ),
                    self.file_name
                )
                self.prog_exit("127")

        return env_dict

    def read_file(self, fname):
        """
          Read the contents of a file and returns the contents to end user
          Attributes:
             fname (string): file to be read

          Return:
             file data (string)
        """
        f1 = open(fname, 'r')
        fdata = f1.read()
        f1.close
        return fdata

    def write_file(self, fname, fdata):
        """
          write the contents to a file
          Attributes:
             fname (string): file to be written
             fdata (string): COnetents to be written

          Return:
             file data (string)
        """
        f1 = open(fname, 'w')
        f1.write(fdata)
        f1.close

    def append_file(self, fname, fdata):
        """
          appened the contents to a file
          Attributes:
             fname (string): file to be written
             fdata (string): COnetents to be written

          Return:
             file data (string)
        """
        f1 = open(fname, 'a')
        f1.write(fdata)
        f1.close

    def create_dir(self, dir, local, remote, user, group):
        """
          Create dir locally or remotely
          Attributes:
             dir (string): dir to be created
             local (boolean): dir to craetes locally
             remote (boolean): dir to be created remotely
             node (string): remote node name on which dir to be created
             user (string): remote user to be connected
        """
        self.log_info_message("Inside create_dir()", self.file_name)
        if local:
            if not os.path.isdir(dir):
                cmd = '''mkdir -p {0}'''.format(dir)
                output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
                cmd = '''chown -R {0}:{1} {2}'''.format(user, group, dir)
                output, error, retcode = self.execute_cmd(cmd, None, None)
                cmd = '''chmod 755 {0}'''.format(dir)
                output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
            else:
                msg = '''Dir {0} already exists'''.format(dir)
                self.log_info_message(msg, self.file_name)

    def create_file(self, file, local, remote, user):
        """
          Create dir locally or remotely
          Attributes:
             file (string): file to be created
             local (boolean): dir to craetes locally
             remote (boolean): dir to be created remotely
             node (string): remote node name on which dir to be created
             user (string): remote user to be connected
        """
        self.log_info_message("Inside create_file()", self.file_name)
        if local:
            if not os.path.isfile(file):
                cmd = '''touch  {0}'''.format(file)
                output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

    def create_pfile(self, pfile, spfile):
        """
          Create pfile from spfile locally
        """
        self.log_info_message("Inside create_pfile()", self.file_name)
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        osid = self.ora_env_dict["GOLD_SID_NAME"]

        sqlpluslogincmd = self.get_sqlplus_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        sqlcmd = """
               create pfile='{0}' from spfile='{1}';
          """.format(pfile, spfile)
        self.log_info_message(
            "Running the sqlplus command to create pfile from spfile: " + sqlcmd, self.file_name)
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

    def create_spfile(self, spfile, pfile):
        """
          Create spfile from pfile locally
        """
        self.log_info_message("Inside create_spfile()", self.file_name)
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        osid = self.ora_env_dict["DB_NAME"] + "1"

        sqlpluslogincmd = self.get_sqlplus_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        sqlcmd = """
               create spfile='{0}' from pfile='{1}';
          """.format(spfile, pfile)
        self.log_info_message(
            "Running the sqlplus command to create spfile from pfile: " + sqlcmd, self.file_name)
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

    def resetlogs(self, osid):
        """
          Reset the database logs
        """
        self.log_info_message("Inside resetlogs()", self.file_name)
        osuser, dbhome, dbbase, oinv = self.get_db_params()

        sqlpluslogincmd = self.get_sqlplus_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        sqlcmd = '''
               alter database open resetlogs;
          '''
        self.log_info_message(
            "Running the sqlplus command to resetlogs" + sqlcmd, self.file_name)
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

    def check_file(self, file, local, remote, user):
        """
          check locally or remotely
          Attributes:
             file (string): file to be created
             local (boolean): dir to craetes locally
             remote (boolean): dir to be created remotely
             node (string): remote node name on which dir to be created
             user (string): remote user to be connected
        """
        self.log_info_message("Inside check_file()", self.file_name)
        if local:
            if os.path.isfile(file):
                return True
            else:
                return False

    def latest_file(self, dir,):
        """
        List the latest file in a directory
        """
        files = os.listdir(dir)
        paths = [os.path.join(dir, basename) for basename in files]
        return max(paths, key=os.path.getctime)

    def latest_dir(self, dir, subdir):
        """
        Get the latest dir matching a regexp
        """
        self.log_info_message(" Received Params : basedir=" +
                              dir + " subdir=" + subdir, self.file_name)
        if subdir is None:
            subdir = '*/'
        dir1 = sorted(pathlib.Path(dir).glob(subdir), key=os.path.getmtime)[-1]
        return dir1

    def shutdown_db(self, osid):
        """
        Shutdown the database
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        self.log_info_message("Inside shutdown_db()", self.file_name)
        sqlpluslogincmd = self.get_sqlplus_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)

        sqlcmd = '''
                  shutdown immediate;
           '''
        self.log_info_message(
            "Running the sqlplus command to shutdown the database: " + sqlcmd, self.file_name)
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, False)

    def start_db(self, osid, mode, pfile=None):
        """
        start  the database
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        self.log_info_message("Inside start_db()", self.file_name)
        cmd = ""
        if mode is None:
            mode = " "

        if pfile is not None:
            cmd = '''startup {1} pfile={0}'''.format(pfile, mode)
        else:
            cmd = '''startup {0}'''.format(mode)

        sqlpluslogincmd = self.get_sqlplus_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        sqlcmd = '''
                {0};
           '''.format(cmd)
        self.log_info_message(
            "Running the sqlplus command to start the database: " + sqlcmd, self.file_name)
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

    def check_substr_match(self, source_str, sub_str):
        """
         CHeck if substring exist 
        """
    #     self.log_info_message("Inside check_substr_match()",self.file_name)
        if (source_str.find(sub_str) != -1):
            return True
        else:
            return False

    def check_status_value(self, match):
        """
          return completed or notcompleted
        """
    #     self.log_info_message("Inside check_status_value()",self.file_name)
        if match:
            return 'completed'
        else:
            return 'notcompleted'

    def remove_file(self, fname):
        """
          Remove if file exist
        """
        self.log_info_message("Inside remove_file()", self.file_name)
        if os.path.exists(fname):
            os.remove(fname)

    def get_global_dbdomain(self, ohost, gdbname):
        """
        get the global dbname 
        """
        domain = self.get_host_domain()
        if domain:
            global_dbname = gdbname + domain
        else:
            global_dbname = gdbname

        return gdbname


########## Checking variable is set   ############


    def check_env_variable(self, key, eflag):
        """
        Check if env variable is set. If not exit if eflag is not set
        """
        # self.ora_env_dict=self.oenv.get_env_vars()
        if self.check_key(key, self.ora_env_dict):
            self.log_info_message("Env variable " + key +
                                  " is set. Check passed!", self.file_name)
        else:
            if eflag:
                self.log_error_message(
                    "Env variable " + key + " is not set " + ". Exiting...", self.file_name)
                self.prog_exit("127")
            else:
                self.log_warn_message("Env variable " + key + " is not set " +
                                      ".Ignoring the variable and procedding further..", self.file_name)

        return True

    def get_optype(self):
        """AI is creating summary for get_optype
          This function retruns the op_type based on nodes
        """
        racenvfile = self.get_envfile()
        if racenvfile:
            pass

    def get_envfiles(self):
        """
        Returns a list of RAC env files to read (original + writable)
        """
        envfiles = []

        # Original env file
        orig_file = "/etc/rac_env_vars/envfile"
        if os.path.isfile(orig_file):
            envfiles.append(orig_file)

        # Writable env file
        writable_file = "/etc/rac_env_vars_writable/envfile"
        if os.path.isfile(writable_file):
            envfiles.append(writable_file)

        return envfiles


    def populate_rac_env_vars(self, log_details=True):
        """
        Populate RAC env vars as key=value pairs from all env files
        """
        envfiles = self.get_envfiles()

        for racenvfile in envfiles:
            if os.path.isfile(racenvfile):
                with open(racenvfile) as fp:
                    for line in fp:
                        newstr = line.replace("export ", "").strip()
                        if log_details:
                            self.log_info_message(newstr + " newstr is populated: ", self.file_name)
                        parts = newstr.split("=")
                        if len(parts) >= 2:
                            key = parts[0]
                            # handle special cases with multiple '='
                            if key in ['DB_ASMDG_PROPERTIES', 'REDO_ASMDG_PROPERTIES', 'RECO_ASMDG_PROPERTIES'] and len(parts) >= 3:
                                value = '='.join(parts[1:])
                            else:
                                value = '='.join(parts[1:])

                            if not self.check_key(key, self.ora_env_dict):
                                self.ora_env_dict = self.add_key(key, value, self.ora_env_dict)
                                if log_details:
                                    self.log_info_message(key + " key is populated: " + self.ora_env_dict[key], self.file_name)
                            else:
                                if log_details:
                                    self.log_info_message(key + " key exists with value " + self.ora_env_dict[key], self.file_name)



########### Get the install Node #######


    def get_installnode(self):
        """AI is creating summary for get_installnode
         This function return the install node name
        Returns:
            string: returns the install node name
            string : return public host name
        """
        install_node = None
        pubhost = None

        if self.check_key("INSTALL_NODE", self.ora_env_dict):
            install_node = self.ora_env_dict["INSTALL_NODE"]
        else:
            pass

        pubhost = self.get_public_hostname()

        return install_node, pubhost

##########  Ping the IP ###############
    def ping_ip(self, ip, status):
        """
        Check if IP is pingable or not
        """
        cmd = '''ping -c 3 {0}'''.format(ip)
        output, error, retcode = self.execute_cmd(cmd, None, None)
        if status:
            self.check_os_err(output, error, retcode, True)
        else:
            self.check_os_err(output, error, retcode, None)

##########  Ping the IP ###############
    def ping_host(self, host):
        """
        Check if IP is pingable or not
        """
        cmd = '''ping -c 3 {0}'''.format(host)
        output, error, retcode = self.execute_cmd(cmd, None, None)
        return retcode

###########  IP Validations ############
    def validate_ip(self, ip):
        """
        validate the IP 
        """
        try:
            socket.inet_pton(socket.AF_INET, ip)
        except socket.error:  # not a valid address
            return False

        return True

######### Block Device Check #############
    def disk_exists(self, path):
        """
        Check if block device exist
        """
        try:
            if self.check_key("ASM_ON_NAS", self.ora_env_dict):
                if self.ora_env_dict["ASM_ON_NAS"] == 'True':
                    return stat.S_ISREG(os.stat(path).st_mode)
                else:
                    return False
            else:
                return stat.S_ISBLK(os.stat(path).st_mode)
        except:
            return False

######### Get Password ##############
    def get_os_password(self):
        """
        get the OS password
        """
        ospasswd = self.get_password(None)
        return ospasswd

    def get_asm_passwd(self):
        """
        get the ASM password
        """
        asmpasswd = self.get_password(None)
        return asmpasswd

    def get_db_passwd(self):
        """
        get the DB password
        """
        dbpasswd = self.get_password(None)
        return dbpasswd

    def get_tde_passwd(self):
        """
        get the tde password
        """
        tdepasswd = self.get_password("TDE_PASSWORD")
        return tdepasswd

    def get_sys_passwd(self):
        """
        get the sys user password
        """
        syspasswd = self.get_password(None)
        return syspasswd

    def _get_or_set_env_value(self, key, default_value):
        """
        Return env value for key; set to default and warn when missing.
        """
        if self.check_key(key, self.ora_env_dict):
            value = self.ora_env_dict[key]
            msg = '''{0} passed as an env variable and set to {1}'''.format(key, value)
            self.log_info_message(msg, self.file_name)
            return value

        self.ora_env_dict = self.add_key(key, default_value, self.ora_env_dict)
        value = self.ora_env_dict[key]
        msg = '''{0} not passed as an env variable. Setting default to {1}'''.format(key, value)
        self.log_warn_message(msg, self.file_name)
        return value

    def _get_or_set_env_from_other(self, key, source_key):
        """
        Return env value for key; default to source_key value when missing.
        """
        if self.check_key(key, self.ora_env_dict):
            value = self.ora_env_dict[key]
            msg = '''{0} passed as an env variable and set to {1}'''.format(key, value)
            self.log_info_message(msg, self.file_name)
            return value

        source_value = self.ora_env_dict[source_key]
        self.ora_env_dict = self.add_key(key, source_value, self.ora_env_dict)
        value = self.ora_env_dict[key]
        msg = '''{0} not passed as an env variable. Setting default to {1}'''.format(key, value)
        self.log_warn_message(msg, self.file_name)
        return value

    def get_password(self, key):
        """
        Return password resolved from secret files for DB/TDE flows.
        """
        if key == 'TDE_PASSWORD':
            svolume, pwdfile, pwdkey, passwdfile, keyvolume = self.get_tde_passwd_details()
        else:
            if key is not None:
                msg = '''Unsupported password key {0}. Falling back to DB password flow.'''.format(key)
                self.log_warn_message(msg, self.file_name)
            svolume, pwdfile, pwdkey, passwdfile, keyvolume = self.get_db_passwd_details()

        pwd_volume = self.ora_env_dict["PWD_VOLUME"] if self.check_key("PWD_VOLUME", self.ora_env_dict) else "/var/tmp"
        password = self.set_password(svolume, pwdfile, pwdkey, passwdfile, keyvolume, pwd_volume)
        return password

    def get_tde_passwd_details(self):
        """
        This function return the TDE parameters
        """
        tde_secret_volume = self._get_or_set_env_value("TDE_SECRET_VOLUME", "/run/.tdesecret")
        tde_key_secret_volume = self._get_or_set_env_from_other("TDE_KEY_SECRET_VOLUME", "TDE_SECRET_VOLUME")
        tde_pwd_file = self._get_or_set_env_value("TDE_PWD_FILE", "tde_pwdfile.enc")
        tde_pwd_key = self._get_or_set_env_value("TDE_PWD_KEY", "tdepwd.key")

        return tde_secret_volume, tde_pwd_file, tde_pwd_key, "tdepwdfile", tde_key_secret_volume

    def get_db_passwd_details(self):
        """
        This function return the db passwd paameters
        """
        secret_volume = self._get_or_set_env_value("SECRET_VOLUME", "/run/secrets")
        key_secret_volume = self._get_or_set_env_from_other("KEY_SECRET_VOLUME", "SECRET_VOLUME")
        db_pwd_file = self._get_or_set_env_value("DB_PWD_FILE", "common_os_pwdfile.enc")
        pwd_key = self._get_or_set_env_value("PWD_KEY", "pwd.key")
        password_file = self._get_or_set_env_value("PASSWORD_FILE", "dbpasswd.file")

        return secret_volume, db_pwd_file, pwd_key, password_file, key_secret_volume
    def set_password(self, secret_volume, passwd_file, key_file, dbpasswd_file, key_secret_volume, pwd_volume):
        """
        Resolve ORACLE password from encrypted secret files, or generate one when missing.
        """
        passwd_file_flag = False
        password = None
        password_file = None
        passwordfile1 = '''{0}/{1}'''.format(secret_volume, passwd_file)
        passwordkeyfile = '''{0}/{1}'''.format(secret_volume, key_file)
        passwordfile2 = '''{0}/{1}'''.format(secret_volume, dbpasswd_file)
        self.log_info_message(
            "Secret volume file set to : " + secret_volume, self.file_name)
        self.log_info_message("Password file set to : " +
                              passwd_file, self.file_name)
        self.log_info_message("key file set to : " + key_file, self.file_name)
        self.log_info_message("dbpasswd file set to : " +
                              dbpasswd_file, self.file_name)
        self.log_info_message("key secret volume set to : " +
                              key_secret_volume, self.file_name)
        self.log_info_message("pwd volume set : " + pwd_volume, self.file_name)
        self.log_info_message("passwordfile1 set to : " +
                              passwordfile1, self.file_name)
        self.log_info_message("passwordkeyfile set to : " +
                              passwordkeyfile, self.file_name)
        self.log_info_message("passwordfile2 set to : " +
                              passwordfile2, self.file_name)
        if (os.path.isfile(passwordfile1)) and (os.path.isfile(passwordkeyfile)):
            msg = '''Passwd file {0} and key file {1} exist. Password file Check passed!'''.format(
                passwordfile1, passwordkeyfile)
            self.log_info_message(msg, self.file_name)
            msg = '''Reading encrypted passwd from file {0}.'''.format(
                passwordfile1)
            self.log_info_message(msg, self.file_name)
            cmd = None
            if self.check_key("ENCRYPTION_TYPE", self.ora_env_dict):
                if self.ora_env_dict["ENCRYPTION_TYPE"].lower() == "aes256":
                    cmd = '''openssl enc -d -aes-256-cbc -in \"{0}/{1}\" -out {2}/{1} -pass file:\"{3}/{4}\"'''.format(
                        secret_volume, passwd_file, pwd_volume, key_secret_volume, key_file)
                elif self.ora_env_dict["ENCRYPTION_TYPE"].lower() == "rsautl":
                    cmd = '''openssl rsautl -decrypt -in \"{0}/{1}\" -out {2}/{1} -inkey \"{3}/{4}\"'''.format(
                        secret_volume, passwd_file, pwd_volume, key_secret_volume, key_file)
                else:
                    pass
            else:
                cmd = '''openssl pkeyutl -decrypt -in \"{0}/{1}\" -out {2}/{1} -inkey \"{3}/{4}\"'''.format(
                    secret_volume, passwd_file, pwd_volume, key_secret_volume, key_file)

            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
            passwd_file_flag = True
            password_file = '''{0}/{1}'''.format(pwd_volume, passwd_file)
        elif os.path.isfile(passwordfile2):
            msg = '''Passwd file {0} exist. Password file Check passed!'''.format(
                dbpasswd_file)
            self.log_info_message(msg, self.file_name)
            msg = '''Reading encrypted passwd from file {0}.'''.format(
                dbpasswd_file)
            self.log_info_message(msg, self.file_name)
            cmd = '''openssl base64 -d -in \"{0}\" -out \"{2}/{1}\"'''.format(
                passwordfile2, dbpasswd_file, pwd_volume)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
            passwd_file_flag = True
            password_file = '''{1}/{0}'''.format(dbpasswd_file, pwd_volume)

        if not passwd_file_flag:
            # get random password pf length 8 with letters, digits, and symbols
            characters1 = string.ascii_letters + string.digits + "_-%#"
            str1 = ''.join(random.choice(string.ascii_uppercase)
                           for i in range(4))
            str2 = ''.join(random.choice(characters1) for i in range(8))
            password = str1+str2
        else:
            fname = '''{0}'''.format(password_file)
            fdata = self.read_file(fname)
            password = fdata
            self.remove_file(password_file)

        if self.check_key("ORACLE_PWD", self.ora_env_dict):
            msg = "ORACLE_PWD is passed as an env variable. Check Passed!"
            self.log_info_message(msg, self.file_name)
        else:
            # self.ora_env_dict=self.add_key("ORACLE_PWD",password,self.ora_env_dict)
            msg = "ORACLE_PWD set to HIDDEN_STRING generated using encrypted password file"
            self.log_info_message(msg, self.file_name)

        return password

######### Get OS Password ##############
    def reset_os_password(self, user):
        """
        reset the OS password
        """
        self.log_info_message(
            '''Resetting OS user {0} password'''.format(user), self.file_name)
        # proc = subprocess.Popen(['/usr/bin/passwd', user, '--stdin'])
        # proc.communicate(passwd)
        ospasswd = self.get_os_password()
        self.set_mask_str(ospasswd)
        cmd = '''usermod --password $(openssl passwd -1 {1}) {0}'''.format(
            user, 'HIDDEN_STRING')
        # cmd='''bash -c \"echo -e '{1}\\n{1}' | passwd {0}\"'''.format(user,passwd)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
        self.unset_mask_str()

######### Copy the file to remote machine ############
    def scpfile(self, node, srcfile, destfile, user):
        """
        copy file to remot machine
        """
        cmd = '''su - {0} -c "scp {2} {0}@{1}:{3}"'''.format(
            user, node, srcfile, destfile)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### Copy file across cluster #########
    def copy_file_cluster(self, srcfile, destfile, user):
        """
        copy file on all the machines of the cluster
        """
        cluster_nodes = self.get_cluster_nodes()
        for node in cluster_nodes.split(" "):
            self.scpfile(node, srcfile, destfile, user)

######### Get the existing Cluster Nodes ##############
    def get_existing_clu_nodes(self, eflag):
        """
        Checking existing Cluster nodes and returning cluster nodes
        """
        cluster_nodes = None
        self.log_info_message(
            "Checking existing CRS nodes and returning cluster nodes", self.file_name)
        if self.check_key("EXISTING_CLS_NODE", self.ora_env_dict):
            return self.ora_env_dict["EXISTING_CLS_NODE"]
        else:
            if eflag:
                self.log_error_message(
                    '''Existing CLS nodes are not set. Exiting...''', self.file_name)
                self.prog_exit("127")
            else:
                self.log_warn_message(
                    '''Existing CLS nodes are not set.''', self.file_name)
        return cluster_nodes


######### Return the existing Cluster Nodes using oldnodes ##############


    def get_existing_cls_nodes(self, hostname, sshnode):
        """
        Checking existing Cluster nodes using clsnodes
        """
        giuser, gihome, gibase, oinv = self.get_gi_params()
        cluster_nodes = None
        cmd = '''su - {0} -c "ssh {2} '{1}/bin/olsnodes'"'''.format(
            giuser, gihome, sshnode)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
        crs_nodes = ""
        if not hostname:
            hostname = ""

        crs_node_list = output.split("\n")
        for node in crs_node_list:
            if hostname != node:
                crs_nodes = crs_nodes + "," + node

        return crs_nodes.strip(",")


######### Get the Cluster Nodes ##############


    def get_cluster_nodes(self):
        """
        Checking Cluster nodes and returning cluster nodes
        """
        cluster_nodes = None
        self.log_info_message(
            "Checking CRS nodes and returning cluster nodes", self.file_name)
        if self.check_key("CRS_NODES", self.ora_env_dict):
            cluster_nodes, vip_nodes, priv_nodes = self.process_cluster_vars(
                "CRS_NODES")
        else:
            cluster_nodes = self.get_public_hostname()

        return cluster_nodes

####### Get the nwIfaces and network #######
    def get_nwifaces(self):
        """
        This function returns the oracle.install.crs.config.networkInterfaceList for prepare responsefile
        """
        nwlist = ""
        nwname = ""
        nwflag = None
        privnwlist = ""
        ipcidr = ""
        netmask = ""
        netmasklist = ""

        if self.detect_k8s_env():
            if self.check_key("NW_CIDR", self.ora_env_dict):
                ipcidr = self.get_cidr_info(self.ora_env_dict["NW_CIDR"])
                netmask = self.ora_env_dict["NW_CIDR"].split("/")[1]
                if ipcidr:
                    self.log_info_message(
                        "Getting network card name for CIDR: " + ipcidr, self.file_name)
                    nwname = self.get_nw_name(ipcidr)
            else:
                pubmask, pubsubnet, nwname = self.get_nwlist("public")
                ip_address = pubsubnet.split(".")
                ipcidr = ip_address[0] + "." + ip_address[1] + ".0.0"
                netmask_address = pubmask.split(".")
                netmask = netmask_address[0] + \
                    "." + netmask_address[1] + ".0.0"

            if self.check_key("CRS_GPC", self.ora_env_dict):
                pubmask, pubsubnet, pubnwname = self.get_nwlist("public")
                nwlist = '''{0}:{1}:6'''.format(pubnwname, pubsubnet)
            else:
                privnwlist, privnetmasklist = self.get_priv_nwlist()
                if nwname:
                    self.log_info_message(
                        "The network card: " + nwname + " for the ip: " + ipcidr, self.file_name)
                    nwlist = '''{0}:{1}:1,{2}'''.format(
                        nwname, ipcidr, privnwlist)
                    netmasklist = '''{0}:{1},{2}'''.format(
                        nwname, netmask, privnetmasklist)
                else:
                    self.log_error_message(
                        "Failed to get network card matching for the subnet:" + ipcidr, self.file_name)
                    self.prog_exit("127")
        elif self.check_key("SINGLE_NETWORK", self.ora_env_dict):
            pubmask, pubsubnet, pubnwname = self.get_nwlist("public")
            nwlist = '''{0}:{1}:1,{0}:{1}:5'''.format(pubnwname, pubsubnet)
        else:
            if self.check_key("CRS_GPC", self.ora_env_dict):
                pubmask, pubsubnet, pubnwname = self.get_nwlist("public")
                nwlist = '''{0}:{1}:6'''.format(pubnwname, pubsubnet)
            else:
                pubmask, pubsubnet, pubnwname = self.get_nwlist("public")
                privnwlist, privnetmasklist = self.get_priv_nwlist()
                nwlist = '''{0}:{1}:1,{2}'''.format(
                    pubnwname, pubsubnet, privnwlist)

        return nwlist, netmasklist

######   Get the Private nwlist #######################
    def get_priv_nwlist(self):
        """
        This function get the private nwlist
        """
        privnwlist = ""
        netmasklist = ""
        if self.check_key("PRIVATE_HOSTS", self.ora_env_dict):
            privmask, privsubnet, privnwname = self.get_nwlist("privatehost")
            privnwlist = '''{0}:{1}:5'''.format(privnwname, privsubnet)
            netmasklist = '''{0}:{1}'''.format(privnwname, privmask)
        else:
            if self.check_key("CRS_PRIVATE_IP1", self.ora_env_dict):
                privmask, privsubnet, privnwname = self.get_nwlist(
                    "privateip1")
                privnwlist = '''{0}:{1}:5'''.format(privnwname, privsubnet)
                netmasklist = '''{0}:{1}'''.format(privnwname, privmask)
            if self.check_key("CRS_PRIVATE_IP2", self.ora_env_dict):
                privmask, privsubnet, privnwname = self.get_nwlist(
                    "privateip2")
                privnwlist = '''{0},{1}:{2}:5'''.format(
                    privnwlist, privnwname, privsubnet)
                netmasklist = '''{0},{1}:{2}'''.format(
                    netmasklist, privnwname, privmask)

        return privnwlist, netmasklist

#######  Detect K8s Env ################################
    def detect_k8s_env(self):
        """
        This function detect the K8s env and return the True or False 
        """
        k8s_flag = None
        f = open("/proc/self/cgroup",  "r")
        if "/kubepods" in f.read():
            k8s_flag = True
        else:
            if self.check_file("/run/secrets/kubernetes.io/serviceaccount/token", "local", None, None):
                k8s_flag = True

        return k8s_flag
######## Process the nwlist and return netmask,net subnet and ne card name #######

    def get_nwlist(self, checktype):
        """
        This function returns the nwlist for prepare responsefile
        """
        nwlist = None
        nwflag = None
        nwname = None
        nmask = None
        nwsubnet = None
        domain = None
        ipaddr = ""

        if self.check_key("CRS_NODES", self.ora_env_dict):
            pub_nodes, vip_nodes, priv_nodes = self.process_cluster_vars(
                "CRS_NODES")
        if checktype == "privatehost":
            crs_nodes = priv_nodes.replace(" ", ",")
            nodelist = priv_nodes.split(" ")
            domain = self.ora_env_dict["PRIVATE_HOSTS_DOMAIN"] if self.check_key(
                "PRIVATE_HOSTS_DOMAIN", self.ora_env_dict) else self.get_host_domain()
        elif checktype == "privateip1":
            nodelist = self.ora_env_dict["CRS_PRIVATE_IP1"].split(",")
        elif checktype == "privateip2":
            nodelist = self.ora_env_dict["CRS_PRIVATE_IP2"].split(",")
        else:
            crs_nodes = pub_nodes.replace(" ", ",")
            nodelist = pub_nodes.split(" ")
            domain = self.ora_env_dict["PUBLIC_HOSTS_DOMAIN"] if self.check_key(
                "PUBLIC_HOSTS_DOMAIN", self.ora_env_dict) else self.get_host_domain()
        print(nodelist)
        for pubnode in nodelist:
            self.log_info_message(
                "Getting IP for the hostname: " + pubnode, self.file_name)
            if checktype == "privateip1":
                ipaddr = pubnode
            elif checktype == "privateip2":
                ipaddr = pubnode
            else:
                ipaddr = self.get_ip(pubnode, domain)

            if ipaddr:
                self.log_info_message(
                    "Getting network name for the IP: " + ipaddr, self.file_name)
                nwname = self.get_nw_name(ipaddr)
                if nwname:
                    self.log_info_message(
                        "The network card: " + nwname + " for the ip: " + ipaddr, self.file_name)
                    nmask = self.get_netmask_info(nwname)
                    nwsubnet = self.get_subnet_info(ipaddr, nmask)
                    nwflag = True
                    break
            else:
                self.log_error_message(
                    "Failed to get the IP address for public hostname: " + pubnode + ". Exiting...", self.file_name)
                self.prog_exit("127")

        if nmask and nwsubnet and nwname and nwflag:
            return nmask, nwsubnet, nwname
        else:
            self.log_error_message(
                "Failed to get the required details. Exiting...", self.file_name)
            self.prog_exit("127")

######## Get the CRS Nodes ##################
    def get_crsnodes(self):
        """
        This function returns the oracle.install.crs.config.clusterNodes for prepare responsefile
        """
        cluster_nodes = ""
        pub_nodes, vip_nodes, priv_nodes = self.process_cluster_vars(
            "CRS_NODES")
        if not self.check_key("CRS_GPC", self.ora_env_dict):
            for (pubnode, vipnode) in zip(pub_nodes.split(" "), vip_nodes.split(" ")):
                cluster_nodes += pubnode + ":" + vipnode + ":HUB" + ","
        else:
            cluster_nodes = self.get_public_hostname()

        return cluster_nodes.strip(',')

######## Process host variables ##############
    def process_cluster_vars(self, key):
        """
        This function process CRS_NODES and return public hosts, or VIP hosts or Priv Hosts or cluser string
        """
        pubhost = " "
        viphost = " "
        privhost = " "
        self.log_info_message("Inside process_cluster_vars()", self.file_name)
        if self.check_key("CRS_GPC", self.ora_env_dict):
            return self.get_public_hostname(), None, None
        else:
            cvar_str = self.ora_env_dict[key]
            for item in cvar_str.split(";"):
                self.log_info_message(
                    "Cluster Node Desc: " + item, self.file_name)
                cvar_dict = dict(item1.split(":") for item1 in item.split(","))
                for ckey in cvar_dict.keys():
                    #  self.log_info_message("key:" + ckey ,self.file_name)
                    #  self.log_info_message("Value:" + cvar_dict[ckey] ,self.file_name)
                    if ckey.replace('"', '') == 'pubhost':
                        pubhost += cvar_dict[ckey].replace('"', '') + " "
                    if ckey.replace('"', '') == 'viphost':
                        viphost += cvar_dict[ckey].replace('"', '') + " "
                    if ckey.replace('"', '') == 'privhost':
                        privhost += cvar_dict[ckey].replace('"', '') + " "
            self.log_info_message("Pubhosts:" + pubhost.strip() + " Pubhost count:" +
                                  str(len(pubhost.strip().split(" "))), self.file_name)
            self.log_info_message("Viphosts:" + viphost.strip() + "Viphost count:" +
                                  str(len(viphost.strip().split(" "))), self.file_name)
            if len(pubhost.strip().split(" ")) == len(viphost.strip().split(" ")):
                return pubhost.strip(), viphost.strip(), privhost.strip()
            else:
                self.log_error_message(
                    "Public hostname count is not matching:/Public hostname count is not matching with virtual hostname count. Exiting...", self.file_name)
                self.prog_exit("127")


######### Get the Public Hostname##############


    def get_public_hostname(self):
        """
        Return Public Hostname
        """
        return socket.gethostname()

######### Get the DOMAIN##############
    def get_host_domain(self):
        """
        Return host domain extracted from local FQDN.
        """
        return self.extract_domain()
######### extract domain #################

    def extract_domain(self):
        """
        Extract DNS domain portion from host FQDN.
        """
        domain = None
        fqdn = subprocess.check_output(['hostname', '-f']).decode().strip()
        self.log_info_message(
            '''Fully Qualified Domain Name (FQDN): {0} '''.format(fqdn), self.file_name)

        parts = fqdn.split('.', 1)
        if len(parts) < 2:
            self.log_error_message(
                "Error: FQDN does not contain a domain name.", self.file_name)
        else:
            domain = parts[1]
            self.log_info_message(
                '''Extracted Domain: {0} '''.format(domain), self.file_name)
        return domain
######### get the public IP ##############

    def get_ip(self, hostname, domain):
        """
        Return the Ip based on hostname
        """
        if not domain:
            domain = self.get_host_domain()
        return socket.gethostbyname(hostname + '.' + domain)

######### Get network card ##############
    def get_nw_name(self, ip):
        """
        Get the network card name based on IP 
        """
        self.log_info_message(
            '''Getting network card name based on IP: {0} '''.format(ip), self.file_name)
        cmd = '''ifconfig | awk '/{0}/ {{ print $1 }}'  RS="\n\n" | awk -F ":" '{{ print $1 }}' | head -1'''.format(
            ip)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
        return output.strip()

######### Get the netmask info ################
    def get_netmask_info(self, nwcard):
        """
        Get the network mask
        """
        self.log_info_message(
            '''Getting netmask'''.format(nwcard), self.file_name)
        cmd = """ifconfig {0} | awk '/netmask/ {{print $4}}'""".format(nwcard)
        output, error, retcode = self.execute_cmd(cmd, None, None)
        return output.strip()

######### Get network subnet info ##############
    def get_subnet_info(self, ip, netmask):
        """
        Get the network card name based on IP
        """
        self.log_info_message('''Getting network subnet info name based on IP {0} and netmask {1}'''.format(
            ip, netmask), self.file_name)
        cmd = """ipcalc -np {0} {1} | grep NETWORK | awk -F '=' '{{ print $2 }}'""".format(
            ip, netmask)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
        return output.strip()

######### Get CIDR portion info ##############
    def get_cidr_info(self, cidr):
        """
        Get the non zero portion of the CIDR
        """
        self.log_info_message(
            '''Checking if network card exist with matching network details {0}'''.format(cidr), self.file_name)
        iplist = cidr.split(".")
        ipcidr = ""
        for ipo in iplist:
            if ipo.startswith('0'):
                break
            else:
                ipcidr += ipo + "."

        str1 = ipcidr.strip()
        ipcidr = str1.strip(".")
        return ipcidr

########  Build the ASM device list #########
    def build_asm_device(self, key, reduntype):
        """
        Build the ASM device list
        """
        self.log_info_message('''Building ASM device list''', self.file_name)
        ASM_DISKGROUP_FG_DISKS = ""
        ASM_DISKGROUP_DISKS = ""
        asmdevlist = self.ora_env_dict[key].split(",")
        for disk1 in asmdevlist:
            disk = disk1.strip('"')
            if self.check_key("ASM_DISK_CLEANUP_FLAG", self.ora_env_dict):
                if self.ora_env_dict["ASM_DISK_CLEANUP_FLAG"] == "TRUE":
                    self.asm_disk_cleanup(disk)
            if reduntype == 'NORMAL':
                ASM_DISKGROUP_FG_DISKS += disk + ",,"
                ASM_DISKGROUP_DISKS += disk + ","
            elif reduntype == 'HIGH':
                ASM_DISKGROUP_FG_DISKS += disk + ",,"
                ASM_DISKGROUP_DISKS += disk + ","
            else:
                ASM_DISKGROUP_FG_DISKS += disk + ","
                ASM_DISKGROUP_DISKS += disk + ","

        if reduntype != 'NORMAL' and reduntype != 'HIGH':
            fdata = ASM_DISKGROUP_DISKS[:-1]
            ASM_DISKGROUP_DISKS = fdata

        return ASM_DISKGROUP_FG_DISKS, ASM_DISKGROUP_DISKS

########  Build the ASM device list #########
    def build_asm_discovery_str(self, key):
        """
        Build the ASM device list
        """
        asm_disk = None
        asmdisk = self.ora_env_dict[key].split(",")[0]
        asm_disk_dir = asmdisk.rsplit("/", 1)[0]
        asm_disk1 = asmdisk.rsplit("/", 1)[1]
        if len(asm_disk1) <= 3:
            asm_disk = asmdisk.rsplit("/", 1)[1][:(len(asm_disk1)-1)]
        else:
            asm_disk = asmdisk.rsplit("/", 1)[1][:(len(asm_disk1)-2)]

        disc_str = asm_disk_dir + '/' + asm_disk + '*'
        return disc_str

######## set the ASM device permission ###############
    def set_asmdisk_perm(self, key, eflag):
        """
        This function set the correct permissions for ASM Disks
        """
        if self.check_key(key, self.ora_env_dict):
            self.log_info_message(key + " variable is set", self.file_name)
            for device1 in self.ora_env_dict[key].split(','):
                device = device1.strip('"')
                if self.disk_exists(device):
                    msg = '''Changing device permission {0}'''.format(device)
                    self.log_info_message(msg, self.file_name)
                    oraversion = self.get_rsp_version("INSTALL", None)
                    version = oraversion.split(".", 1)[0].strip()
                    self.log_info_message("disk" + version, self.file_name)

                    if int(version) == 19 or int(version) == 21:
                        cmd = '''chmod 660 {0};chown grid:asmadmin {0}'''.format(
                            device)
                    else:
                        cmd = '''chmod 660 {0};chown grid:asmdba {0}'''.format(
                            device)

                    self.log_info_message(
                        "Executing command:" + cmd, self.file_name)
                    output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
                else:
                    self.log_error_message(
                        '''ASM device {0} is passed but disk does not exist. Exiting...'''.format(device), self.file_name)
                    self.prog_exit("None")
        else:
            if eflag:
                self.log_error_message(
                    key + " is not passed. Exiting...", self.file_name)
                self.prog_exit("None")

######## CLeanup the disks ###############
    def asm_disk_cleanup(self, disk):
        """
        This function cleanup the ASM Disks
        """
        cmd = '''dd if=/dev/zero of={0} bs=8k count=10000 '''.format(disk)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)


######## Get the GI Image  ###############


    def get_gi_params(self):
        """
        This function return the GI home 
        """
        gihome = self.ora_env_dict["GRID_HOME"]
        gibase = self.ora_env_dict["GRID_BASE"]
        giuser = self.ora_env_dict["GRID_USER"]
        oinv = self.ora_env_dict["INVENTORY"]

        return giuser, gihome, gibase, oinv

######## Get the TMPDIR ################
    def get_tmpdir(self):
        """
        This function returns the TMPDIR
        Returns:
            tmpdir: return tmpdir
        """
        return self.ora_env_dict["TMPDIR"] if self.check_key("TMPDIR", self.ora_env_dict) else "/var/tmp"

######## Get the DB Image  ###############
    def get_db_params(self):
        """
        This function return the DB home
        """
        dbhome = self.ora_env_dict["DB_HOME"]
        dbbase = self.ora_env_dict["DB_BASE"]
        dbuser = self.ora_env_dict["DB_USER"]
        oinv = self.ora_env_dict["INVENTORY"]

        return dbuser, dbhome, dbbase, oinv

######## Get the cmd  ###############
    def get_sw_cmd(self, key, rspfile, node, netmasklist):
        """
        This function returns the installation command.
        """
        cmd = ""
        giuser, gihome, gbase, oinv = self.get_gi_params()
        pwdparam = f'''oracle.install.asm.SYSASMPassword={"HIDDEN_STRING"} oracle.install.asm.monitorPassword={"HIDDEN_STRING"}'''
        copyflag = " -noCopy " if self.check_key(
            "COPY_GRID_SOFTWARE", self.ora_env_dict) else ""
        prereq = " -ignorePreReq " if self.check_key(
            "IGNORE_CRS_PREREQS", self.ora_env_dict) else " "
        prereqfailure = " -ignorePrereqFailure " if self.check_key(
            "IGNORE_CRS_PREREQS_FAILURE", self.ora_env_dict) else " "
        snic = "-J-Doracle.install.crs.allowSingleNIC=true" if self.check_key(
            "SINGLENIC", self.ora_env_dict) else ""

        if key == "INSTALL":
            runCmd = "gridSetup.sh"
            if self.check_key("DEBUG_MODE", self.ora_env_dict):
                runCmd += " -debug"

            self.log_info_message(f"runCmd set to : {runCmd}", self.file_name)

            if self.detect_k8s_env():
                oraversion = self.get_rsp_version("INSTALL", None)
                version = oraversion.split(".", 1)[0].strip()
                distid_env = ""
                if int(version) == 19:
                    distid_env = "export CV_ASSUME_DISTID=OL8; "
                if self.check_key("CRS_GPC", self.ora_env_dict):
                    if int(version) <= 21:
                        cmd = f'''su - {giuser} -c "{distid_env}{gihome}/{runCmd} -waitforcompletion {copyflag} -silent -responseFile {rspfile} {prereq} {prereqfailure}"'''
                    else:
                        cmd = f'''su - {giuser} -c "{distid_env}{gihome}/{runCmd} -waitforcompletion {copyflag} -silent -responseFile {rspfile} {pwdparam} {prereq} {prereqfailure}"'''
                else:
                    param1 = f'''oracle.install.crs.config.netmaskList={netmasklist}''' if netmasklist else \
                             '''oracle.install.crs.config.netmaskList=eth0:255.255.0.0,eth1:255.255.255.0,eth2:255.255.255.0'''
                    cmd = f'''su - {giuser} -c "{distid_env}{gihome}/{runCmd} -waitforcompletion {copyflag} -silent {snic} -responseFile {rspfile} {param1} {pwdparam} {prereq} {prereqfailure}"'''
            else:
                cmd = f'''su - {giuser} -c "{gihome}/{runCmd} -waitforcompletion {copyflag} -silent {snic} -responseFile {rspfile} {prereq} {prereqfailure} {pwdparam}"'''
        elif key == 'ADDNODE':
            status = self.check_home_inv(None, gihome, giuser)
            if status:
                copyflag = " -noCopy "
            else:
                copyflag = " "
            cmd = f'''su - {giuser} -c "ssh {node} '{gihome}/gridSetup.sh -silent -waitForCompletion {copyflag} {prereq} {prereqfailure} -responseFile {rspfile}'"'''
        else:
            cmd = ""
        return cmd

# Installing Grid Software on Individual nodes
    def crs_sw_install_on_node(self, giuser, copyflag, crs_nodes, oinv, gihome, gibase, osdba, osoper, osasm, version, node):
        """
        This function installs CRS software on each node and registers it with oraInventory
        """
        cmd = None
        prereq = " "
        apply_ru = ""
        apply_oneoff = ""
        distid_env = ""

        if self.check_key("IGNORE_CRS_PREREQS", self.ora_env_dict):
            prereq = " -ignorePreReq "

        # Determine Oracle version
        oraversion = self.get_rsp_version("INSTALL", None)
        version = oraversion.split(".", 1)[0].strip()

        self.log_info_message("disk" + version, self.file_name)
        self.opatch_apply(node)

        # Handle Oracle 19c (special case)
        if int(version) == 19:
            distid_env = "export CV_ASSUME_DISTID=OL8; "

        if self.check_key("APPLY_RU_LOCATION", self.ora_env_dict):
            self.log_info_message(
                "Oracle RU Patch deployment detected.", self.file_name)
            apply_ru = ''' -applyRU "{0}" '''.format(
                self.ora_env_dict["APPLY_RU_LOCATION"])

        if self.check_key("ONEOFF_FOLDER_NAME", self.ora_env_dict) and self.check_key("GRID_ONEOFF_IDS", self.ora_env_dict):
            grid_oneoff_ids = self.ora_env_dict["GRID_ONEOFF_IDS"]
            oneoff_ids_with_location = ""

            # Split by comma to get individual oneoff IDs
            for oneoff_id in grid_oneoff_ids.split(","):
                if oneoff_ids_with_location:
                    oneoff_ids_with_location += ","
                oneoff_ids_with_location += self.ora_env_dict["ONEOFF_FOLDER_NAME"] + \
                    "/" + oneoff_id.strip()

            apply_oneoff = ''' -applyOneOffs "{0}" '''.format(
                oneoff_ids_with_location)

        if int(version) < 23:
            rspdata = '''su - {0} -c "ssh {10} '{11}{1}/gridSetup.sh {12} {13} {14} -waitforcompletion {2} -silent
            oracle.install.option=CRS_SWONLY
            INVENTORY_LOCATION={4}
            ORACLE_HOME={5}
            ORACLE_BASE={6}
            oracle.install.asm.OSDBA={7}
            oracle.install.asm.OSOPER={8}
            oracle.install.asm.OSASM={9}'"'''.format(
                giuser, gihome, copyflag, crs_nodes, oinv, gihome, gibase,
                osdba, osoper, osasm, node,
                distid_env, prereq, apply_ru, apply_oneoff
            )

            cmd = rspdata.replace('\n', ' ')

        else:
            rspdata = '''su - {0} -c "ssh {10} '{11}{1}/gridSetup.sh -silent -setupHome
            -OSDBA {7}
            -OSOPER {8}
            -OSASM {9}
            -ORACLE_BASE {6}
            -INVENTORY_LOCATION {4}
            -clusterNodes {10}
            {12} {13} {2}'"'''.format(
                giuser, gihome, copyflag, crs_nodes, oinv, gihome, gibase,
                osdba, osoper, osasm, node,
                distid_env, apply_ru, apply_oneoff
            )

            cmd = rspdata.replace('\n', ' ')

        output, error, retcode = self.execute_cmd_checked(
            cmd, None, None, exit_on_error=None
        )
        self.check_crs_sw_install(output)

    def opatch_apply(self, node):
        """Apply OPatch on both GI and DB homes remotely via SSH."""
        today = datetime.date.today()

        # GI parameters
        giuser, gihome, gbase, oinv = self.get_gi_params()
        if self.check_key("OPATCH_ZIP_FILE", self.ora_env_dict):
            cmd1 = '''su - {2} -c "ssh {3} 'mv {0}/OPatch {0}/OPatch_{1}_old'"'''.format(
                gihome, today, giuser, node
            )
            cmd2 = '''su - {2} -c "ssh {3} 'unzip -q {0} -d {1}/'"'''.format(
                self.ora_env_dict["OPATCH_ZIP_FILE"], gihome, giuser, node
            )
            for cmd in (cmd1, cmd2):
                output, error, retcode = self.execute_cmd(cmd, None, True)
                self.check_os_err(output, error, retcode, True)

        # DB parameters
        dbuser, dbhome, dbase, oinv = self.get_db_params()
        if self.check_key("OPATCH_ZIP_FILE", self.ora_env_dict):
            cmd1 = '''su - {2} -c "ssh {3} 'mv {0}/OPatch {0}/OPatch_{1}_old'"'''.format(
                dbhome, today, dbuser, node
            )
            cmd2 = '''su - {2} -c "ssh {3} 'unzip -q {0} -d {1}/'"'''.format(
                self.ora_env_dict["OPATCH_ZIP_FILE"], dbhome, dbuser, node
            )
            for cmd in (cmd1, cmd2):
                output, error, retcode = self.execute_cmd(cmd, None, True)
                self.check_os_err(output, error, retcode, True)

    def check_crs_sw_install(self, swdata):
        """
        This function check the if the sw install went fine
        """
        if not self.check_substr_match(swdata, "root.sh"):
            self.log_error_message(
                "Grid software install failed. Exiting...", self.file_name)
            self.prog_exit("127")

    def run_orainstsh_local(self, giuser, node, oinv):
        """
        This function run the orainst after grid setup
        """
        cmd = '''su - {0}  -c "sudo {2}/orainstRoot.sh"'''.format(
            giuser, node, oinv)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

    def run_rootsh_local(self, gihome, giuser, node):
        """
        This function run the root.sh after grid setup
        """
        self.log_info_message(
            "Running root.sh on node " + node, self.file_name)
        cmd = '''su - {0}  -c "sudo {2}/root.sh"'''.format(
            giuser, node, gihome)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######## Get the  oraversion ###############
    def get_rsp_version(self, key, node):
        """
        This function return the oraVersion
        """
        cmd = ""
        giuser, gihome, gbase, oinv = self.get_gi_params()
        if key == "INSTALL":
            cmd = '''su - {0} -c "{1}/bin/oraversion -majorVersion"'''.format(
                giuser, gihome)
        elif key == 'ADDNODE':
            cmd = '''su - {0} -c "ssh {2} {1}/bin/oraversion -majorVersion"'''.format(
                giuser, gihome, node)
        else:
            pass

        vdata = ""
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if output.strip() == "12.2":
            vdata = "12.2.0"
        elif output.strip() == "21":
            vdata = "21.0.0"
        elif output.strip() == "23":
            vdata = "23.0.0"
        elif output.strip() == "26":
            vdata = "26.0.0"
        elif output.strip() == "19":
            vdata = "19.0.0"
        elif output.strip() == "18":
            vdata = "18.0.0"
        else:
            self.log_error_message(
                "The SW major version is not matching {12.2|18.3|19.3|21.3|23|26}. Exiting...", self.file_name)
            self.prog_exit("None")

        return vdata

######### Check if GI is already installed on this machine ###########
    def check_gi_installed(self, retcode1, gihome, giuser, node, oinv):
        """
        Check if the Gi is installed on this machine
        """
        if retcode1 == 0:
            if os.path.isdir("/etc/oracle"):
                bstr = "Grid is already installed on this machine and /etc/oracle also exist. Skipping Grid setup.."
                self.log_info_message(self.print_banner(bstr), self.file_name)
                return True
            else:
                dir = os.listdir(gihome)
                if len(dir) != 0:
                    status = self.check_home_inv(None, gihome, giuser)
                    if status:
                        status = self.restore_gi_files(gihome, giuser)
                        if not status:
                            return False
                        else:
                            self.run_orainstsh_local(giuser, node, oinv)
                            if self.check_key("CRS_GPC", self.ora_env_dict):
                                return True
                            else:
                                status = self.start_crs(gihome, giuser)
                                if status:
                                    return True
                                else:
                                    return False
                else:
                    bstr = "Grid is not configured on this machine and /etc/oracle does not exist."
                    self.log_info_message(
                        self.print_banner(bstr), self.file_name)
                    return False
        else:
            self.log_info_message(
                "Grid is not installed on this machine. Proceeding further...", self.file_name)
            return False

    def restore_gi_files(self, gihome, giuser):
        """
        Restore GI-related OS files (/etc/oracle).
        Start CRS/HAS ONLY if restore was performed.
        Returns True on success, False on failure.
        """

        giuser, gihome, gibase, oinv = self.get_gi_params()
        srcdir = "{0}/.etcoraclebackup".format(gibase)

        oraversion = self.get_rsp_version("INSTALL", None)
        version = oraversion.split(".", 1)[0].strip()

        self.log_info_message(
            "restore_gi_files invoked (Oracle major version: {0})".format(version),
            self.file_name
        )

        restored = False

        # --------------------------------------------------
        # 1. Restore /etc/oracle if backup exists
        # --------------------------------------------------
        if os.path.isdir(srcdir) and os.listdir(srcdir):
            self.log_info_message(
                "Found /etc/oracle backup at {0}, restoring".format(srcdir),
                self.file_name
            )

            cmd = "cp -rp {0}/oracle /etc/".format(srcdir)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

            if retcode != 0:
                self.log_error_message(
                    "Failed to restore /etc/oracle from backup",
                    self.file_name
                )
                return False

            restored = True
        else:
            self.log_info_message(
                "No /etc/oracle backup found; skipping restore",
                self.file_name
            )

        # --------------------------------------------------
        # 2. Update OS files (always)
        # --------------------------------------------------
        if self.check_key("CRS_GPC", self.ora_env_dict):
            self.log_info_message(
                "CRS_GPC set: updating OS files using roothas.pl",
                self.file_name
            )

            cmd = (
                "export ORACLE_HOME={0} && "
                "{0}/perl/bin/perl "
                "-I{0}/perl/lib "
                "-I{0}/crs/install "
                "-I{0}/xag "
                "{0}/crs/install/roothas.pl -updateosfiles"
            ).format(gihome)
        else:
            self.log_info_message(
                "CRS_GPC not set: updating OS files using rootcrs.sh",
                self.file_name
            )
            cmd = "{0}/crs/install/rootcrs.sh -updateosfiles".format(gihome)

        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

        if retcode != 0:
            self.log_error_message(
                "OS file update failed",
                self.file_name
            )
            return False

        # --------------------------------------------------
        # 3. Start Oracle stack ONLY if restore happened
        # --------------------------------------------------
        if not restored:
            self.log_info_message(
                "GI files not restored; skipping CRS/HAS startup",
                self.file_name
            )
            return True

        if self.check_key("CRS_GPC", self.ora_env_dict):
            self.log_info_message(
                "Starting Oracle Restart stack (HAS)",
                self.file_name
            )
            status = self.start_has(gihome, giuser)
        else:
            self.log_info_message(
                "Starting Oracle Clusterware (CRS)",
                self.file_name
            )
            status = self.start_crs(gihome, giuser)

        if not status:
            self.log_error_message(
                "Failed to start Oracle stack after GI restore",
                self.file_name
            )
            return False

        self.log_info_message(
            "GI restore completed and Oracle stack started successfully",
            self.file_name
        )
        return True


######  Starting Crs ###############
    def start_crs(self, gihome, giuser):
        """
        starting CRS
        """
        cmd = '''{1}/bin/crsctl start crs'''.format(giuser, gihome)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if retcode == 0:
            return True
        else:
            return False

######  Starting Has ###############
    def start_has(self, gihome, giuser):
        """
        starting HAS
        """
        cmd = '''{1}/bin/crsctl start has'''.format(giuser, gihome)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if retcode == 0:
            return True
        else:
            return False

######### Check if GI is already installed on this machine ###########
    def check_rac_installed(self, retcode1):
        """
        Check if the RAC is installed on this machine
        """
        if retcode1 == 0:
            bstr = "RAC HOME is already installed on this machine!"
            self.log_info_message(self.print_banner(bstr), self.file_name)
            return True
        else:
            self.log_info_message(
                "Oracle RAC home is not installed on this machine. Proceeding further...", self.file_name)
            return False


######## Print the banner  ###############

    def print_banner(self, btext):
        """
        print the banner
        """
        strlen = len(btext)
        sep = '='
        sepchar = sep * strlen
        banner_text = '''
          {0}
          {1}
          {0}
          '''.format(sepchar, btext)
        return banner_text

######### Sqlplus connect string  ###########
    def get_sqlplus_str(self, home, osid, osuser, dbuser, password, hostname, port, svc, osep, role, wallet):
        """
        return the sqlplus connect string
        """
        path, ldpath = self._oracle_env_paths(home)
        export_cmd = '''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2};export ORACLE_SID={3}'''.format(
            home, path, ldpath, osid)
        if dbuser == 'sys' and password and hostname and port and svc:
            return '''su - {7} -c "{5};{6}/bin/sqlplus -S {0}/{1}@//{2}:{3}/{4} as sysdba"'''.format(dbuser, password, hostname, port, svc, export_cmd, home, osuser)
        elif dbuser != 'sys' and password and hostname and svc:
            return '''su - {7} -c "{5};{6}/bin/sqlplus -S {0}/{1}@//{2}:{3}/{4}"'''.format(dbuser, password, hostname, "1521", svc, export_cmd, home, osuser)
        elif dbuser and osep:
            return dbuser
        elif dbuser == 'sys' and not password:
            return '''su - {2} -c "{1};{0}/bin/sqlplus -S '/ as sysdba'"'''.format(home, export_cmd, osuser)
        elif dbuser == 'sys' and password:
            return '''su - {4} -c "{1};{0}/bin/sqlplus -S {2}/{3} as sysdba"'''.format(home, export_cmd, dbuser, password, osuser)
        elif dbuser != 'sys' and password:
            return '''su - {4} -c "{1};{0}/bin/sqlplus -S {2}/{3}"'''.format(home, export_cmd, dbuser, password, osuser)
        else:
            self.log_info_message(
                "At least specify db user and password for db connectivity. Exiting...", self.file_name)
            self.prog_exit("127")

######### RMAN connect string  ###########
    def get_rman_str(self, home, osid, osuser, dbuser, password, hostname, port, svc, osep, role, wallet):
        """
        return the rman connect string
        """
        path, ldpath = self._oracle_env_paths(home)
        export_cmd = '''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2};export ORACLE_SID={3}'''.format(
            home, path, ldpath, osid)
        if dbuser == 'sys' and password and hostname and port and svc:
            return '''su - {7} -c "{5};{6}/bin/rman {0}/{1}@//{2}:{3}/{4}"'''.format(dbuser, password, hostname, port, svc, export_cmd, home, osuser)
        elif dbuser != 'sys' and password and hostname and svc:
            return '''su - {7} -c "{5};{6}/bin/rman {0}/{1}@//{2}:{3}/{4}"'''.format(dbuser, password, hostname, "1521", svc, export_cmd, home, osuser)
        elif dbuser == 'sys' and not password:
            return '''su - {2} -c "{1};{0}/bin/rman target /"'''.format(home, export_cmd, osuser)
        elif dbuser == 'sys' and password:
            return '''su - {4} -c "{1};{0}/bin/rman target {2}/{3}"'''.format(home, export_cmd, dbuser, password, osuser)
        elif dbuser != 'sys' and password:
            return '''su - {4} -c "{1};{0}/bin/rman target {2}/{3}"'''.format(home, export_cmd, dbuser, password, osuser)
        else:
            self.log_info_message(
                "At least specify db user and password for db connectivity. Exiting...", self.file_name)
            self.prog_exit("127")

######### dgmgrl connect string  ###########
    def get_dgmgr_str(self, home, osid, osuser, dbuser, password, hostname, port, svc, osep, role, wallet):
        """
        return the dgmgrl connect string
        """
        path, ldpath = self._oracle_env_paths(home)
        if role is None:
            role = 'sysdg'

        export_cmd = '''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2};export ORACLE_SID={3}'''.format(
            home, path, ldpath, osid)
        if dbuser == 'sys' and password and hostname and port and svc:
            return '''su - {7} -c "{5};{6}/bin/dgmgrl {0}/{1}@//{2}:{3}/{4} as {8}"'''.format(dbuser, password, hostname, port, svc, export_cmd, home, osuser, role)
        elif dbuser != 'sys' and password and hostname and svc:
            return '''su - {7} -c "{5};{6}/bin/dgmgrl {0}/{1}@//{2}:{3}/{4} as {8}"'''.format(dbuser, password, hostname, "1521", svc, export_cmd, home, osuser, role)
        elif dbuser and osep:
            return dbuser
        elif dbuser == 'sys' and not password:
            return '''su - {2} -c "{1};{0}/bin/dgmgrl /"'''.format(home, export_cmd, osuser)
        elif dbuser == 'sys' and password:
            return '''su - {4} -c "{1};{0}/bin/dgmgrl {2}/{3} as {5}"'''.format(home, export_cmd, dbuser, password, osuser, role)
        elif dbuser != 'sys' and password:
            return '''su - {4} -c "{1};{0}/bin/dgmgrl {2}/{3}"'''.format(home, export_cmd, dbuser, password, osuser)
        else:
            self.log_info_message(
                "At least specify db user and password for db connectivity. Exiting...", self.file_name)
            self.prog_exit("127")

######## function to get tnssvc str ######
    def get_tnssvc_str(self, dbsvc, dbport, dbscan):
        """
        return tnssvc
        """
        tnssvc = '''(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = {0})(PORT = {1})) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = {2})))'''.format(
            dbscan, dbport, dbsvc)
        return tnssvc

######### Sqlplus   ###########
    def get_inst_sid(self, dbuser, dbhome, osid, hostname):
        """
        return the sid
        """
        if self.check_key("CRS_GPC", self.ora_env_dict):
            return osid

        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {5} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl status database -d {3} | grep {4}"'''.format(
            dbhome, path, ldpath, osid, hostname, dbuser)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if len(output.split(" ")) > 1:
            inst_sid = output.split(" ")[1]
            return inst_sid
        else:
            return None

######### Stop RAC DB ########
    def stop_rac_db(self, dbuser, dbhome, osid, hostname):
        """
        stop the Database 
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {5} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl stop database -d {3}"'''.format(
            dbhome, path, ldpath, osid, hostname, dbuser)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### Stop RAC DB ########
    def get_host_dbsid(self, hname, connect_str):
        """
        get the host sid based on hostname
        """
        if hname is None:
            cmd = '''select instance_name from gv$instance;'''
        else:
            cmd = """select instance_name from gv$instance where HOST_NAME='{0}';""".format(
                hname)
        sqlcmd = '''
         set heading off;
         set pagesize 0; 
         {0}
         exit;
         '''.format(cmd)
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(connect_str, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        return output.strip()


######### Get SVC Domain ########

    def get_svc_domain(self, hname):
        """
        get the host domain baded on service name
        """
        svc_dom = None
        cmd = '''nslookup {0}'''.format(hname)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        for line in output.split('\n'):
            if "Name:" in line:
                svc_dom = line.split(':')[1].strip()
        return svc_dom

######### Stop RAC DB ########
    def start_rac_db(self, dbuser, dbhome, osid, node=None, startoption=None):
        """
        Start the Database
        """
        path, ldpath = self._oracle_env_paths(dbhome)

        if node is None:
            nodename = ""
        else:
            nodename = node

        if startoption is None:
            startflag = ""
        else:
            startflag = ''' -o {0}'''.format(startoption)

        cmd = '''su - {5} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl start database -d {3} {6}"'''.format(
            dbhome, path, ldpath, osid, nodename, dbuser, startflag)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### DB-Status ###########
    def get_db_status(self, dbuser, dbhome, osid):
        """
        return the status of the database
        """
        path, ldpath = self._oracle_env_paths(dbhome)

        cmd = '''su - {4} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl status database -d {3}"'''.format(
            dbhome, path, ldpath, osid, dbuser)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

    def get_dbinst_status(self, dbuser, dbhome, inst_sid, sqlpluslogincmd):
        """
        return the status of the local dbinstance
        """
        sqlcmd = '''
          set heading off;
          set pagesize 0;
          select status from v$instance;
          exit;
         '''
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        return output

##### DB-Config ######
    def get_db_config(self, dbuser, dbhome, osid):
        """
        return the db-config
        """
        path, ldpath = self._oracle_env_paths(dbhome)

        cmd = '''su - {4} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl config database -d {3}"'''.format(
            dbhome, path, ldpath, osid, dbuser)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

##### Get service name #####
##### Get service name #####
    def _get_service_env_keys(self):
        """
        Return environment keys that match RAC DB service definitions.
        """
        reg_exp = self.service_regex()
        return [key for key in self.ora_env_dict.keys() if reg_exp.match(key)]

    def _parse_service_vars(self, key):
        """
        Parse service variable string from env into a dictionary.
        """
        cvar_str = self.ora_env_dict[key]
        cvar_dict = {}
        for item in cvar_str.split(";"):
            if item == "":
                continue
            if ":" not in item:
                msg = '''RAC service params {0} is not set correctly. Invalid token {1}'''.format(key, item)
                self.log_error_message(msg, self.file_name)
                self.prog_exit("Error occurred")
            k, v = item.split(":", 1)
            cvar_dict[k] = v
        return cvar_dict

    def get_service_name(self):
        """
        This function get the service_name.
        """
        self.log_info_message("Inside get_service_name()", self.file_name)
        service_name = None
        osid = None
        opdb = None
        sparams = None

        for key in self._get_service_env_keys():
            service_name, osid, opdb, uniformflag, sparams = self.process_service_vars(key, None)

        return service_name, osid, opdb, sparams

##### Setup DB Service ######
    def setup_db_service(self, type):
        """
        This function setup the Oracle RAC database service.
        """
        self.log_info_message("Inside setup_db_service()", self.file_name)
        op_type = (type or "create").lower()

        for key in self._get_service_env_keys():
            service_name, osid, opdb, uniformflag, sparams = self.process_service_vars(key, op_type)
            rac_service_exist = self.check_db_service_exist(service_name, osid)

            if not rac_service_exist:
                if op_type == "create":
                    self.create_db_service(service_name, osid, opdb, sparams)
            elif op_type == "modify" and uniformflag is not True:
                self.modify_db_service(service_name, osid, opdb, sparams)

            rac_service_exist = self.check_db_service_exist(service_name, osid)
            if rac_service_exist:
                msg = '''RAC db service exist'''
            else:
                msg = '''RAC db service does not exist or creation failed'''
            self.log_info_message(msg, self.file_name)

##### Process DB Service ######
    def process_service_vars(self, key, type):
        """
        This function process the service parameters for RAC service creation.
        """
        service = None
        preferred = None
        pdb = None
        db = None
        uniformflag = None
        sparam_parts = []

        op_type = type.lower() if type is not None else "create"
        self.log_info_message("Inside process_service_vars()", self.file_name)

        cvar_dict = self._parse_service_vars(key)
        for ckey, cvalue in cvar_dict.items():
            if ckey == 'service':
                service = cvalue
                sparam_parts.append("-service " + service)
                continue

            if ckey == 'preferred':
                if not self.ora_env_dict.get("CRS_GPC"):
                    preferred = cvalue
                    if op_type == 'modify':
                        sparam_parts.append("-modifyconfig -preferred " + preferred)
                    else:
                        sparam_parts.append("-preferred " + preferred)
                continue

            if ckey == 'available':
                sparam_parts.append("-available " + cvalue)
                continue

            if op_type == 'modify':
                continue

            if ckey == 'role':
                sparam_parts.append("-role " + cvalue)
            elif ckey == 'cardinality':
                sparam_parts.append("-cardinality " + cvalue)
                uniformflag = True
            elif ckey == 'policy':
                sparam_parts.append("-policy " + cvalue)
            elif ckey == 'tafpolicy':
                sparam_parts.append("-tafpolicy " + cvalue)
            elif ckey == 'resetstate':
                sparam_parts.append("-resetstate " + cvalue)
            elif ckey == 'failovertype':
                sparam_parts.append("-failovertype " + cvalue)
            elif ckey == 'failoverdelay':
                sparam_parts.append("-failoverdelay " + cvalue)
            elif ckey == 'failoverretry':
                sparam_parts.append("-failoverretry " + cvalue)
            elif ckey == 'failback':
                sparam_parts.append("-failback " + cvalue)
            elif ckey == 'failover_restore':
                sparam_parts.append("-failover_restore " + cvalue)
            elif ckey == 'pdb':
                pdb = cvalue
            elif ckey == 'clbgoal':
                sparam_parts.append("-clbgoal " + cvalue)
            elif ckey == 'rlbgoal':
                sparam_parts.append("-rlbgoal " + cvalue)
            elif ckey == 'dtp':
                sparam_parts.append("-dtp " + cvalue)
            elif ckey == 'notification':
                sparam_parts.append("-notification " + cvalue)
            elif ckey == 'commit_outcome':
                sparam_parts.append("-commit_outcome " + cvalue)
            elif ckey == 'commit_outcome_fastpath':
                sparam_parts.append("-commit_outcome_fastpath " + cvalue)
            elif ckey == 'replay_init_time':
                sparam_parts.append("-replay_init_time " + cvalue)
            elif ckey == 'session_state':
                sparam_parts.append("-session_state " + cvalue)
            elif ckey == 'drain_timeout':
                sparam_parts.append("-drain_timeout " + cvalue)
            elif ckey == 'db':
                db = cvalue
                sparam_parts.append("-db " + db)

        if uniformflag is not True:
            if pdb is None:
                pdb = self.ora_env_dict["ORACLE_PDB_NAME"] if self.check_key("ORACLE_PDB_NAME", self.ora_env_dict) else "ORCLPDB"
            sparam_parts.append("-pdb " + pdb)
        else:
            pdb = self.ora_env_dict["ORACLE_PDB_NAME"] if self.check_key("ORACLE_PDB_NAME", self.ora_env_dict) else "ORCLPDB"

        if preferred is None and not self.ora_env_dict.get("CRS_GPC"):
            osuser, dbhome, dbbase, oinv = self.get_db_params()
            dbname, osid, dbuname = self.getdbnameinfo()
            hostname = self.get_public_hostname()
            inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)
            connect_str = self.get_sqlplus_str(dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
            dbsid = self.get_host_dbsid(None, connect_str)
            preferred = ",".join(dbsid.splitlines())
            if op_type == 'modify':
                sparam_parts.append("-modifyconfig -preferred " + preferred)
            else:
                sparam_parts.append("-preferred " + preferred)

        if db is None:
            db = self.ora_env_dict["DB_NAME"] if self.check_key("DB_NAME", self.ora_env_dict) else "ORCLCDB"
            sparam_parts.append("-db " + db)

        if service and db and pdb:
            sparam = " " + " ".join(sparam_parts) if sparam_parts else ""
            return service, db, pdb, uniformflag, sparam

        msg1 = '''service={0},pdb={1},db={2}'''.format((service or "Missing Value"), (pdb or "Missing Value"), (db or "Missing Value"))
        msg = '''RAC service params {0} is not set correctly. One or more value is missing {1}'''.format(key, msg1)
        self.log_error_message(msg, self.file_name)
        self.prog_exit("Error occurred")

####  Process Service Regex  ####
    def service_regex(self):
        """
          This function return the rgex to search the DB_SERVICE
        """
        self.log_info_message("Inside service_regex()", self.file_name)
        return re.compile('DB_SERVICE')


    def _build_db_srvctl_service_cmd(self, dbuser, dbhome, opdb, action, service_name=None, sparams=None):
        """
        Build srvctl command for database service operations.
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        if sparams is not None:
            return '''su - {4} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl {5} service {6}"'''.format(
                dbhome, path, ldpath, opdb, dbuser, action, sparams)

        return '''su - {4} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl {5} service -db {3} -s {6}"'''.format(
            dbhome, path, ldpath, opdb, dbuser, action, service_name)

##### craete DB service ######
    def create_db_service(self, service_name, osid, opdb, sparams):
        """
        create database service
        """
        dbuser, dbhome, dbase, oinv = self.get_db_params()
        cmd = self._build_db_srvctl_service_cmd(dbuser, dbhome, opdb, "add", service_name=service_name, sparams=sparams)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

##### craete DB service ######
    def modify_db_service(self, service_name, osid, opdb, sparams):
        """
        modify database service
        """
        dbuser, dbhome, dbase, oinv = self.get_db_params()
        cmd = self._build_db_srvctl_service_cmd(dbuser, dbhome, opdb, "modify", service_name=service_name, sparams=sparams)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

##### check Db service ######
    def check_db_service_exist(self, service_name, osid):
        """
        check if db service exist
        """
        dbuser, dbhome, dbase, oinv = self.get_db_params()
        cmd = self._build_db_srvctl_service_cmd(dbuser, dbhome, osid, "status", service_name=service_name)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if "does not exist" in output.lower():
            return False
        return True

##### check service ######
    def check_db_service_status(self, service_name, osid):
        """
        check if db service is running
        """
        dbuser, dbhome, dbase, oinv = self.get_db_params()
        cmd = self._build_db_srvctl_service_cmd(dbuser, dbhome, osid, "status", service_name=service_name)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        msg = '''Service {0} is running on'''.format(service_name)
        if self.check_substr_match(output.lower(), msg.lower()):
            return True, output.lower()
        else:
            return False, output.lower()

##### check service ######
    def start_db_service(self, service_name, osid):
        """
        start the DB service
        """
        dbuser, dbhome, dbase, oinv = self.get_db_params()
        cmd = self._build_db_srvctl_service_cmd(dbuser, dbhome, osid, "start", service_name=service_name)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
######### Add RAC DB ########
    def add_rac_db(self, dbuser, dbhome, osid, spfile):
        """
        add the Database 
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {5} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl add database -d {3} -oraclehome {0} -dbtype RAC -spfile '{4}'"'''.format(
            dbhome, path, ldpath, osid, spfile, dbuser)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### Add RAC DB ########
    def add_rac_db_lsnr(self, dbuser, dbhome, osid, endpoints, lsnrname):
        """
        add the Database 
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {3} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl add listener -listener {4} -endpoints {5}; {0}/bin/srvctl start listener -listener {4}"'''.format(
            dbhome, path, ldpath, dbuser, lsnrname, endpoints)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### Add RAC DB ########
    def modify_rac_db_lsnr(self, dbuser, dbhome, osid, endpoints, lsnrname):
        """
        add the Database 
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {3} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl modify listener -listener {4} -endpoints {5}"'''.format(
            dbhome, path, ldpath, dbuser, lsnrname, endpoints)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### Add RAC DB ########
    def check_rac_db_lsnr(self, dbuser, dbhome, osid, endpoints, lsnrname):
        """
        add the Database 
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {3} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl status listener -listener {6}"'''.format(
            dbhome, path, ldpath, dbuser, lsnrname, endpoints, lsnrname)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        msg = '''Listener {0} is enabled'''.format(lsnrname)
        if self.check_substr_match(output.lower(), msg.lower()):
            return True
        else:
            return False

######### Add RAC DB ########
######### Add RAC DB ########
    def _build_remote_srvctl_cmd(self, user, node, home, srvctl_args, use_sudo=False):
        """
        Build remote srvctl command wrapped with ssh and Oracle env exports.
        """
        path, ldpath = self._oracle_env_paths(home)
        sudo_prefix = "sudo " if use_sudo else ""
        cmd = '''su - {0} -c "ssh {1} 'export ORACLE_HOME={2};export PATH={3};export LD_LIBRARY_PATH={4};{5}{2}/bin/srvctl {6}'"'''.format(
            user, node, home, path, ldpath, sudo_prefix, srvctl_args)
        return cmd

    def _get_remote_srvctl_status(self, user, node, home, status_target):
        """
        Return remote srvctl status output for a target resource.
        """
        status_cmd = self._build_remote_srvctl_cmd(
            user, node, home, "status {0}".format(status_target), use_sudo=False)
        output, error, retcode = self.execute_cmd_checked(
            status_cmd, None, None, exit_on_error=None)
        return output

    def _extract_scan_number(self, line, token_prefix):
        """
        Extract scan/scan-listener number from srvctl status line tokens.
        """
        parts = line.strip().split()
        if len(parts) < 3:
            return None
        token = parts[2]
        if not token.startswith(token_prefix):
            return None
        return token.replace(token_prefix, "", 1)

    def update_scan(self, user, home, endpoints, node):
        """
        Update Scan
        """
        scanname = self.ora_env_dict["SCAN_NAME"]
        cmd = self._build_remote_srvctl_cmd(
            user, node, home, "modify scan -scanname {0}".format(scanname), use_sudo=True)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

    def stop_scan(self, user, home, node):
        """
        Disable and stop only the SCAN VIP not running on the specified node.
        """
        output = self._get_remote_srvctl_status(user, node, home, "scan")

        for line in output.splitlines():
            if "SCAN VIP" in line and "is running" in line and node in line:
                scan_number = self._extract_scan_number(line, "scan")
                if scan_number:
                    stop_cmd = self._build_remote_srvctl_cmd(
                        user, node, home, "stop scan -scannumber {0}".format(scan_number), use_sudo=True)
                    out2, err2, code2 = self.execute_cmd_checked(stop_cmd, None, None, exit_on_error=None)

                    disable_cmd = self._build_remote_srvctl_cmd(
                        user, node, home, "disable scan -scannumber {0}".format(scan_number), use_sudo=True)
                    out1, err1, code1 = self.execute_cmd_checked(disable_cmd, None, None, exit_on_error=None)

    def start_scan(self, user, home, node):
        """
        Start only the SCAN VIP that is not running on the given node.
        """
        output = self._get_remote_srvctl_status(user, node, home, "scan")

        for line in output.splitlines():
            if "SCAN VIP" in line and "is not running" in line:
                scan_number = self._extract_scan_number(line, "scan")
                if scan_number:
                    start_cmd = self._build_remote_srvctl_cmd(
                        user, node, home, "start scan -scannumber {0}".format(scan_number), use_sudo=True)
                    out, err, code = self.execute_cmd_checked(start_cmd, None, None, exit_on_error=None)

    def start_scan_lsnr(self, user, home, node):
        """
        Start only the SCAN listener that is not running on the given node.
        """
        output = self._get_remote_srvctl_status(user, node, home, "scan_listener")

        for line in output.splitlines():
            if "is not running" in line and "SCAN listener" in line:
                lsnr_number = self._extract_scan_number(line, "LISTENER_SCAN")
                if lsnr_number:
                    start_cmd = self._build_remote_srvctl_cmd(
                        user, node, home, "start scan_listener -scannumber {0}".format(lsnr_number), use_sudo=False)
                    out, err, code = self.execute_cmd_checked(start_cmd, None, None, exit_on_error=None)

    def stop_scan_lsnr(self, user, home, node):
        """
        Disable and stop only the SCAN listener not running on the specified node.
        """
        output = self._get_remote_srvctl_status(user, node, home, "scan_listener")

        for line in output.splitlines():
            if "SCAN listener" in line and "is running" in line and node in line:
                lsnr_number = self._extract_scan_number(line, "LISTENER_SCAN")
                if lsnr_number:
                    stop_cmd = self._build_remote_srvctl_cmd(
                        user, node, home, "stop scan_listener -scannumber {0}".format(lsnr_number), use_sudo=True)
                    out2, err2, code2 = self.execute_cmd_checked(stop_cmd, None, None, exit_on_error=None)

                    disable_cmd = self._build_remote_srvctl_cmd(
                        user, node, home, "disable scan_listener -scannumber {0}".format(lsnr_number), use_sudo=True)
                    out1, err1, code1 = self.execute_cmd_checked(disable_cmd, None, None, exit_on_error=None)


######### Add RAC DB ########

    def update_scan_lsnr(self, user, home, node):
        """
        Update Scan
        """
        scanname = self.ora_env_dict["SCAN_NAME"]
        cmd = self._build_remote_srvctl_cmd(
            user, node, home, "modify scan_listener -update", use_sudo=False)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
######### Set DB Lsnr ########
    def setup_db_lsnr(self):
        """
        Create and Setup DB lsnr
        """
        giuser, gihome, gibase, oinv = self.get_gi_params()
        status, osid, host, mode = self.check_dbinst()
        endpoints = self.ora_env_dict["DB_LISTENER_ENDPOINTS"] if self.check_key(
            "DB_LISTENER_ENDPOINTS", self.ora_env_dict) else None
        lsnrname = self.ora_env_dict["DB_LISTENER_NAME"] if self.check_key(
            "DB_LISTENER_NAME", self.ora_env_dict) else "dblsnr"

        if status:
            if endpoints is not None and lsnrname is not None:
                status1 = self.check_rac_db_lsnr(
                    giuser, gihome, osid, endpoints, lsnrname)
                if not status1:
                    self.add_rac_db_lsnr(
                        giuser, gihome, osid, endpoints, lsnrname)
                else:
                    self.modify_rac_db_lsnr(
                        giuser, gihome, osid, endpoints, lsnrname)
        else:
            self.log_info_message("DB Instance is not up", self.file_name)

######### Add RACDB Instance ########
    def add_rac_instance(self, dbuser, dbhome, osid, instance_number, nodename):
        """
        add the RAC Database Instance
        """
        path, ldpath = self._oracle_env_paths(dbhome)
        cmd = '''su - {5} -c "export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl add instance -d {3} -i {4}  -node {6}"'''.format(
            dbhome, path, ldpath, osid, osid+instance_number, dbuser, nodename)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

######### get DB Role ########
    def get_db_role(self, dbuser, dbhome, inst_sid, sqlpluslogincmd):
        """
        return the  
        """
        sqlcmd = '''
          set heading off;
          set pagesize 0;
          select database_role from v$database;
          exit;
         '''
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        return output

######### Sqlplus   ###########
    def check_setup_status(self, dbuser, dbhome, inst_sid, sqlpluslogincmd):
        """
        return the RAC setup status. It check a status in the table.
        """
        fname = '''/tmp/{0}'''.format("rac_setup.txt")
        self.remove_file(fname)
        self.set_mask_str(self.get_sys_passwd())
        msg = '''Checking racsetup table in CDB'''
        self.log_info_message(msg, self.file_name)
        sqlcmd = '''
          set heading off
          set feedback off
          set  term off
          SET NEWPAGE NONE
          spool {0}
          select * from system.racsetup WHERE ROWNUM = 1;
          spool off
          exit;
         '''.format(fname)
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)

        if os.path.isfile(fname):
            fdata = self.read_file(fname)
        else:
            fdata = 'nosetup'

        # Unsetting the encrypt value to None
        self.unset_mask_str()

        if re.search('completed', fdata):
            # status = self.catalog_pdb_setup_check(host,ccdb,svc,port)
            # if status == 'completed':
            return 'completed'
            # else:
            #   return 'notcompleted'
        else:
            return 'notcompleted'

#### Get DB Parameters #######
    def get_init_params(self, paramname, sqlpluslogincmd):
        """
        return the
        """
        sqlcmd = '''
          set heading off;
          set pagesize 0;
          set feedback off
          select value from v$parameter where upper(name)=upper('{0}');
          exit;
         '''.format(paramname)

        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        return output.strip()

#### set DB Params #######
    def run_sql_cmd(self, sqlcmd, sqlpluslogincmd):
        """
        return the
        """
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(
            sqlpluslogincmd, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        return output

#### Set sqlcmd ########
    def get_sqlsetcmd(self):
        """
        return the sql set commands
        """
        sqlsetcmd = '''
           set heading off
           set pagesize 0
           set feedback off
         '''
        return sqlsetcmd

#### Check DB Inst #############
    def check_dbinst(self):
        """
        This function the db inst
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        dbname, osid, dbuname = self.getdbnameinfo()
        hostname = self.get_public_hostname()
        inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)

        connect_str = self.get_sqlplus_str(
            dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
        if inst_sid:
            status = self.get_dbinst_status(
                osuser, dbhome, inst_sid, connect_str)
            if not self.check_substr_match(status, "OPEN"):
                return False, inst_sid, hostname, status
            else:
                return True, inst_sid, hostname, status
        else:
            return False, inst_sid, hostname, ""

######## Set Remote Listener ######
    def set_remote_listener(self):
        """
        This function set the remote listener 
        """
        if self.check_key("CMAN_HOST", self.ora_env_dict):
            cmanhost = self.ora_env_dict["CMAN_HOST"]
            osuser, dbhome, dbbase, oinv = self.get_db_params()
            dbname, osid, dbuname = self.getdbnameinfo()
            scanname = self.ora_env_dict["SCAN_NAME"] if self.check_key(
                "SCAN_NAME", self.ora_env_dict) else self.prog_exit("127")
            scanport = self.ora_env_dict["SCAN_PORT"] if self.check_key(
                "SCAN_PORT", self.ora_env_dict) else "1521"
            cmanport = self.ora_env_dict["CMAN_PORT"] if self.check_key(
                "CMAN_PORT", self.ora_env_dict) else "1521"
            hostname = self.get_public_hostname()
            inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)
            connect_str = self.get_sqlplus_str(
                dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
            sqlcmd = '''
             set heading off;
             set pagesize 0; 
             alter system set remote_listener='{0}:{1},(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST={2})(PORT={3}))))'  scope=both;    
             alter system register;
             alter system register;
             exit;
            '''.format(scanname, scanport, cmanhost, cmanport)
            self.set_mask_str(self.get_sys_passwd())
            output, error, retcode = self.run_sqlplus(
                connect_str, sqlcmd, None)
            self.log_info_message(
                "Calling check_sql_err() to validate the sql command return status", self.file_name)
            self.check_sql_err(output, error, retcode, None)
            self.unset_mask_str()

######## Set Remote Listener ######
    def set_local_listener(self):
        """
        This function set the remote listener 
        """
        if self.check_key("LOCAL_LISTENER", self.ora_env_dict):
            lsnrstr = self.ora_env_dict["LOCAL_LISTENER"].split(";")
            for str1 in lsnrstr:
                if len(str1.split(":")) == 2:
                    hname = (str1.split(":")[0]).strip()
                    lport = (str1.split(":")[1]).strip()
                    osuser, dbhome, dbbase, oinv = self.get_db_params()
                    dbname, osid, dbuname = self.getdbnameinfo()
                    hostname = self.get_public_hostname()
                    inst_sid = self.get_inst_sid(
                        osuser, dbhome, osid, hostname)
                    connect_str = self.get_sqlplus_str(
                        dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
                    dbsid = self.get_host_dbsid(hname, connect_str)
                    svcdom = self.get_svc_domain(hname)
                    hname1 = svcdom
                    lstr = '''(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST={0})(PORT={1}))))'''.format(
                        hname1, lport)
                    dbsid1 = re.sub(r"[\n\t\s]*", "", dbsid)
                    self.log_info_message(
                        "the local_listener string set to : " + lstr, self.file_name)
                    sqlcmd = '''
                  set heading off;
                  set pagesize 0;
                  alter system set local_listener='{0}'  scope=both sid='{1}';
                  alter system register;
                  alter system register;
                  exit;
                  '''.format(lstr, dbsid1)
                    self.set_mask_str(self.get_sys_passwd())
                    output, error, retcode = self.run_sqlplus(
                        connect_str, sqlcmd, None)
                    self.log_info_message(
                        "Calling check_sql_err() to validate the sql command return status", self.file_name)
                    self.check_sql_err(output, error, retcode, None)
                    self.unset_mask_str()

# Perform DB Check
    def perform_db_check(self, type):
        """
        This function check the DB and print the message"
        """
        status, osid, host, mode = self.check_dbinst()
        if status:
            dbuser, dbhome, dbase, oinv = self.get_db_params()
            if type == "INSTALL":
                self.rac_setup_complete()
                self.set_remote_listener()
                self.run_custom_scripts(
                    "CUSTOM_DB_SCRIPT_DIR", "CUSTOM_DB_SCRIPT_FILE", dbuser)
            msg = '''Oracle Database {0} is up and running on {1}.'''.format(
                osid, host)
            self.log_info_message(self.print_banner(msg), self.file_name)
            if self.ora_env_dict.get("CRS_GPC"):
                os.system("echo ORACLE DATABASE IS READY TO USE > /dev/pts/0")
                msg = '''ORACLE DATABASE IS READY TO USE'''
                self.log_info_message(self.print_banner(msg), self.file_name)
            else:
                os.system(
                    "echo ORACLE RAC DATABASE IS READY TO USE > /dev/pts/0")
                msg = '''ORACLE RAC DATABASE IS READY TO USE'''
                self.log_info_message(self.print_banner(msg), self.file_name)
        else:
            msg = '''Oracle Database {0} is not up and running on {1}.'''.format(
                osid, host)
            self.log_info_message(self.print_banner(msg), self.file_name)
            self.prog_exit("127")

# Complete RAC Setup
    def rac_setup_complete(self):
        """
        This function complete the RAC setup by creating a table inside the DB
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        dbname, osid, dbuname = self.getdbnameinfo()
        hostname = self.get_public_hostname()
        inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)
        connect_str = self.get_sqlplus_str(
            dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
        sqlcmd = '''
            set heading off
            set feedback off
            create table system.racsetup (status varchar2(10));
            insert into system.racsetup values('completed');
            commit;
            exit;
         '''
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(connect_str, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()

# Complete RAC Setup
    def get_dbversion(self):
        """
        This function returns the DB version
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        dbname, osid, dbuname = self.getdbnameinfo()
        hostname = self.get_public_hostname()
        inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)
        connect_str = self.get_sqlplus_str(
            dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
        sqlcmd = '''
            set heading off
            set feedback off
            SELECT version_full FROM v$instance;
            exit;
         '''
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(connect_str, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        if not error:
            return output.strip("\r\n")
        else:
            return "NOTAVAILABLE"

# Complete RAC Setup
    def reset_dbuser_passwd(self, user, pdb, type):
        """
        This function reset the password
        """
        passwdcmd = None
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        dbname, osid, dbuname = self.getdbnameinfo()
        hostname = self.get_public_hostname()
        inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)
        connect_str = self.get_sqlplus_str(
            dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
        if pdb:
            passwdcmd = '''alter session set container={0};alter user {1} identified by HIDDEN_STRING;'''.format(
                pdb, user)
        else:
            if type == 'all':
                passwdcmd = '''alter user {0} identified by HIDDEN_STRING container=all;'''.format(
                    user)
            else:
                passwdcmd = '''alter user {0} identified by HIDDEN_STRING;'''.format(
                    user)
        sqlcmd = '''
            set heading off
            set feedback off
            {0}
            exit;
         '''.format(passwdcmd)
        self.set_mask_str(self.get_sys_passwd())
        output, error, retcode = self.run_sqlplus(connect_str, sqlcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_sql_err(output, error, retcode, None)
        self.unset_mask_str()
        if not error:
            return output.strip("\r\n")


# Setup Primary for standby


    def set_primary_for_standby(self):
        """
         Perform the task on primary for standby
        """
        dgname = self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.check_key(
            "CRS_ASM_DISKGROUP", self.ora_env_dict) else "+DATA"
        dbrdest = self.ora_env_dict["DB_RECOVERY_FILE_DEST"] if self.check_key(
            "DB_RECOVERY_FILE_DEST", self.ora_env_dict) else dgname
        dbrdestsize = self.ora_env_dict["DB_RECOVERY_FILE_DEST_SIZE"] if self.check_key(
            "DB_RECOVERY_FILE_DEST_SIZE", self.ora_env_dict) else "10G"
        dbname, osid, dbuname = self.getdbnameinfo()

        osuser, dbhome, dbbase, oinv = self.get_db_params()
        dbname, osid, dbuname = self.getdbnameinfo()
        hostname = self.get_public_hostname()
        inst_sid = self.get_inst_sid(osuser, dbhome, osid, hostname)
        connect_str = self.get_dgmgr_str(
            dbhome, inst_sid, osuser, "sys", None, None, None, None, None, None, None)
        dgcmd = '''
           PREPARE DATABASE FOR DATA GUARD
            WITH DB_UNIQUE_NAME IS {0}
            DB_RECOVERY_FILE_DEST IS "{1}"
            DB_RECOVERY_FILE_DEST_SIZE is {2}
            BROKER_CONFIG_FILE_1 IS "{3}"
            BROKER_CONFIG_FILE_2 IS "{3}";
            exit;
         '''.format(dbuname, dbrdest, dbrdestsize, dbrdest)
        output, error, retcode = self.run_sqlplus(connect_str, dgcmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the sql command return status", self.file_name)
        self.check_dgmgrl_err(output, error, retcode, True)

######## Check INV Home ########
    def check_home_inv(self, node, dbhome, dbuser):
        """
        This function the db home with inventory
        """
        if not node:
            cmd = '''su - {0} -c "{1}/OPatch/opatch lsinventory"'''.format(
                dbuser, dbhome)
        else:
            cmd = '''su - {0} -c "ssh {2} '{1}/OPatch/opatch lsinventory'"'''.format(
                dbuser, dbhome, node)

        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if self.check_substr_match(output, "OPatch succeeded"):
            return True
        else:
            return False

######## Process delete node param variables ##############
    def del_node_params(self, key):
        """
        This function process DEL_PARAMS and set the keys
        """
        cvar_str = self.ora_env_dict[key]
        cvar_dict = dict(item.split("=") for item in cvar_str.split(";"))
        for ckey in cvar_dict.keys():
            if ckey == 'del_rachome':
                if self.check_key("DEL_RACHOME", self.ora_env_dict):
                    self.ora_env_dict["DEL_RACHOME"] = "true"
                else:
                    self.ora_env_dict = self.add_key(
                        "DEL_RACHOME", "true", self.ora_env_dict)
            if ckey == 'del_gridnode':
                if self.check_key("DEL_GRIDNODE", self.ora_env_dict):
                    self.ora_env_dict["DEL_GRIDNODE"] = "true"
                else:
                    self.ora_env_dict = self.add_key(
                        "DEL_GRIDNODE", "true", self.ora_env_dict)

######## Process delete node param variables ##############
    def populate_existing_cls_nodes(self):
        """
        This function populate the nodes witht he existing cls nodes
        """
        hostname = self.get_public_hostname()
        crs_node_list = self.get_existing_cls_nodes(hostname, hostname)
        if self.check_key("EXISTING_CLS_NODE", self.ora_env_dict):
            self.ora_env_dict["EXISTING_CLS_NODE"] = crs_node_list
        else:
            self.ora_env_dict = self.add_key(
                "EXISTING_CLS_NODE", crs_node_list, self.ora_env_dict)

######## Run the custom scripts ##############
    def run_custom_scripts(self, dirkey, filekey, user):
        """
        This function run the custom scripts after Grid or DB setup based on env variables 
        """
#          self.log_info_message("Inside run_custom_scripts()",self.file_name)
        if self.check_key(dirkey, self.ora_env_dict):
            scrdir = self.ora_env_dict[dirkey]
            if self.check_key(filekey, self.ora_env_dict):
                scrfile = self.ora_env_dict[filekey]
                script_file = '''{0}/{1}'''.format(scrdir, scrfile)
                if os.path.isfile(script_file):
                    msg = '''Custom script exist {0}'''.format(script_file)
                    self.log_info_message(msg, self.file_name)
                    cmd = '''su - {0} -c "sh {0}"'''.format(user, script_file)
                    output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
#             else:
#              self.log_info_message("Custom script dir is specified " + self.ora_env_dict[dirkey] + " but no user script file is specified. Not executing any user specified script.",self.file_name)
#          else:
#            self.log_info_message("No custom script dir specified to execute user specified scripts. Not executing any user specified script.",self.file_name)

    def sync_gi_home(self, node, ohome, user, clsnodes):
        """
        Sync GI home during addnode.
        ED25519-safe and StrictHostKeyChecking-compliant.
        """

        ssh_opts = (
            "-o StrictHostKeyChecking=yes "
            "-o PasswordAuthentication=no "
            "-o BatchMode=yes"
        )

        for target_node in clsnodes:

            # ------------------------------------------------------------
            # Ensure ED25519 host key exists on SOURCE node (critical)
            # ------------------------------------------------------------
            seed_cmd = (
                "su - {0} -c "
                "\"ssh-keygen -F {1} >/dev/null || "
                "ssh-keyscan -t ed25519 -H {1} >> ~/.ssh/known_hosts\""
            ).format(user, target_node)

            self.execute_cmd(seed_cmd, None, None)

            # ------------------------------------------------------------
            # rsync using SSH with enforced ED25519 verification
            # ------------------------------------------------------------
            rsync_cmd = (
                "su - {0} -c "
                "\"ssh {1} "
                "'rsync -Pav -e \\\"ssh {2}\\\" "
                "--exclude \\\"{1}*\\\" "
                "{3}/* {0}@{4}:{3}'\""
            ).format(
                user,
                node,
                ssh_opts,
                ohome,
                target_node
            )

            output, error, retcode = self.execute_cmd(rsync_cmd, None, None)
            self.check_os_err(output, error, retcode, False)


# Set the User profiles
    def set_user_profile(self, ouser, key, val, type):
        """
        This function run the custom scripts after Grid or DB setup based on env variables 
        """
        match = None
        bashrc = '''/home/{0}/.bashrc'''.format(ouser)
        fdata = self.read_file(bashrc)

        match = re.search(key, fdata, re.MULTILINE)
        # if not match:
        if type == "export":
            cmd = '''echo "export {0}={1}" >> {2}'''.format(key, val, bashrc)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)
        if type == "alias":
            cmd = '''echo "alias {0}='{1}'" >> {2}'''.format(key, val, bashrc)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=True)

# Reading  grid Resonsefile

  # Update the env variables dictionary from the values in the grid response file ( if provided )

    def _set_or_update_env(self, key, value):
        """
        Set env key value by updating existing entry or adding a new one.
        """
        self.ora_env_dict = self.upsert_env(key, value, self.ora_env_dict)

    def _iter_rsp_kv_pairs(self, rsp_file, log_pairs=True):
        """
        Yield key-value pairs from response file lines containing '='.
        """
        with open(rsp_file) as fp:
            for line in fp:
                if "=" not in line:
                    continue
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()
                if log_pairs:
                    self.log_info_message(
                        "KEY and Value pair set to: " + key + ":" + value, self.file_name)
                yield key, value

    def _update_cluster_nodes_from_rsp(self, value, log_details=True):
        """
        Parse cluster node list from response value and update INSTALL_NODE/CRS_NODES.
        """
        cls_nodes = []
        install_node_set = False

        for crs_node in value.split(","):
            parts = crs_node.split(":")
            if len(parts) < 2:
                continue

            install_node = parts[0].strip()
            install_vip_node = parts[1].strip()
            cls_node = '''pubhost:{0},viphost:{1}'''.format(install_node, install_vip_node)
            if log_details:
                self.log_info_message("cls_node set to : " + cls_node, self.file_name)
            cls_nodes.append(cls_node)
            if log_details:
                self.log_info_message("cls_nodes set to : " + ";".join(cls_nodes) + ";", self.file_name)

            if not install_node_set:
                self._set_or_update_env("INSTALL_NODE", install_node)
                install_node_set = True
                if log_details:
                    self.log_info_message(
                        "Install node set to :" + self.ora_env_dict["INSTALL_NODE"], self.file_name)

        if cls_nodes:
            crs_nodes = ";".join(cls_nodes)
            if log_details:
                self.log_info_message("cls_nodes set to : " + crs_nodes + ";", self.file_name)
            self._set_or_update_env("CRS_NODES", crs_nodes)

    def _update_gi_env_vars_from_rspfile_internal(
            self,
            key_mapping,
            cluster_nodes_key,
            redundancy_key,
            au_size_key=None,
            log_details=True):
        """
        Shared implementation for GI response file parsing across versions.
        """
        if not self.check_key("GRID_RESPONSE_FILE", self.ora_env_dict):
            return

        gridrsp = self.ora_env_dict["GRID_RESPONSE_FILE"]
        if log_details:
            self.log_info_message(
                "GRID_RESPONSE_FILE parameter is set and file location is:" + gridrsp, self.file_name)

        gridrsp = self.validate_response_file(gridrsp, "grid")

        for key, value in self._iter_rsp_kv_pairs(gridrsp, log_pairs=log_details):
            if key in key_mapping:
                self._set_or_update_env(key_mapping[key], value)
            elif key == cluster_nodes_key:
                self._update_cluster_nodes_from_rsp(value, log_details=log_details)
            elif key == redundancy_key:
                self._set_or_update_env("CRS_ASMDG_REDUNDANCY ", value)
            elif au_size_key and key == au_size_key:
                self._set_or_update_env("CRS_ASMDG_AU_SIZE ", value)

    def update_gi_env_vars_from_rspfile(self, log_details=True):
        """
        Update GI env vars as key value pair from the response file (if provided).
        """
        key_mapping = {
            "INVENTORY_LOCATION": "INVENTORY",
            "ORACLE_BASE": "GRID_BASE",
            "scanName": "SCAN_NAME",
            "diskString": "CRS_ASM_DISCOVERY_STRING",
            "diskList": "CRS_ASM_DEVICE_LIST",
            "diskGroupName": "CRS_ASM_DISKGROUP",
        }

        self._update_gi_env_vars_from_rspfile_internal(
            key_mapping=key_mapping,
            cluster_nodes_key="clusterNodes",
            redundancy_key="redundancy",
            au_size_key=None,
            log_details=log_details,
        )

    def update_pre_23c_gi_env_vars_from_rspfile(self, log_details=True):
        """
        Update GI env vars as key value pair from the response file (if provided).
        """
        key_mapping = {
            "INVENTORY_LOCATION": "INVENTORY",
            "ORACLE_BASE": "GRID_BASE",
            "oracle.install.crs.config.gpnp.scanName": "SCAN_NAME",
            "oracle.install.asm.diskGroup.diskDiscoveryString": "CRS_ASM_DISCOVERY_STRING",
            "oracle.install.asm.diskGroup.disks": "CRS_ASM_DEVICE_LIST",
        }

        self._update_gi_env_vars_from_rspfile_internal(
            key_mapping=key_mapping,
            cluster_nodes_key="oracle.install.crs.config.clusterNodes",
            redundancy_key="oracle.install.asm.diskGroup.redundancy",
            au_size_key="oracle.install.asm.diskGroup.AUSize",
            log_details=log_details,
        )

    def update_rac_env_vars_from_rspfile(self, dbcarsp, log_details=True):
        """
        Update RAC env vars as key value pair from the response file (if provided).
        """
        dbcarsp = self.validate_response_file(dbcarsp, "dbca")

        def _set_env(key, value):
            self.ora_env_dict = self.upsert_env(key, value, self.ora_env_dict)

        with open(dbcarsp) as fp:
            for line in fp:
                if log_details:
                    msg = "Read from dbca.rsp: line=" + line
                    self.log_info_message(msg, self.file_name)

                if "=" not in line:
                    continue

                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()

                if log_details:
                    msg = "key=" + key + ".. value=" + value
                    self.log_info_message(msg, self.file_name)

                if key == "gdbName":
                    _set_env("DB_NAME", value)
                    continue

                if key == "datafileDestination" and value != "":
                    match = re.search(r"\+(.+?)/.*", value)
                    if match:
                        _set_env("DB_DATA_FILE_DEST", match.group(1))
                    continue

                if key == "recoveryAreaDestination" and value != "":
                    match = re.search(r"\+(.+?)/.*", value)
                    if match:
                        _set_env("DB_RECOVERY_FILE_DEST", match.group(1))
                    continue

                if key == "variables" and value:
                    variables_map = {}
                    for item in value.split(","):
                        if "=" in item:
                            vkey, vvalue = item.split("=", 1)
                            variables_map[vkey.strip()] = vvalue.strip()

                    if "DB_UNIQUE_NAME" in variables_map:
                        _set_env("DB_UNIQUE_NAME", variables_map["DB_UNIQUE_NAME"])
                    if "ORACLE_HOME" in variables_map:
                        _set_env("DB_HOME", variables_map["ORACLE_HOME"])
                    if "ORACLE_BASE" in variables_map:
                        _set_env("DB_BASE", variables_map["ORACLE_BASE"])

  # Update the env variables dictionary from the values in the grid response file ( if provided )

    def update_domainfrom_resolvconf_file(self):
        """
        Update domain variables using /etc/resolv.conf values when available.
        """
        resolv_conf = "/etc/resolv.conf"
        if not os.path.isfile(resolv_conf):
            return

        fdata = self.read_file(resolv_conf)

        def _set_env(key, value):
            self.ora_env_dict = self.upsert_env(key, value, self.ora_env_dict)

        # First configured nameserver is used as DNS_SERVERS value.
        nameserver_match = re.search(r"^\s*nameserver\s+(\S+)", fdata, re.MULTILINE)
        if nameserver_match:
            dns_server = nameserver_match.group(1).strip()
            _set_env("DNS_SERVERS", dns_server)

        search_match = re.search(r"^\s*search\s+(.+)$", fdata, re.MULTILINE)
        if not search_match:
            self.log_warn_message("No search domain found in /etc/resolv.conf", self.file_name)
            return

        search_value = search_match.group(1).strip()
        domains = search_value.split()
        if not domains:
            self.log_warn_message("Search domain entry in /etc/resolv.conf is empty", self.file_name)
            return

        pub_domain = domains[0]
        self.log_info_message("Domain set to :" + pub_domain, self.file_name)
        _set_env("PUBLIC_HOSTS_DOMAIN", pub_domain)

# set DG Prefix Function
    def setdgprefix(self, dgname):
        """
        add dg prefix
        """
        dgflag = dgname.startswith("+")
        stype = self.ora_env_dict["DB_STORAGE_TYPE"] if self.check_key(
            "DB_STORAGE_TYPE", self.ora_env_dict) else "ASM"

        if stype == "ASM" and not dgflag:
            dgname = "+" + dgname
            self.log_info_message(
                "The dgname set to : " + dgname, self.file_name)

        return dgname

# rm DG Prefix Function
    def rmdgprefix(self, dgname):
        """
        rm dg prefix
        """
        dgflag = dgname.startswith("+")

        if dgflag:
            return dgname[1:]
        else:
            return dgname

# Get SID, dbname,dbuname
    def getdbnameinfo(self):
        """
        this function returns the sid,dbname,dbuname 
        """
        dbname = self.ora_env_dict["DB_NAME"] if self.check_key(
            "DB_NAME", self.ora_env_dict) else "ORCLCDB"
        osid = dbname
        dbuname = self.ora_env_dict["DB_UNIQUE_NAME"] if self.check_key(
            "DB_UNIQUE_NAME", self.ora_env_dict) else dbname

        return dbname, osid, dbuname

# function to return DG Name for CRS
    def getcrsdgname(self):
        """
        return CRS DG NAME
        """
        return self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.check_key("CRS_ASM_DISKGROUP", self.ora_env_dict) else "+DATA"


# function to return DG Name for DATAFILE

    def getdbdestdgname(self, dgname):
        """
        return DB DG NAME
        """
        return self.ora_env_dict["DB_DATA_FILE_DEST"] if self.check_key("DB_DATA_FILE_DEST", self.ora_env_dict) else dgname

# function to return DG Name for RECOVERY DESTINATION
    def getdbrdestdgname(self, dgname):
        """
        return RECO DG NAME
        """
        return self.ora_env_dict["DB_RECOVERY_FILE_DEST"] if self.check_key("DB_RECOVERY_FILE_DEST", self.ora_env_dict) else dgname


# function to return DG Name for REDO LOG DESTINATION

    def getredodestdgname(self, dgname):
        """
        return REDO DG NAME
        """
        return self.ora_env_dict["LOG_FILE_DEST"] if self.check_key("LOG_FILE_DEST", self.ora_env_dict) else dgname


# Function to catalog the backup


    def catalog_bkp(self):
        """
        catalog the backup
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        osid = self.ora_env_dict["GOLD_SID_NAME"]
        rmanlogincmd = self.get_rman_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        rmancmd = '''
           catalog start with '{0}' noprompt;   
        '''.format(self.ora_env_dict["GOLD_DB_BACKUP_LOC"])
        self.log_info_message(
            "Running the rman command to catalog the backup: " + rmancmd, self.file_name)
        output, error, retcode = self.run_sqlplus(rmanlogincmd, rmancmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the rman command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

# Function to validate the backup
    def check_bkp(self):
        """
        Check the backup
        """
        pass

# Function to validate the backup
    def restore_bkp(self, dgname):
        """
        restore the backup
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        osid = self.ora_env_dict["GOLD_SID_NAME"]
        dbname = self.ora_env_dict["GOLD_DB_NAME"]
        self.log_info_message(
            "In restore_bkp() : dgname=[" + dgname + "]", self.file_name)
        rmanlogincmd = self.get_rman_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        rmancmd = '''
       run {{
         restore controlfile from '{2}';
         alter database mount;
         set newname for database to '{0}';
         restore database;
         switch datafile all;
         alter database open resetlogs;
         alter pluggable database {1} open read write;
       }}
       '''.format(dgname, self.ora_env_dict["GOLD_PDB_NAME"], "/oradata/orclcdb_bkp/spfile" + dbname + ".ora")
        self.log_info_message(
            "Running the rman command to restore the controlfile and datafiles from the backup: " + rmancmd, self.file_name)
        output, error, retcode = self.run_sqlplus(rmanlogincmd, rmancmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the rman command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

# Function restore the spfile
    def restore_spfile(self):
        """ 
        Restore the spfile
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        osid = self.ora_env_dict["GOLD_SID_NAME"]
        dbname = self.ora_env_dict["GOLD_DB_NAME"]
        rmanlogincmd = self.get_rman_str(
            dbhome, osid, osuser, "sys", None, None, None, osid, None, None, None)
        rmancmd = '''
         restore spfile from '{0}'; 
       '''.format(self.ora_env_dict["GOLD_DB_BACKUP_LOC"] + "/spfile" + dbname + ".ora")
        self.log_info_message(
            "Running the rman command to restore the spfile from the backup: " + rmancmd, self.file_name)
        output, error, retcode = self.run_sqlplus(rmanlogincmd, rmancmd, None)
        self.log_info_message(
            "Calling check_sql_err() to validate the rman command return status", self.file_name)
        self.check_sql_err(output, error, retcode, True)

# Set cluster mode to true or false
    def set_cluster_mode(self, pfile, cflag):
        """
        This function sets the cluster mode to true or false in the pfile
        """
        cmd = '''sed -i "s/*.cluster_database=.*/*.cluster_database={0}/g" {1}'''.format(
            cflag, pfile)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=False)

# Change the dbname in the parameter file to the new dbname
    def change_dbname(self, pfile, newdbname):
        """
        This function sets the resets the dbname to newdbname in the pfile
        """
        osuser, dbhome, dbbase, oinv = self.get_db_params()
        olddbname = self.ora_env_dict["GOLD_DB_NAME"]
        osid = self.ora_env_dict["GOLD_SID_NAME"]
        cmd = '''su - {3} -c "export ORACLE_SID={2};export ORACLE_HOME={1};echo Y | {1}/bin/nid target=/ dbname={0}"'''.format(
            newdbname, dbhome, osid, osuser)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=False)

        self.set_cluster_mode(pfile, True)
        cmd = '''sed -i "s/*.db_name=.*/*.db_name={0}/g" {1}'''.format(
            newdbname, pfile)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=False)
        cmd = '''sed -i "s/*.db_unique_name=.*/*.db_unique_name={0}/g" {1}'''.format(
            newdbname, pfile)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=False)
        cmd = '''sed -i "s/{0}\(.*\).instance_number=\(.*\)/{1}\\1.instance_number=\\2/g" {2}'''.format(
            olddbname, newdbname, pfile)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=False)

# Change the dbname in the parameter file to the new dbname
    def rotate_log_files(self):
        """
        Rotate log files.
        """
        try:
            # Preferred path for new logger implementation (timed + archived)
            self.ologger.force_rotate()
            return
        except Exception:
            # Keep legacy fallback behavior in case logger object is old/custom
            currentfile = '''{0}'''.format(self.ologger.filename_)
            newfile = '''{0}.old'''.format(self.ologger.filename_)
            if self.check_file(currentfile, "local", None, None):
                os.rename(currentfile, newfile)

    def modify_scan(self, giuser, gihome, scanname):
        """
        Modify Scan Details (run as sudo)
        """

        cmd = (
            'su - {0} -c '
            '"sudo {1}/bin/srvctl modify scan -scanname {2}"'
        ).format(giuser, gihome, scanname)

        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

        return retcode == 0

    def updateasmcount(self, giuser, gihome, asmcount):
        """
        Update ASM disk counts
        """
        cmd = '''su - {0} -c "{1}/bin/srvctl modify asm -count {2}"'''.format(
            giuser, gihome, asmcount)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if retcode == 0:
            return True
        else:
            return False

    def updateasmdevices(self, giuser, gihome, diskname, diskgroup, processtype):
        """
        Update ASM devices, handle addition or deletion.
        """
        retcode = 1
        if processtype == "addition":
            cmd = '''su - {0} -c "{1}/bin/asmca -silent -addDisk -diskGroupName {2} -disk {3}"'''.format(
                giuser, gihome, diskgroup, diskname)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        elif processtype == "deletion":
            cmd = '''su - {0} -c "{1}/bin/asmca -silent -removeDisk -diskGroupName {2} -disk {3}"'''.format(
                giuser, gihome, diskgroup, diskname)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if retcode == 0:
            return True
        else:
            return False

    def updatelistenerendp(self, giuser, gihome, listenername, portlist):
        """
        Update ListenerEndpoints
        """
        cmd = '''su - {0} -c "{1}/bin/srvctl modify listener -listener {2} -endpoints 'TCP:{3}'"'''.format(
            giuser, gihome, listenername, portlist)
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        if retcode == 0:
            return True
        else:
            return False

    def get_asmsid(self, giuser, gihome):
        """
        get the asm sid details
        """
        sid = None
        if self.check_key("CRS_GPC", self.ora_env_dict):
            # Oracle Restart environment
            cmd = '''su - {0} -c "{1}/bin/crsctl status resource ora.asm -f"'''.format(
                giuser, gihome)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
            if retcode == 0:
                for line in output.splitlines():
                    if line.startswith(("GEN_USR_ORA_INST_NAME=", "USR_ORA_INST_NAME=")):
                        sid = line.split("=")[1]
                        break
        else:
            # RAC environment
            cmd = '''su - {0} -c "{1}/bin/olsnodes -n"'''.format(
                giuser, gihome)
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
            if retcode == 0:
                pubhost = self.get_public_hostname()
                for line in output.splitlines():
                    if pubhost in line:
                        nodeid = line.split()
                        if len(nodeid) == 2:
                            sid = "+ASM" + nodeid[1]
                            break

        if sid is not None:
            self.log_info_message("ASM sid set to :" + sid, self.file_name)
            return sid
        else:
            return None

    def check_asminst(self, giuser, gihome):
        """
        check asm instance
        """
        sid = self.get_asmsid(giuser, gihome)
        if sid is not None:
            sqlpluslogincmd = self.get_sqlplus_str(
                gihome, sid, giuser, "sys", None, None, None, sid, None, None, None)
            sqlcmd = """
            set heading off
            set feedback off
            set  term off
            SET NEWPAGE NONE
            select status from v$instance;
            exit;
          """
            output, error, retcode = self.run_sqlplus(
                sqlpluslogincmd, sqlcmd, None)
            self.log_info_message(
                "Calling check_sql_err() to validate the sql command return status", self.file_name)
            self.check_sql_err(output, error, retcode, True)
            if "STARTED" in ''.join(output).upper() or "OPEN" in ''.join(output).upper():
                return 0
            else:
                return 1

    def get_asmdg(self, giuser, gihome):
        """
        get the asm dg list
        """
        sid = self.get_asmsid(giuser, gihome)
        if sid is not None:
            sqlpluslogincmd = self.get_sqlplus_str(
                gihome, sid, giuser, "sys", None, None, None, sid, None, None, None)
            sqlcmd = """
            set heading off
            set feedback off
            set  term off
            SET NEWPAGE NONE
            select name from v$asm_diskgroup;
          """
            output, error, retcode = self.run_sqlplus(
                sqlpluslogincmd, sqlcmd, None)
            self.log_info_message(
                "Calling check_sql_err() to validate the sql command return status", self.file_name)
            self.check_sql_err(output, error, retcode, True)
            return output.strip().replace('\n', ',')

    def get_asmdgrd(self, giuser, gihome, dg):
        """
        get the asm disk redundancy
        """
        sid = self.get_asmsid(giuser, gihome)
        if sid is not None:
            sqlpluslogincmd = self.get_sqlplus_str(
                gihome, sid, giuser, "sys", None, None, None, sid, None, None, None)
            sqlcmd = """
            set heading off
            set feedback off
            set  term off
            SET NEWPAGE NONE
            select type from v$asm_diskgroup where upper(name)=upper('{0}');
          """.format(dg)
            output, error, retcode = self.run_sqlplus(
                sqlpluslogincmd, sqlcmd, None)
            self.log_info_message(
                "Calling check_sql_err() to validate the sql command return status", self.file_name)
            self.check_sql_err(output, error, retcode, True)
            return output

    def get_asmdsk(self, giuser, gihome, dg):
        """
        Return ASM disks that belong to a specific diskgroup
        """

        sid = self.get_asmsid(giuser, gihome)

        cmd = (
            '''su - {0} -c "export ORACLE_SID={1};'''
            '''{2}/bin/asmcmd lsdsk -G {3} --suppressheader"'''
        ).format(giuser, sid, gihome, dg)

        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)

        if retcode == 0 and output:
            disks = []
            for line in output.strip().splitlines():
                parts = line.split()
                if len(parts) == 1:
                    disks.append(parts[0])      # path-only format
                else:
                    disks.append(parts[-1])     # multi-column format
            return ",".join(disks)

        return ""
    def _wait_for_cdp_removal(self, gihome, retries=10, sleep_sec=3):
        """
        Wait until CDP is fully removed from OCR.
        """
        check_cmd = "{}/bin/srvctl status cdp".format(gihome)

        for i in range(retries):
            out, err, rc = self.execute_cmd(check_cmd, None, None)

            if rc != 0 and "PRCS-1157" in (out + err):
                return True  # CDP is gone

            time.sleep(sleep_sec)

        return False

    def update_cdp(self, operation, node):
        """
        Reconcile CDP configuration with current SCAN topology.
        CDPs are recreated but NOT enabled or started.
        """

        giuser, gihome, obase, invloc = self.get_gi_params()

        oraversion = self.get_rsp_version(operation, node)
        major_version = int(oraversion.split(".", 1)[0].strip())

        if major_version < 23:
            self.log_info_message(
                "GI version {}: CDP update not required".format(oraversion),
                self.file_name
            )
            return True

        self.log_info_message(
            "GI version {}: Reconciling CDP configuration".format(oraversion),
            self.file_name
        )

        remove_cmd = "sudo {}/bin/srvctl remove cdp".format(gihome)
        add_cmd = "sudo {}/bin/srvctl add cdp".format(gihome)

        # Step 1: Remove CDP
        out, err, rc = self.execute_cmd(remove_cmd, None, None)

        if rc != 0 and "PRCS-1157" not in (out + err):
            self.log_info_message(
                "Failed to remove CDP (rc={})\nCommand: {}\nSTDOUT: {}\nSTDERR: {}".format(
                    rc, remove_cmd, out.strip(), err.strip()
                ),
                self.file_name
            )
            return False

        # Step 2: WAIT for OCR propagation
        if not self._wait_for_cdp_removal(gihome):
            self.log_info_message(
                "Timed out waiting for CDP removal from OCR",
                self.file_name
            )
            return False

        # Step 3: Add CDP (retry-safe)
        out, err, rc = self.execute_cmd(add_cmd, None, None)

        if rc != 0:
            self.log_info_message(
                "Failed to add CDP (rc={})\nCommand: {}\nSTDOUT: {}\nSTDERR: {}".format(
                    rc, add_cmd, out.strip(), err.strip()
                ),
                self.file_name
            )
            return False

        self.log_info_message(
            "CDP configuration added (disabled, not running)",
            self.file_name
        )

        return True


    def update_ons(self, giuser, gihome, onsstate):
        """
        Update ONS details based on the onsstate:
        - start   : enable and start ONS (skip if already enabled and running)
        - stop    : stop and disable ONS
        - enable  : only enable ONS
        - disable : only disable ONS
        - status  : get ONS status
        """
        def run_cmd(action):
            cmd = f'''su - {giuser} -c "{gihome}/bin/srvctl {action} ons"'''
            output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
            return output.strip(), retcode

        if onsstate == "start":
            # Check current status
            status_output, status_ret = run_cmd("status")
            if status_ret != 0:
                return False

            lower_status = status_output.lower()
            # Example: "ons is enabled and running on node(s): ..."
            if "enabled" in lower_status and ("running" in lower_status or "online" in lower_status):
                # Already enabled and running
                return True

            # Enable if not enabled
            if "enabled" not in lower_status:
                if run_cmd("enable")[1] != 0:
                    return False

            # Start if not running
            return run_cmd("start")[1] == 0

        elif onsstate == "stop":
            return run_cmd("stop")[1] == 0 and run_cmd("disable")[1] == 0

        elif onsstate in {"enable", "disable", "status"}:
            return run_cmd(onsstate)[1] == 0

        return False

    def clean_oracle_dirs(self, node):
        """
        Removes /u01/app/oraInventory and /u01/app/grid on a remote node,
        then sets correct ownership and permissions on /u01/app.
        """
        try:
            giuser, _, _, _ = self.get_gi_params()  # GI user for ownership tasks

            cmds = [
                "sudo rm -rf /u01/app/oraInventory",
                "sudo rm -rf /u01/app/grid",
                "sudo chown -R grid:oinstall /u01/app",
                "sudo chmod 775 /u01/app"
            ]

            for cmd in cmds:
                remote_cmd = '''su - {0} -c "ssh {1} '{2}'"'''.format(
                    giuser, node, cmd)
                output, error, retcode = self.execute_cmd(
                    remote_cmd, None, True)
                self.check_os_err(output, error, retcode, True)
                self.log_info_message(
                    "Executed on {}: {}".format(node, cmd), self.file_name)

        except Exception as e:
            self.log_error_message(
                "Failed to clean and reset /u01/app directories on {}: {}".format(
                    node, str(e)),
                self.file_name
            )


######## Get the  dbversion ###############


    def get_ora_version(self):
        """
        This function return the complete db version in a.b.c.d.e
        """
        cmd = ""
        giuser, gihome, gbase, oinv = self.get_gi_params()
        cmd = '''su - {0} -c "{1}/bin/oraversion -compositeVersion"'''.format(
            giuser, gihome)

        vdata = ""
        output, error, retcode = self.execute_cmd_checked(cmd, None, None, exit_on_error=None)
        vdata = output.strip()
        self.log_info_message(
            "get_ora_version():[" + vdata + "]", self.file_name)
        major_version, minor_version, other_version = vdata.split(".", 2)
        return major_version, minor_version
    
    def seed_ed25519_on_source(self, user, source_node, target_node):
        """
        Ensure ED25519 host key for target_node exists
        in known_hosts ON THE SOURCE NODE.
        """

        cmd = (
            "su - {0} -c "
            "\"ssh {1} "
            "'ssh-keygen -F {2} >/dev/null || "
            "ssh-keyscan -t ed25519 -H {2} >> ~/.ssh/known_hosts'\""
        ).format(user, source_node, target_node)

        self.execute_cmd(cmd, None, None)

    def update_osid_for_grid_and_db_users(self):
        """
        Update OSID for both Grid and DB users by modifying their .bashrc profile.
        """
        status = ""
        msg = ""
        users = []

        # Gather DB user details
        try:
            dbuser, dbhome, dbbase, dbinv = self.get_db_params()
            dbname = self.ora_env_dict["DB_NAME"] if self.check_key("DB_NAME", self.ora_env_dict) else "ORCLCDB"
            hostname = self.get_public_hostname()
            dbosid = self.get_inst_sid(dbuser, dbhome, dbname, hostname)
            if not dbosid:
                dbosid = dbname + "1"
            users.append((dbuser, dbosid))
        except Exception as e:
            status = "DB_USER_INFO_FAILED"
            msg = '''Failed to get DB user info: {0}'''.format(e)
            self.log_info_message(msg, self.file_name)
            print(status)
            self.prog_exit("Error occurred")

        # Gather GI user details
        try:
            giuser, gihome, gibase, giinv = self.get_gi_params()
            giname = self.ora_env_dict["DB_NAME"] if self.check_key("DB_NAME", self.ora_env_dict) else "ORCLCDB"
            hostname = self.get_public_hostname()
            giosid = self.get_inst_sid(giuser, gihome, giname, hostname)
            if not giosid:
                giosid = giname + "1"
            users.append((giuser, giosid))
        except Exception as e:
            status = "GI_USER_INFO_FAILED"
            msg = '''Failed to get GI user info: {0}'''.format(e)
            self.log_info_message(msg, self.file_name)
            print(status)
            self.prog_exit("Error occurred")

        # Update .bashrc for each user
        for osuser, osid in users:
            bashrc_path = "/home/{0}/.bashrc".format(osuser)
            bashrc_line = "\nexport ORACLE_SID={0}\n".format(osid)
            try:
                with open(bashrc_path, "a") as bashrc_file:
                    bashrc_file.write(bashrc_line)
                msg = '''ORACLE_SID {0} is now added to {1}'''.format(osid, bashrc_path)
                # status = "OSID_UPDATED_SUCCESSFULLY"
                self.log_info_message(msg, self.file_name)
                # print(status)
            except Exception as e:
                # status = "OSID_NOT_UPDATED"
                msg = '''Failed to update {0} for user {1}: {2}'''.format(bashrc_path, osuser, e)
                self.log_info_message(msg, self.file_name)
                # print(status)
                self.prog_exit("Error occurred")

    def update_listener_env_for_users(self):
        """
        Configure listener-related environment variables for interactive shells
        (oracle and grid users). Idempotent and safe across pod restarts.
        """

        giuser, gihome, gibase, giinv = self.get_gi_params()
        dbuser, dbhome, dbbase, dbinv = self.get_db_params()

        marker = "# --- RAC listener environment ---"

        exports = [
            "export GRID_HOME={0}".format(gihome),
            "export TNS_ADMIN={0}/network/admin".format(gihome),
        ]

        for user in [giuser, dbuser]:
            bashrc_path = "/home/{0}/.bashrc".format(user)

            try:
                existing = ""
                if self.check_file(bashrc_path, True, None, None):
                    existing = self.read_file(bashrc_path)

                with open(bashrc_path, "a") as bashrc:
                    if marker not in existing:
                        bashrc.write("\n{0}\n".format(marker))

                    for line in exports:
                        if line not in existing:
                            bashrc.write("{0}\n".format(line))

                self.log_info_message(
                    "Listener environment updated for user {0}".format(user),
                    self.file_name
                )

            except Exception as e:
                self.log_error_message(
                    "Failed to update listener environment for user {0}: {1}".format(user, e),
                    self.file_name
                )
                self.prog_exit("127")
