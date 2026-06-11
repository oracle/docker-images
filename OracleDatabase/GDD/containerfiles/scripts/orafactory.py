#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

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

    def _build_factory(self, obj_cls):
        """
        Build target setup object with common constructor dependencies.
        """
        return obj_cls(self.ologger,self.ohandler,self.oenv,self.ocommon)

    def _get_or_set_op_type(self):
        """
        Return configured OP_TYPE, defaulting to 'nosetup' when absent.
        """
        if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
           op_type = self.ora_env_dict["OP_TYPE"]
           msg='''OP_TYPE variable is set to {0}.'''.format(op_type)
           self.ocommon.log_info_message(msg,self.file_name)
           return op_type

        self.ora_env_dict = self.ocommon.add_key("OP_TYPE","nosetup",self.ora_env_dict)
        msg="OP_TYPE variable is set to default nosetup. No value passed as an enviornment variable."
        self.ocommon.log_info_message(msg,self.file_name)
        return self.ora_env_dict["OP_TYPE"]
 
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

        op_type = self._get_or_set_op_type()

        op_type_to_builder = {
           "primaryshard": (OraPShard, "Creating and calling instance to setup primary shard"),
           "setuprac,primaryshard": (OraPShard, "Creating and calling instance to setup primary shard"),
           "primaryshard,setuprac": (OraPShard, "Creating and calling instance to setup primary shard"),
           "standbyshard": (OraSShard, "Creating and calling instance to setup standby shard"),
           "setuprac,standbyshard": (OraSShard, "Creating and calling instance to setup standby shard"),
           "standbyshard,setuprac": (OraSShard, "Creating and calling instance to setup standby shard"),
           "catalog": (OraPCatalog, "Creating and calling instance to setup Catalog DB"),
           "setuprac,catalog": (OraPCatalog, "Creating and calling instance to setup Catalog DB"),
           "catalog,setuprac": (OraPCatalog, "Creating and calling instance to setup Catalog DB"),
           "standbycatalog": (OraSShard, "Creating and calling instance to setup Catalog DB"),
           "gsm": (OraGSM, "Creating and calling instance to setup GSM"),
        }

        if op_type in op_type_to_builder:
           obj_cls, msg = op_type_to_builder[op_type]
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(self._build_factory(obj_cls))
        else:
           msg="OP_TYPE must be set to {primaryshard|standbyshard|catalog|standbycatalog|gsm}"
           self.ocommon.log_info_message(msg,self.file_name)
           msg="Since OP_TYPE is set to nosetup, only compute env is being setup. Creating and calling instance to setup compute."
           self.ocommon.log_info_message(msg,self.file_name)
           ofactory_obj.append(self._build_factory(OraMachine))

        return ofactory_obj
