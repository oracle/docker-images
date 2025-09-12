#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
#############################

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *

import os
import sys

class OraMachine:
    """
     This calss setup the compute before starting the installation.
    """
    def __init__(self,oralogger,orahandler,oraenv,oracommon,oracvu,orasetupssh):
        """
        This constructor of OraMachine class to setup the compute 

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
        self.ocvu                = oracvu
        self.osetupssh           = orasetupssh
        self.osetupenv           = OraSetupEnv(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
    def setup(self):
        """
          This function setup the compute before starting the installation
        """
        self.ocommon.log_info_message("Start setup()",self.file_name)
        ct = datetime.datetime.now()
        bts = ct.timestamp()

        self.memory_check()
        self.osetupenv.setup()

        ct = datetime.datetime.now()
        ets = ct.timestamp()
        totaltime=ets - bts
        self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

    def memory_check(self):
        """
          This function check the memory available inside the container
        """
        pass 
