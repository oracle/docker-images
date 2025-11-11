#!/usr/bin/python

#############################
# Copyright 2021-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file contains to the code call different classes objects based on setup type
"""

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oraracadd import *

import os
import sys

class OraAsmca:
   """
   This class performs the ASMCA operations
   """
   def __init__(self,oralogger,orahandler,oraenv,oracommon,oracvu,orasetupssh):
      try:
         self.ologger             = oralogger
         self.ohandler            = orahandler
         self.oenv                = oraenv.get_instance()
         self.ocommon             = oracommon
         self.ocvu                = oracvu
         self.orasetupssh         = orasetupssh
         self.ora_env_dict        = oraenv.get_env_vars()
         self.file_name           = os.path.basename(__file__)
      except BaseException as ex:
         ex_type, ex_value, ex_traceback = sys.exc_info()
         trace_back = traceback.extract_tb(ex_traceback)
         stack_trace = list()
         for trace in trace_back:
             stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1], trace[2], trace[3]))
         self.ocommon.log_info_message(ex_type.__name__,self.file_name)
         self.ocommon.log_info_message(ex_value,self.file_name)
         self.ocommon.log_info_message(stack_trace,self.file_name)

   def setup(self):
       """
       This function setup the grid on this machine
       """
       pass

   def validate_dg(self,device_list,device_prop,type):
       """
        Check dg if it exist
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       device_prop,cname,cred,casm,crdbms,asdvm,cuasize=self.get_device_prop(device_prop,type)
       self.ocommon.log_info_message("device prop set to :" + device_prop + " DG Name: " + cname + " Redundancy : " + cred, self.file_name)
       cmd='''su - {0} -c "{1}/bin/asmcmd lsdg {2}"'''.format(giuser,gihome,cname)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)
       if self.ocommon.check_substr_match(output,cname):
          return True
       else:
          return False  
        
   def create_dg(self,device_list,device_prop,type):
       """
       This function creates the disk group
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       disk_lst=self.get_device_list(device_list) 
       self.ocommon.log_info_message("The type is set to :" + type,self.file_name)
       device_prop,cname,cred,casm,crdbms,asdvm,cuasize=self.get_device_prop(device_prop,type)
       self.ocommon.log_info_message("device prop set to :" + device_prop + " DG Name: " + cname + " Redundancy : " + cred, self.file_name) 
       cmd='''su - {0} -c "{1}/bin/asmca -silent -createDiskGroup {3} {2}"'''.format(giuser,gihome,disk_lst,device_prop)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,True)
 
   def get_device_list(self,device_list):
       """
       This function returns the device_list
       """
       disklst=""
       for disk in device_list.split(','):
           disklst +=""" -disk '{0}'""".format(disk)

       if disklst:
         return disklst     
       else:
        self.ocommon.log_error_message("disk string is set to None for diskgroup creation. Exiting..",self.file_name)
        self.prog_exit("127")

   def get_device_prop(self,device_prop,type):
       """
       This function returns the device_props
       """
       cname=""
       cred=""
       casm=""
       crdbms=""
       cadvm=""
       causize=""
       cmd=""

       self.ocommon.log_info_message("The type is set to :" + type,self.file_name) 
       if device_prop:
          cvar_dict=dict(item.split(":") for item in device_prop.split(";")) 
          for ckey in cvar_dict.keys():
              if ckey == 'name':
                 cname = cvar_dict[ckey]
              if ckey == 'redundancy':
                 cred = cvar_dict[ckey]
              if ckey == 'compatibleasm':
                 casm = cvar_dict[ckey]
              if ckey == 'compatiblerdbms':
                 crdbms = cvar_dict[ckey]
              if ckey ==  'compatibleadvm':
                 cadvm = cvar_dict[ckey]
              if ckey == 'au_size':
                 causize = cvar_dict[ckey]

       if not cname: 
          cmd +='''  -diskGroupName  {0}'''.format(type)
          cname=type
       else:
          cmd +='''  -diskGroupName  {0}'''.format(cname)
       if not cred:
          cmd +='''  -redundancy {0}'''.format("EXTERNAL")
          cred="EXTERNAL"
       else:
          cmd +='''  -redundancy {0}'''.format(cred)
       if casm:
          cmd +=""" -compatible.asm  '{0}'""".format(casm)
       if crdbms:
          cmd +=""" -compatible.rdbms '{0}'""".format(crdbms) 
       if cadvm:
          cmd +=""" -compatible.advm '{0}'""".format(cadvm)
       if causize:
          cmd +=""" -au_size '{0}'""".format(causize) 
          
       if cmd:     
         return cmd,cname,cred,casm,crdbms,cadvm,causize
       else:
        self.ocommon.log_error_message("CMD is set to None for diskgroup creation. Exiting..",self.file_name)
        self.ocommon.prog_exit("127")  
