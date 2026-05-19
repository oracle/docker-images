#!/usr/bin/python

#############################
# Copyright 2020 - 2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
# Contributor: saurabh.ahuja@oracle.com
############################

"""
This is the main file that calls other files to set up Real Application Clusters.
"""

from oralogger import *
from orafactory import *
from oraenv import *
from oracommon import *


def main():

   # Checking Comand line Args
   opts=[]
   args=[]
   parse_error = None
   try:
      opts, args = getopt.getopt(sys.argv[1:], '', ['help','resetpassword=','delracnode=','addtns=', 'checkracinst=', 'checkgilocal=','checkdbrole=','checkracdb=','checkracstatus','checkconnstr=','checkpdbconnstr=','setupdblsnr=','setuplocallsnr=','checkdbsvc=','modifydbsvc=','checkdbversion=','updatelsnrendp=','updateasmcount=','modifyscan=','updateasmdevices=','getasmdiskgroup=','getasmdisks=','getdgredundancy=','getasminstname=','getasminststatus=','rundatapatch=','ons=','updatesidprofile=','updatecdp='])
   except getopt.GetoptError as ex:
      parse_error = str(ex)

   # Initializing oraenv instance
   oenv=OraEnv()
   oenv.preload_log_path_vars()
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

   if parse_error is not None:
      ocommon.log_error_message(
         "Invalid command-line argument: {0}. Refusing to run full setup.".format(parse_error),
         file_name,
      )
      sys.exit(2)

   if args:
      ocommon.log_error_message(
         "Unexpected positional arguments: {0}. Refusing to run full setup.".format(" ".join(args)),
         file_name,
      )
      sys.exit(2)

   if sys.argv[1:] and not opts:
      ocommon.log_error_message(
         "No valid command-line option provided. Refusing to run full setup.",
         file_name,
      )
      sys.exit(2)

   def update_logfile(log_key):
      lf = oenv.logfile_name(log_key)
      oralogger.filename_ = lf
      ocommon.log_info_message("=======================================================================", lf)
      return lf

   def set_miscops_op_type(add_if_missing=True):
      if ocommon.check_key("OP_TYPE", oenv.get_env_dict()):
         oenv.update_key("OP_TYPE", "miscops")
      elif add_if_missing:
         oenv.add_custom_variable("OP_TYPE", "miscops")

   miscops_opt_map = {
      '--checkracinst': ("CHECK_RAC_INST", "CHECK_RAC_INST", True, True, True),
      '--checkgilocal': ("CHECK_GI_LOCAL", "CHECK_GI_LOCAL", True, True, True),
      '--checkracdb': ("CHECK_RAC_DB", "CHECK_RAC_DB", True, True, True),
      '--checkracstatus': ("CHECK_RAC_STATUS", "CHECK_RAC_STATUS", False, True, True),
      '--checkdbrole': ("CHECK_DB_ROLE", "CHECK_DB_ROLE", True, True, True),
      '--checkconnstr': ("CHECK_CONNECT_STR", "CHECK_CONNECT_STR", True, True, True),
      '--checkpdbconnstr': ("CHECK_PDB_CONNECT_STR", "CHECK_PDB_CONNECT_STR", True, True, True),
      '--setupdblsnr': ("SETUP_DB_LSNR", "NEW_DB_LSNR_ENDPOINTS", True, False, False),
      '--setuplocallsnr': ("SETUP_LOCAL_LSNR", "NEW_LOCAL_LISTENER", True, True, False),
      '--checkdbsvc': ("CHECK_DB_SVC", "CHECK_DB_SVC", True, True, True),
      '--modifydbsvc': ("MODIFY_DB_SVC", "MODIFY_DB_SVC", True, True, False),
      '--checkdbversion': ("CHECK_DB_VERSION", "CHECK_DB_VERSION", True, True, True),
      '--modifyscan': ("MODIFY_SCAN", "MODIFY_SCAN", True, True, False),
      '--updateasmcount': ("UPDATE_ASMCOUNT", "UPDATE_ASMCOUNT", True, True, False),
      '--updateasmdevices': ("UPDATE_ASMDEVICES", "UPDATE_ASMDEVICES", True, True, False),
      '--getasmdiskgroup': ("LIST_ASMDG", "LIST_ASMDG", True, True, True),
      '--getasmdisks': ("LIST_ASMDISKS", "LIST_ASMDISKS", True, True, True),
      '--getdgredundancy': ("LIST_ASMDGREDUNDANCY", "LIST_ASMDGREDUNDANCY", True, True, True),
      '--getasminstname': ("LIST_ASMINSTNAME", "LIST_ASMINSTNAME", True, True, True),
      '--getasminststatus': ("LIST_ASMINSTSTATUS", "LIST_ASMINSTSTATUS", True, True, True),
      '--updatelsnrendp': ("UPDATE_LISTENERENDP", "UPDATE_LISTENERENDP", True, True, False),
      '--updatecdp': ("UPDATE_CDP", "UPDATE_CDP", True, True, False),
      '--rundatapatch': ("RUN_DATAPATCH", "RUN_DATAPATCH", True, True, False),
      '--ons': ("ONS", "ONS", True, True, False),
      '--updatesidprofile': ("SIDPROFILEUPDATE", "SID_PROFILE_UPDATE", True, True, False),
   }

   quiet_custom_run = False
   selected_miscops_opts = [opt for opt, arg in opts if opt in miscops_opt_map]
   if selected_miscops_opts:
      quiet_custom_run = all(miscops_opt_map[opt][4] for opt in selected_miscops_opts)
      if quiet_custom_run:
         oenv.add_custom_variable("QUIET_CUSTOM_RUN", "true")
         oralogger.set_stdout_enabled(False)

   for opt, arg in opts:
      if opt in ('--help'):
         oralogger.msg_ = '''{:^17}-{:^17} : You can pass parameter --help'''
         stdout_handler.handle(oralogger)
         return
      elif opt in ('--resetpassword'):
         file_name = update_logfile("RESET_PASSWORD")
         oenv.add_custom_variable("RESET_PASSWORD",arg)
      elif opt in ('--delracnode'):
         file_name = update_logfile("DEL_PARAMS")
         oenv.add_custom_variable("DEL_PARAMS",arg)
         oenv.add_custom_variable("CUSTOM_RUN_FLAG","true")
         oenv.add_custom_variable("DEL_RACHOME","true")
         oenv.add_custom_variable("DEL_GIHOME","true")
         if ocommon.check_key("OP_TYPE",oenv.get_env_dict()):
            oenv.update_key("OP_TYPE","racdelnode")
         else:
            oenv.add_custom_variable("OP_TYPE","miscops")
      elif opt in ('--addtns'):
         file_name = update_logfile("ADD_TNS")
         oenv.add_custom_variable("TNS_PARAMS",arg)
         oenv.add_custom_variable("CUSTOM_RUN_FLAG","true")
         if ocommon.check_key("OP_TYPE",oenv.get_env_dict()):
            oenv.update_key("OP_TYPE","racdelnode")
         else:
            oenv.add_custom_variable("OP_TYPE","miscops")
      elif opt in miscops_opt_map:
         log_key, env_key, use_arg, add_if_missing, quiet_op = miscops_opt_map[opt]
         file_name = update_logfile(log_key)
         if use_arg:
            oenv.add_custom_variable(env_key,arg)
         else:
            oenv.add_custom_variable(env_key,"true")
         oenv.add_custom_variable("CUSTOM_RUN_FLAG","true")
         set_miscops_op_type(add_if_missing)
      else:
         pass

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
    main()
