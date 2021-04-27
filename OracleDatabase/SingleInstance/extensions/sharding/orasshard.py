#!/usr/bin/python

#############################
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################


import os
import sys
import os.path
import re
import socket
from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
import traceback

class OraSShard:
      """
      This calss setup the standby shard after DB installation.
      """
      def __init__(self,oralogger,orahandler,oraenv,oracommon):
        """
        This constructor of OraSShard class to setup the shard on standby DB.

        Attributes:
           oralogger (object): object of OraLogger Class.
           ohandler (object): object of Handler class.
           oenv (object): object of singleton OraEnv class.
           ocommon(object): object of OraCommon class.
           ora_env_dict(dict): Dict of env variable populated based on env variable for the setup.
           file_name(string): Filename from where logging message is populated.
        """
        try:
          self.ologger             = oralogger
          self.ohandler            = orahandler
          self.oenv                = oraenv.get_instance()
          self.ocommon             = oracommon
          self.ora_env_dict        = oraenv.get_env_vars()
          self.file_name           = os.path.basename(__file__)
          self.omachine            = OraMachine(self.ologger,self.ohandler,self.oenv,self.ocommon)
        except BaseException as ex:
          ex_type, ex_value, ex_traceback = sys.exc_info()
          trace_back = traceback.extract_tb(ex_traceback)
          stack_trace = list()
          for trace in trace_back:
              stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1], trace[2], trace[3]))
          ocommon.log_info_message(ex_type.__name__,self.file_name)
          ocommon.log_info_message(ex_value,self.file_name)
          ocommon.log_info_message(stack_trace,self.file_name)
      def setup(self):
          """
           This function setup the shard on standby DB.
          """
          pass
