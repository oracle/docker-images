#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

"""
This is the main file which calls other file to setup the sharding.
"""

import getopt
import os
import sys
import traceback

from oralogger import *
from orafactory import *
from oraenv import *
from oracommon import *

_HELP_TEXT = (
   "You can pass parameter --addshard, --deleteshard, --validateshard, "
   "--checkliveness, --resetlistener, --restartdb, --createdir, --optype, "
   "--addshardgroup, --deployshard, '--checkonlineshard', '--cancelchunks', "
   "'--movechunks', '--checkchunks', '--checkgsmshard','--validatenochunks', "
   "'--checkreadyness','--invitednode', '--resetpassword','--exporttdekey',"
   "'--importtdekey',or --help"
)

_SEPARATOR = "======================================================================="

_LONG_OPTS = [
   "addshard=",
   "deleteshard=",
   "validateshard=",
   "checkliveness=",
   "resetlistener=",
   "restartdb=",
   "createdir=",
   "optype=",
   "addshardgroup=",
   "deployshard=",
   "movechunks=",
   "checkonlineshard=",
   "cancelchunks=",
   "checkchunks=",
   "checkgsmshard=",
   "checkreadyness=",
   "validatenochunks=",
   "invitednode=",
   "resetpassword=",
   "exporttdekey=",
   "importtdekey=",
   "prestandbysetup=",
   "help",
]

_OPTION_RULES = {
   "--addshard": ("ADD_SHARD", "ADD_SHARD", False),
   "--validateshard": ("VALIDATE_SHARD", "VALIDATE_SHARD", False),
   "--deleteshard": ("REMOVE_SHARD", "REMOVE_SHARD", False),
   "--checkliveness": ("CHECK_LIVENESS", "CHECK_LIVENESS", True),
   "--checkreadyness": ("CHECK_READYNESS", "CHECK_READYNESS", True),
   "--resetlistener": ("RESET_LISTENER", "RESET_LISTENER", False),
   "--restartdb": ("RESTART_DB", "RESTART_DB", False),
   "--createdir": ("CREATE_DIR", "CREATE_DIR", False),
   "--addshardgroup": ("ADD_SGROUP_PARAMS", "ADD_SGROUP_PARAMS", False),
   "--deployshard": ("DEPLOY_SHARD", "DEPLOY_SHARD", False),
   "--cancelchunks": ("CANCEL_CHUNKS", "CANCEL_CHUNKS", False),
   "--movechunks": ("MOVE_CHUNKS", "MOVE_CHUNKS", False),
   "--checkchunks": ("CHECK_CHUNKS", "CHECK_CHUNKS", False),
   "--validatenochunks": ("VALIDATE_NOCHUNKS", "VALIDATE_NOCHUNKS", False),
   "--checkonlineshard": ("CHECK_ONLINE_SHARD", "CHECK_ONLINE_SHARD", False),
   "--checkgsmshard": ("CHECK_GSM_SHARD", "CHECK_GSM_SHARD", False),
   "--invitednode": ("INVITED_NODE_OP", "INVITED_NODE_OP", False),
   "--resetpassword": ("RESET_PASSWD", "RESET_PASSWORD", False),
   "--exporttdekey": ("TDE_KEY", "EXPORT_TDE_KEY", False),
   "--importtdekey": ("TDE_KEY", "IMPORT_TDE_KEY", False),
   "--prestandbysetup": ("PRE_STANDBY_SETUP", "PRE_STANDBY_SETUP", False),
}


def _handle_help(oralogger, stdout_handler, file_name):
   oralogger.msg_ = '''{:^17}-{:^17} : {}'''.format(file_name, "main", _HELP_TEXT)
   stdout_handler.handle(oralogger)


def _apply_option(opt, arg, oenv, oralogger, ocommon):
   if opt == "--optype":
      oenv.add_custom_variable("OP_TYPE", arg)
      return None

   rule = _OPTION_RULES.get(opt)
   if not rule:
      return None

   logfile_type, custom_key, disable_stdout = rule
   if disable_stdout:
      oralogger.stdout_ = None

   file_name = oenv.logfile_name(logfile_type)
   oralogger.filename_ = file_name
   ocommon.log_info_message(_SEPARATOR, file_name)
   oenv.add_custom_variable(custom_key, arg)
   return file_name


def main(): 

   # Checking Comand line Args
   opts = []
   try:
      opts, _ = getopt.getopt(sys.argv[1:], "", _LONG_OPTS)
   except getopt.GetoptError:
      pass
  
   # Initializing oraenv instance 
   oenv=OraEnv()
   file_name  = os.path.basename(__file__)
   funcname = sys._getframe(1).f_code.co_name

   log_file_name = oenv.logfile_name("NONE")

   # Initialiing logger instance
   oralogger  = OraLogger(log_file_name)
   console_handler = CHandler()
   file_handler = FHandler()
   stdout_handler = StdHandler()
   # Setting next log handlers
   stdout_handler.nextHandler = file_handler
   file_handler.nextHandler = console_handler
   console_handler.nextHandler = PassHandler()

   ocommon = OraCommon(oralogger,stdout_handler,oenv)

   for opt, arg in opts:
      if opt == "--help":
         _handle_help(oralogger, stdout_handler, file_name)
         continue

      applied_file = _apply_option(opt, arg, oenv, oralogger, ocommon)
      if applied_file:
         file_name = applied_file

   # Initializing orafactory instances   
   oralogger.msg_ = '''{:^17}-{:^17} : Calling OraFactory to start the setup'''.format(file_name,funcname)
   stdout_handler.handle(oralogger)
   orafactory = OraFactory(oralogger,stdout_handler,oenv,ocommon)
   
   # Get the ora objects
   ofactory=orafactory.get_ora_objs()

   # Traverse through returned factory objects and execute the setup function
   for obj in ofactory:
       obj.setup()
    
# Using the special variable  
if __name__=="__main__": 
    try:
       main()
    except SystemExit:
       raise
    except Exception:
       traceback.print_exc()
       print("Unhandled exception in main.py", file=sys.stderr)
       sys.exit(1)
