#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file contains code that calls different class objects based on setup type
"""

import os
import sys
import re
sys.path.insert(0, "/opt/scripts/startup/scripts")


from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from oragiprov import *
from oragiadd import *
from orasshsetup import *
from oraracadd import *
from oraracprov import *
from oraracdel import *
from oramiscops import *


class OraFactory:
    """
    This is a class for calling child objects to setup RAC/DG/GRID/DB/Sharding based on OP_TYPE env variable.
    """

    def __init__(self, oralogger, orahandler, oraenv, oracommon):
        """
        Initialize factory context and shared helper objects.
        """
        self.ologger = oralogger
        self.ohandler = orahandler
        self.oenv = oraenv.get_instance()
        self.ocommon = oracommon
        self.ocvu = OraCvu(self.ologger, self.ohandler, self.oenv, self.ocommon)
        self.osetupssh = OraSetupSSH(self.ologger, self.ohandler, self.oenv, self.ocommon)
        self.ora_env_dict = oraenv.get_env_vars()
        self.file_name = os.path.basename(__file__)

    def _append_miscops_obj(self, ofactory_obj):
        msg = "Creating and calling instance to perform miscellaneous operations"
        oramops = OraMiscOps(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh)
        self.ocommon.log_info_message(msg, self.file_name)
        ofactory_obj.append(oramops)

    def _detect_grid_rsp_version(self):
        """
        Detect GI response-file version (defaults to 0 when not available).
        """
        version = 0
        if not self.ocommon.check_key("GRID_RESPONSE_FILE", self.ora_env_dict):
            return version

        gridrsp = self.ora_env_dict["GRID_RESPONSE_FILE"]
        self.ocommon.log_info_message(
            "GRID_RESPONSE_FILE parameter is set and file location is:" + gridrsp,
            self.file_name,
        )

        if not os.path.isfile(gridrsp):
            return version

        with open(gridrsp) as fp:
            for line in fp:
                if len(line.split("=")) != 2:
                    continue
                key = (line.split("=")[0]).strip()
                value = (line.split("=")[1]).strip()
                self.ocommon.log_info_message(
                    "KEY and Value pair set to: " + key + ":" + value,
                    self.file_name,
                )
                if key == "oracle.install.responseFileVersion":
                    match = re.search(r'v(\d{2})', value)
                    if match:
                        version = int(match.group(1))
                    else:
                        # Default to version 23 if no match is found
                        version = 23

        msg = "Version detected in response file is {0}".format(version)
        self.ocommon.log_info_message(msg, self.file_name)
        return version

    def _update_gi_env_by_version(self, version):
        """
        Update GI environment variables from the proper response-file parser.
        """
        if version in (19, 21):
            self.ocommon.update_pre_23c_gi_env_vars_from_rspfile()
        else:
            # Default to new format parser when response file is absent or version >= 23.
            self.ocommon.update_gi_env_vars_from_rspfile()

    def _build_primary_op_obj(self, op_type):
        """
        Build and return operation object + log message for supported OP_TYPE values.
        Returns (msg, obj) or (None, None) when unsupported.
        """
        setuprac_aliases = {
            'setuprac',
            'setuprac,catalog',
            'catalog,setuprac',
            'setuprac,primaryshard',
            'primaryshard,setuprac',
            'setuprac,standbyshard',
            'standbyshard,setuprac',
        }

        if op_type == 'setupgrid':
            return (
                "Creating and calling instance to provGrid",
                OraGIProv(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        if op_type in setuprac_aliases:
            return (
                "Creating and calling instance to prov RAC DB",
                OraRacProv(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        if op_type == 'setupssh':
            return (
                "Creating and calling instance to setup ssh between computes",
                self.osetupssh,
            )

        if op_type == 'setupracstandby':
            return (
                "Creating and calling instance to setup RAC standby database",
                OraRacStdby(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        if op_type == 'gridaddnode':
            return (
                "Creating and calling instance to add grid",
                OraGIAdd(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        if op_type == 'racaddnode':
            return (
                "Creating and calling instance to add RAC node",
                OraRacAdd(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        if op_type == 'setupenv':
            return (
                "Creating and calling instance to set up RAC environment",
                OraSetupEnv(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        if op_type == 'racdelnode':
            return (
                "Creating and calling instance to delete the rac node",
                OraRacDel(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh),
            )

        return None, None

    def get_ora_objs(self):
        """
        Return the class instances that will set up the environment.

        Returns:
            ofactory_obj: List of objects
        """
        ofactory_obj = []
        quiet_custom_run = (
            self.ocommon.check_key("CUSTOM_RUN_FLAG", self.ora_env_dict)
            and self.ocommon.check_key("QUIET_CUSTOM_RUN", self.ora_env_dict)
        )

        if quiet_custom_run:
            self.ocommon.log_info_message(
                "ora_env_dict initialized for quiet custom run",
                self.file_name,
            )
        else:
            msg = '''ora_env_dict set to : {0}'''.format(self.ora_env_dict)
            self.ocommon.log_info_message(msg, self.file_name)

        if not quiet_custom_run:
            msg = '''Adding machine setup object in orafactory'''
            self.ocommon.log_info_message(msg, self.file_name)
            omachine = OraMachine(self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh)
            self.ocommon.log_info_message(msg, self.file_name)
            ofactory_obj.append(omachine)
        else:
            self.ocommon.log_info_message(
                "Skipping machine setup object for quiet custom run",
                self.file_name,
            )

        msg = "Checking OP_TYPE and version to begin installation"
        self.ocommon.log_info_message(msg, self.file_name)

        # Preserve user-passed OP_TYPE in custom-run mode before env population.
        op_type = None
        if self.ocommon.check_key("CUSTOM_RUN_FLAG", self.ora_env_dict):
            if self.ocommon.check_key("OP_TYPE", self.ora_env_dict):
                op_type = self.ora_env_dict["OP_TYPE"]

        self.ocommon.populate_rac_env_vars(log_details=not quiet_custom_run)
        if self.ocommon.check_key("OP_TYPE", self.ora_env_dict):
            if op_type is not None:
                self.ocommon.update_key("OP_TYPE", op_type, self.ora_env_dict)
            msg = '''OP_TYPE variable is set to {0}.'''.format(self.ora_env_dict["OP_TYPE"])
            self.ocommon.log_info_message(msg, self.file_name)
        else:
            self.ora_env_dict = self.ocommon.add_key("OP_TYPE", "nosetup", self.ora_env_dict)
            msg = "OP_TYPE variable is set to default nosetup. No value passed as an environment variable."
            self.ocommon.log_info_message(msg, self.file_name)

        version = self._detect_grid_rsp_version()
        self._update_gi_env_by_version(version)

        install_node, pubhost = self.ocommon.get_installnode()
        op_type = self.ora_env_dict["OP_TYPE"]
        self.ora_env_dict = self.ocommon.validate_operation_env(op_type, self.ora_env_dict)

        if install_node.lower() == pubhost.lower():
            if op_type == 'miscops':
                self._append_miscops_obj(ofactory_obj)
            else:
                msg, op_obj = self._build_primary_op_obj(op_type)
                if op_obj is not None:
                    self.ocommon.log_info_message(msg, self.file_name)
                    ofactory_obj.append(op_obj)
                else:
                    msg = "OP_TYPE must be set to {setupgrid|setuprac|setupssh|setupracstandby|gridaddnode|racaddnode|setupenv|racdelnode|miscops}"
                    self.ocommon.log_info_message(msg, self.file_name)

        elif install_node.lower() != pubhost.lower() and self.ocommon.check_key("CUSTOM_RUN_FLAG", self.ora_env_dict):
            if op_type == 'miscops':
                self._append_miscops_obj(ofactory_obj)
        else:
            msg = "INSTALL_NODE {0} is not matching with the hostname {1}. Resetting OP_TYPE to nosetup.".format(
                install_node,
                pubhost,
            )
            self.ocommon.log_info_message(msg, self.file_name)
            self.ocommon.update_key("OP_TYPE", "nosetup", self.ora_env_dict)

        return ofactory_obj
