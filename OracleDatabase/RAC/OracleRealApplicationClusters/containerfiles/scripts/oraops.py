#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
############################

"""
Shared operation orchestration primitives for Phase-2 refactor.

This module is intentionally lightweight and behavior-preserving:
- CommandBuilder centralizes command-string creation.
- OperationRunner centralizes step execution/logging wrappers.
"""


class CommandBuilder:
    """
    Centralized command construction for installer/database operations.
    """

    def __init__(self, ocommon):
        self.ocommon = ocommon

    def build_gi_addnode(self, gridrsp, node):
        """
        Build GI addnode software command.
        """
        return self.ocommon.get_sw_cmd("ADDNODE", gridrsp, node, None)

    def build_rac_addnode(self, dbuser, dbhome, crs_nodes, copyflag, node):
        """
        Build RAC DB home addnode command.
        """
        return '''su - {0} -c "ssh -vvv {4} 'sh {1}/addnode/addnode.sh \"CLUSTER_NEW_NODES={{{2}}}\"  -waitForCompletion  {3} -silent'"'''.format(
            dbuser, dbhome, crs_nodes, copyflag, node
        )

    def build_rac_add_instance(self, dbuser, dbhome, node, new_node, osid):
        """
        Build RAC DBCA add-instance command.
        """
        return '''su - {0} -c "ssh {2} '{1}/bin/dbca -addInstance -silent  -nodeName {3} -gdbName {4}'"'''.format(
            dbuser, dbhome, node, new_node, osid
        )


    def build_rac_delete_instance(self, dbuser, dbhome, dbname, inst_sid, node, hostname):
        """
        Build RAC DBCA delete-instance command.
        """
        return '''su - {0} -c "ssh {4} '{1}/bin/dbca -silent -ignorePrereqFailure -deleteInstance -gdbName {2} -nodeName {5} -instanceName {3}'"'''.format(
            dbuser, dbhome, dbname, inst_sid, node, hostname
        )

    def build_gi_delete_node(self, giuser, gihome, node, hostname):
        """
        Build GI CRS delete-node command.
        """
        return '''su - {0} -c "ssh {2} '/bin/sudo {1}/bin/crsctl delete node -n {3}'"'''.format(
            giuser, gihome, node, hostname
        )

    def build_remote_sudo(self, user, node, command):
        """
        Build a generic remote sudo command over SSH.
        """
        return '''su - {0} -c "ssh {1} sudo {2}"'''.format(user, node, command)

    def build_gi_postroot_config(self, giuser, gihome, gridrsp):
        """
        Build GI executeConfigTools command.
        """
        return '''su - {0} -c "{1}/gridSetup.sh -executeConfigTools -responseFile {2} -silent"'''.format(
            giuser, gihome, gridrsp
        )

    def build_gi_install_cvuqdisk(self, giuser, node, rpm_directory):
        """
        Build cvuqdisk installation command for a node.
        """
        return '''su - {0} -c "ssh {1} 'sudo rpm -Uvh {2}/cvuqdisk-*.rpm'"'''.format(
            giuser, node, rpm_directory
        )

class OperationRunner:
    """
    Shared step runner with consistent operation lifecycle logging.
    """

    def __init__(self, ocommon, file_name, component="OPS"):
        self.ocommon = ocommon
        self.file_name = file_name
        self.component = component

    def run_step(self, action, fn, *args, **kwargs):
        """
        Execute a callable while emitting standardized start/end step logs.
        """
        self.ocommon.log_step(self.component, action, "start", None, self.file_name)
        result = fn(*args, **kwargs)
        self.ocommon.log_step(self.component, action, "end", None, self.file_name)
        return result

    def run_command(self, action, cmd, env=None, cwd=None, exit_on_error=None):
        """
        Execute shell command via OraCommon and apply standard error checks.
        """
        self.ocommon.log_step(self.component, action, "command", cmd, self.file_name)
        output, error, retcode = self.ocommon.execute_cmd(cmd, env, cwd)
        self.ocommon.check_os_err(output, error, retcode, exit_on_error)
        return output, error, retcode
