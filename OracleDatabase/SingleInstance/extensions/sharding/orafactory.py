#!/usr/bin/python

#############################
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
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
from orapshard import *
from orasshard import *
from orapcatalog import *
from oragsm import *

import os
import sys

class OraFactory:
    """ 
    This is a class for calling child objects to setup RAC/DG/GRID/DB/Sharding based on OP_TYPE env variable.
      
    Attributes: 
        oralogger (object): object of OraLogger Class.
        ohandler (object): object of Handler class.
        oenv (object): object of singleton OraEnv class.
        ocommon(object): object of OraCommon class.
        ora_env_dict(dict): Dict of env variable populated based on env variable for the setup.
        file_name(string): Filename from where logging message is populated. 
    """
    def __init__(self,oralogger,orahandler,oraenv,oracommon):
        """
        This is a class for calling child objects to setup RAC/DG/GRID/DB/Sharding based on OP_TYPE env variable.
    
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
 
    def get_ora_objs(self):
        '''
        Return the instance of a classes which will setup the enviornment.

        Returns:
         ofactory_obj: List of objects  
        '''  
        ofactory_obj = []

        msg='''ora_env_dict set to : {0}'''.format(self.ora_env_dict)
        self.ocommon.log_info_message(msg,self.file_name) 

        msg="Checking the OP_TYPE and Version to begin the installation"
        self.ocommon.log_info_message(msg,self.file_name)

        # Checking the OP_TYPE
        if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
           msg='''OP_TYPE variable is set to {0}.'''.format(self.ora_env_dict["OP_TYPE"])
           self.ocommon.log_info_message(msg,self.file_name)
        else:
           self.ora_env_dict=self.ocommon.add_key("OP_TYPE","nosetup",self.ora_env_dict)
           msg="OP_TYPE variable is set to default nosetup. No value passed as an enviornment variable."
           self.ocommon.log_info_message(msg,self.file_name)
            
        # Check the OP_TYPE value and call objects based on it value
        if self.ora_env_dict["OP_TYPE"] == 'primaryshard':
           msg="Creating and calling instance to setup primary shard"
           opshard = OraPShard(self.ologger,self.ohandler,self.oenv,self.ocommon)
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(opshard)
        elif self.ora_env_dict["OP_TYPE"] == 'standbyshard':
           msg="Creating and calling instance to setup standby shard"
           osshard = OraSShard(self.ologger,self.ohandler,self.oenv,self.ocommon)
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(osshard)
        elif self.ora_env_dict["OP_TYPE"] == 'catalog':
           msg="Creating and calling instance to setup Catalog DB"
           opcat = OraPCatalog(self.ologger,self.ohandler,self.oenv,self.ocommon)
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(opcat)
        elif self.ora_env_dict["OP_TYPE"] == 'standbycatalog':
           msg="Creating and calling instance to setup Catalog DB"
           oscat = OraSShard(self.ologger,self.ohandler,self.oenv,self.ocommon)
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(oscat)
        elif self.ora_env_dict["OP_TYPE"] == 'gsm':
           msg="Creating and calling instance to setup GSM"
           ogsm = OraGSM(self.ologger,self.ohandler,self.oenv,self.ocommon)
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(ogsm)
        else:
           msg="OP_TYPE must be set to {primaryshard|standbyshard|catalog|standbycatalog|gsm}"
           self.ocommon.log_info_message(msg,self.file_name)
           msg="Since OP_TYPE is set to nosetup, only compute env is being setup. Creating and calling instance to setup compute."
           self.ocommon.log_info_message(msg,self.file_name)
           omachine = OraMachine(self.ologger,self.ohandler,self.oenv,self.ocommon)
           ofactory_obj.append(omachine)

        return ofactory_obj
