#!/usr/bin/python

#############################
# Copyright 2021-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
This file contains ASMCA helper code for ASM disk group operations.
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
import traceback


class OraAsmca:
   """
   This class performs ASMCA operations.
   """

   def __init__(self, oralogger, orahandler, oraenv, oracommon, oracvu, orasetupssh):
      try:
         self.ologger = oralogger
         self.ohandler = orahandler
         self.oenv = oraenv.get_instance()
         self.ocommon = oracommon
         self.ocvu = oracvu
         self.orasetupssh = orasetupssh
         self.ora_env_dict = oraenv.get_env_vars()
         self.file_name = os.path.basename(__file__)
      except BaseException as ex:
         ex_type, ex_value, ex_traceback = sys.exc_info()
         trace_back = traceback.extract_tb(ex_traceback)
         stack_trace = list()
         for trace in trace_back:
            stack_trace.append(
               "File : %s , Line : %d, Func.Name : %s, Message : %s"
               % (trace[0], trace[1], trace[2], trace[3])
            )
         self.ocommon.log_info_message(ex_type.__name__, self.file_name)
         self.ocommon.log_info_message(ex_value, self.file_name)
         self.ocommon.log_info_message(stack_trace, self.file_name)

   def setup(self):
       """
       Placeholder for class-level setup hooks.
       """
       pass

   def _get_gi_user_home(self):
       """
       Return GI user and GI home values.
       """
       giuser, gihome, gbase, oinv = self.ocommon.get_gi_params()
       return giuser, gihome

   def _parse_device_prop(self, device_prop):
       """
       Parse device property string into a dictionary.
       """
       prop_dict = {}
       if not device_prop:
          return prop_dict

       for item in device_prop.split(";"):
          entry = item.strip()
          if not entry:
             continue
          if ":" not in entry:
             self.ocommon.log_error_message(
                "Invalid device property entry: " + entry + ". Expected key:value format.",
                self.file_name,
             )
             self.ocommon.prog_exit("127")

          key, value = entry.split(":", 1)
          prop_dict[key.strip().lower()] = value.strip()

       return prop_dict

   def _log_dg_props(self, cmd_prop, dg_name, dg_redundancy):
       """
       Log the resolved disk group properties.
       """
       self.ocommon.log_info_message(
          "Device properties: " + cmd_prop + " DG Name: " + dg_name + " Redundancy: " + dg_redundancy,
          self.file_name,
       )

   def validate_dg(self, device_list, device_prop, type):
       """
       Check whether a disk group exists.
       """
       giuser, gihome = self._get_gi_user_home()
       cmd_prop, dg_name, dg_redundancy, casm, crdbms, cadvm, causize = self.get_device_prop(device_prop, type)
       self._log_dg_props(cmd_prop, dg_name, dg_redundancy)

       cmd = '''su - {0} -c "{1}/bin/asmcmd lsdg {2}"'''.format(giuser, gihome, dg_name)
       output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
       self.ocommon.check_os_err(output, error, retcode, None)
       return self.ocommon.check_substr_match(output, dg_name)

   def create_dg(self, device_list, device_prop, type):
       """
       Create a disk group.
       """
       giuser, gihome = self._get_gi_user_home()
       disk_lst = self.get_device_list(device_list)
       self.ocommon.log_info_message("Disk group type is set to: " + type, self.file_name)
       cmd_prop, dg_name, dg_redundancy, casm, crdbms, cadvm, causize = self.get_device_prop(device_prop, type)
       self._log_dg_props(cmd_prop, dg_name, dg_redundancy)

       cmd = '''su - {0} -c "{1}/bin/asmca -silent -createDiskGroup {3} {2}"'''.format(
          giuser, gihome, disk_lst, cmd_prop
       )
       output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
       self.ocommon.check_os_err(output, error, retcode, True)

   def get_device_list(self, device_list):
       """
       Return ASMCA disk list arguments.
       """
       if not device_list:
          self.ocommon.log_error_message(
             "Disk string is not set for disk group creation. Exiting...",
             self.file_name,
          )
          self.ocommon.prog_exit("127")

       disklst = ""
       for disk in device_list.split(","):
           disk_name = disk.strip()
           if disk_name:
              disklst += " -disk '{0}'".format(disk_name)

       if disklst:
          return disklst

       self.ocommon.log_error_message(
          "Disk string is not set for disk group creation. Exiting...",
          self.file_name,
       )
       self.ocommon.prog_exit("127")

   def get_device_prop(self, device_prop, type):
       """
       Return ASMCA command properties and resolved values.
       """
       dg_name = ""
       dg_redundancy = ""
       compatible_asm = ""
       compatible_rdbms = ""
       compatible_advm = ""
       au_size = ""
       cmd = ""

       self.ocommon.log_info_message("Disk group type is set to: " + type, self.file_name)
       prop_dict = self._parse_device_prop(device_prop)

       if "name" in prop_dict:
          dg_name = prop_dict["name"]
       if "redundancy" in prop_dict:
          dg_redundancy = prop_dict["redundancy"]
       if "compatibleasm" in prop_dict:
          compatible_asm = prop_dict["compatibleasm"]
       if "compatiblerdbms" in prop_dict:
          compatible_rdbms = prop_dict["compatiblerdbms"]
       if "compatibleadvm" in prop_dict:
          compatible_advm = prop_dict["compatibleadvm"]
       if "au_size" in prop_dict:
          au_size = prop_dict["au_size"]

       if not dg_name:
          cmd += '''  -diskGroupName  {0}'''.format(type)
          dg_name = type
       else:
          cmd += '''  -diskGroupName  {0}'''.format(dg_name)

       if not dg_redundancy:
          cmd += '''  -redundancy {0}'''.format("EXTERNAL")
          dg_redundancy = "EXTERNAL"
       else:
          cmd += '''  -redundancy {0}'''.format(dg_redundancy)

       if compatible_asm:
          cmd += " -compatible.asm  '{0}'".format(compatible_asm)
       if compatible_rdbms:
          cmd += " -compatible.rdbms '{0}'".format(compatible_rdbms)
       if compatible_advm:
          cmd += " -compatible.advm '{0}'".format(compatible_advm)
       if au_size:
          cmd += " -au_size '{0}'".format(au_size)

       if cmd:
          return cmd, dg_name, dg_redundancy, compatible_asm, compatible_rdbms, compatible_advm, au_size

       self.ocommon.log_error_message(
          "ASMCA command properties are empty for disk group creation. Exiting...",
          self.file_name,
       )
       self.ocommon.prog_exit("127")
