#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
This file contains GI add-node workflow logic for SSH, CVU, and addnode config.
"""

import os
import sys
import traceback
import datetime

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oracvu import *
from oragiprov import *
from oraops import OperationRunner, CommandBuilder


class OraGIAdd:
    """
    This class performs GI add-node checks and operations
    """

    def __init__(self, oralogger, orahandler, oraenv, oracommon, oracvu, orasetupssh):
        try:
            self.ologger = oralogger
            self.ohandler = orahandler
            self.oenv = oraenv.get_instance()
            self.ocommon = oracommon
            self.ora_env_dict = oraenv.get_env_vars()
            self.file_name = os.path.basename(__file__)
            self.ocvu = oracvu
            self.osetupssh = orasetupssh
            self.ogiprov = OraGIProv(
                self.ologger, self.ohandler, self.oenv, self.ocommon, self.ocvu, self.osetupssh)
            self.op_runner = OperationRunner(self.ocommon, self.file_name, "GI")
            self.cmd_builder = CommandBuilder(self.ocommon)

        except BaseException as ex:
            traceback.print_exc(file=sys.stdout)

    def setup(self):
        """
        Set up GI add-node workflow on this machine.
        """
        self.ocommon.log_step("GI", "setup", "start", None, self.file_name)
        ct = datetime.datetime.now()
        bts = ct.timestamp()
        giuser, gihome, obase, invloc = self.ocommon.get_gi_params()
        pubhostname = self.ocommon.get_public_hostname()
        retcode1 = self.ocvu.check_home(pubhostname, gihome, giuser)
        if retcode1 == 0:
            bstr = "Grid home is already installed on this machine"
            self.ocommon.log_info_message(
                self.ocommon.print_banner(bstr), self.file_name)
        if self.ocommon.check_key("GI_HOME_INSTALLED_FLAG", self.ora_env_dict):
            bstr = "Grid is already configured on this machine"
            self.ocommon.log_info_message(
                self.ocommon.print_banner(bstr), self.file_name)
        else:
            self.env_param_checks()
            self.ocommon.log_step("GI", "perform_ssh_setup", "start", None, self.file_name)
            self.perform_ssh_setup()
            self.ocommon.log_step("GI", "perform_ssh_setup", "end", None, self.file_name)
            if self.ocommon.check_key("COPY_GRID_SOFTWARE", self.ora_env_dict):
                self.ocommon.log_step("GI", "crs_sw_install", "start", None, self.file_name)
                self.ogiprov.crs_sw_install()
                self.ocommon.log_step("GI", "crs_sw_install", "end", None, self.file_name)
                self.ogiprov.run_orainstsh()
                self.ocommon.log_info_message(
                    "Start ogiprov.run_rootsh()", self.file_name)
                self.ogiprov.run_rootsh()
                self.ocommon.log_info_message(
                    "End ogiprov.run_rootsh()", self.file_name)
            self.ocvu.check_addnode()
            self.ocommon.log_step("GI", "crs_sw_configure", "start", None, self.file_name)
            gridrsp = self.crs_sw_configure()
            self.ocommon.log_step("GI", "crs_sw_configure", "end", None, self.file_name)
            self.run_orainstsh()
            self.ocommon.log_step("GI", "run_rootsh", "start", None, self.file_name)
            self.run_rootsh()
            self.ocommon.log_step("GI", "run_rootsh", "end", None, self.file_name)
            pub_nodes, vip_nodes, priv_nodes = self.ocommon.process_cluster_vars(
                "CRS_NODES")
            crs_nodes = pub_nodes.replace(" ", ",")
            for node in crs_nodes.split(","):
                self.clu_checks(node)
            if self.ocommon.detect_k8s_env():
                self.ocommon.run_custom_scripts(
                    "CUSTOM_GRID_SCRIPT_DIR", "CUSTOM_GRID_SCRIPT_FILE", giuser)
                self.ocommon.update_scan(giuser, gihome, None, pubhostname)
                self.ocommon.start_scan(giuser, gihome, pubhostname)
                self.ocommon.update_scan_lsnr(giuser, gihome, pubhostname)
                self.ocommon.start_scan_lsnr(giuser, gihome, pubhostname)
                if self.ocommon.check_key("ADD_CDP", self.ora_env_dict):
                    self.ocommon.log_step("GI", "updatecdp", "start", None, self.file_name)
                    self.updatecdp(operation="ADDNODE")
                    self.ocommon.log_step("GI", "updatecdp", "end", None, self.file_name)


        ct = datetime.datetime.now()
        ets = ct.timestamp()
        totaltime = ets - bts
        self.ocommon.log_info_message(
            "Total time for setup() = [ " + str(round(totaltime, 3)) + " ] seconds", self.file_name)

    def env_param_checks(self):
        """
        Perform environment setup checks.
        """
        self.scan_check()
        self.ocommon.check_env_variable("GRID_HOME", True)
        self.ocommon.check_env_variable("GRID_BASE", True)
        self.ocommon.check_env_variable("INVENTORY", True)
#       self.ocommon.check_env_variable("ASM_DISCOVERY_DIR",None)

    def scan_check(self):
        """
        Check if scan is set
        """
        if self.ocommon.check_key("GRID_RESPONSE_FILE", self.ora_env_dict):
            self.ocommon.log_info_message(
                "GRID_RESPONSE_FILE is set. Skipping SCAN_NAME check because CVU validates the response file", self.file_name)
        else:
            if self.ocommon.check_key("SCAN_NAME", self.ora_env_dict):
                self.ocommon.log_info_message(
                    "SCAN_NAME variable is set: " + self.ora_env_dict["SCAN_NAME"], self.file_name)
                # ipaddr=self.ocommon.get_ip(self.ora_env_dict["SCAN_NAME"])
                # status=self.ocommon.validate_ip(ipaddr)
                # if status:
                #    self.ocommon.log_info_message("SCAN_NAME is a valid IP. Check passed...",self.file_name)
                # else:
                #    self.ocommon.log_error_message("SCAN_NAME is not a valid IP. Check failed. Exiting...",self.file_name)
                #    self.ocommon.prog_exit("127")
        # else:
        #    self.ocommon.log_error_message("SCAN_NAME is not set. Exiting...",self.file_name)
        #    self.ocommon.prog_exit("127")

    def clu_checks(self, hostname):
        """
        Perform cluster validation checks.
        """
        self.ocommon.log_info_message(
            "Performing CVU checks before DB home installation to make sure clusterware is up and running", self.file_name)
        retcode1 = self.ocvu.check_ohasd(hostname)
        retcode2 = self.ocvu.check_asm(hostname)
        retcode3 = self.ocvu.check_clu(hostname, None, None)

        if retcode1 == 0:
            msg = "Cluvfy ohasd check passed!"
            self.ocommon.log_info_message(msg, self.file_name)
        else:
            msg = "Cluvfy ohasd check failed. Exiting..."
            self.ocommon.log_error_message(msg, self.file_name)
            self.ocommon.prog_exit("127")

        if retcode2 == 0:
            msg = "Cluvfy asm check passed!"
            self.ocommon.log_info_message(msg, self.file_name)
        else:
            msg = "Cluvfy asm check failed. Exiting..."
            self.ocommon.log_error_message(msg, self.file_name)
            self.ocommon.prog_exit("127")

        if retcode3 == 0:
            msg = "Cluvfy clumgr check passed!"
            self.ocommon.log_info_message(msg, self.file_name)
        else:
            msg = "Cluvfy clumgr check failed. Exiting..."
            self.ocommon.log_error_message(msg, self.file_name)
            self.ocommon.prog_exit("127")

    def perform_ssh_setup(self):
        """
        Perform SSH setup.

        - Non-k8s:
            * Perform SSH setup (ADDNODE)
            * Verify SSH at the end

        - k8s:
            * SSH is assumed to be pre-configured
            * Only verify SSH connectivity to
            CRS nodes + EXISTING_CLS_NODE(s)
        """

        user = self.ora_env_dict["GRID_USER"]
        ohome = self.ora_env_dict["GRID_HOME"]

        giuser, gihome, _, _ = self.ocommon.get_gi_params()

        # --------------------------------------------------
        # Resolve CRS nodes (space-separated)
        # --------------------------------------------------
        cluster_nodes = self.ocommon.get_cluster_nodes() or ""
        cluster_nodes = cluster_nodes.replace(",", " ").split()

        # --------------------------------------------------
        # Resolve existing cluster nodes (may be None)
        # --------------------------------------------------
        existing_nodes = self.ocommon.get_existing_clu_nodes(False)
        if existing_nodes:
            existing_nodes = existing_nodes.replace(",", " ").split()
        else:
            existing_nodes = []

        # --------------------------------------------------
        # Merge + normalize node list
        # --------------------------------------------------
        all_nodes = sorted(set(cluster_nodes + existing_nodes))
        all_nodes_str = " ".join(all_nodes)

        # --------------------------------------------------
        # Determine GI version
        # --------------------------------------------------
        oraversion = self.ocommon.get_rsp_version("INSTALL", None)
        version = int(oraversion.split(".", 1)[0].strip())

        # --------------------------------------------------
        # Non-k8s: perform SSH setup
        # --------------------------------------------------
        if not self.ocommon.detect_k8s_env():
            self.ocommon.log_info_message(
                "Performing SSH setup for ADDNODE",
                self.file_name
            )

            self.osetupssh.setupssh(user, ohome, "ADDNODE")

        else:
            # --------------------------------------------------
            # k8s: setup already done, verify only
            # --------------------------------------------------
            self.ocommon.log_info_message(
                "k8s environment detected; skipping SSH setup and verifying connectivity only",
                self.file_name
            )

        # --------------------------------------------------
        # Final authoritative verification (common path)
        # --------------------------------------------------
        if all_nodes_str:
            self.ocommon.log_info_message(
                "Final SSH verification for nodes: {0}".format(all_nodes_str),
                self.file_name
            )

            self.osetupssh.verifyssh(
                giuser,
                gihome,
                "runcluvfy.sh",
                all_nodes_str,
                version
            )


    def _get_first_active_crs_node(self, existing_crs_nodes):
        """
        Return first cluster node where cluvfy clumgr passes.
        """
        return self.ocommon.get_first_active_crs_node(existing_crs_nodes, self.ocvu)

    def _validate_response_file(self, gridrsp):
        """
        Validate response file path and existence.
        """
        return self.ocommon.validate_response_file(gridrsp, "grid")

    def crs_sw_configure(self):
        """
        Perform CRS software add-node configuration across nodes.
        """
        ohome = self.ora_env_dict["GRID_HOME"]
        gridrsp = ""
        if self.ocommon.check_key("GRID_RESPONSE_FILE", self.ora_env_dict):
            gridrsp = self.check_responsefile()
        else:
            gridrsp = self.prepare_responsefile()
        existing_crs_nodes = self.ocommon.get_existing_clu_nodes(True)
        node = self._get_first_active_crs_node(existing_crs_nodes) or ""
        target_nodes = []
        crd_nodes = self.ocommon.get_crsnodes()
        for crs_node in crd_nodes.split(","):
            target_node = (crs_node.split(":"))[0].strip()
            self.ocommon.log_info_message("Target node set to: " +
                                  target_node, self.file_name)
            target_nodes.append(target_node)

        # self.ocvu.cluvfy_addnode(gridrsp,self.ora_env_dict["GRID_HOME"],self.ora_env_dict["GRID_USER"])
        if node:
            user = self.ora_env_dict["GRID_USER"]
            self.op_runner.run_step("scp_grid_rsp", self.ocommon.scpfile, node, gridrsp, gridrsp, user)
            status = self.ocommon.check_home_inv(None, ohome, user)
            if status:
                self.op_runner.run_step("sync_gi_home", self.ocommon.sync_gi_home, node, ohome, user, target_nodes)
            cmd = self.cmd_builder.build_gi_addnode(gridrsp, node)
            output, error, retcode = self.op_runner.run_command("gi_addnode", cmd, None, None, None)
            self.ocommon.check_crs_sw_install(output)
        else:
            self.ocommon.log_error_message(
                "Clusterware is not up on any node: " + existing_crs_nodes + ". Exiting...", self.file_name)
            self.ocommon.prog_exit("127")

        return gridrsp

    def check_responsefile(self):
        """
         Return the valid response file.
        """
        gridrsp = None
        if self.ocommon.check_key("GRID_RESPONSE_FILE", self.ora_env_dict):
            gridrsp = self.ora_env_dict["GRID_RESPONSE_FILE"]
            self.ocommon.log_info_message(
                "GRID_RESPONSE_FILE parameter is set. File location: " + gridrsp, self.file_name)

        return self._validate_response_file(gridrsp)

    def prepare_responsefile(self):
        """
        Prepare response file when none is provided.
        """
        self.ocommon.log_info_message(
            "Preparing Grid response file.", self.file_name)
        giuser, gihome, obase, invloc = self.ocommon.get_gi_params()
        # Variable Assignments
        # asmstr="/dev/asm*"
        x = datetime.datetime.now()
        rspdata = ""
        gridrsp = '''{1}/grid_addnode_{0}.rsp'''.format(
            x.strftime("%f"), "/tmp")
        clunodes = self.ocommon.get_crsnodes()
        existing_crs_nodes = self.ocommon.get_existing_clu_nodes(True)
        node = self._get_first_active_crs_node(existing_crs_nodes)

        if not node:
            self.ocommon.log_error_message(
                "Unable to find any healthy existing cluster node to verify cluster status. This can be an SSH issue or an unhealthy cluster.")
            self.ocommon.prog_exit("127")

        oraversion = self.ocommon.get_rsp_version("ADDNODE", node)

        version = oraversion.split(".", 1)[0].strip()
        if int(version) < 23:
            rspdata = '''
            oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{3} 
            oracle.install.option=CRS_ADDNODE
            ORACLE_BASE={0}
            INVENTORY_LOCATION={1}
            oracle.install.asm.OSDBA=asmdba
            oracle.install.asm.OSOPER=asmoper
            oracle.install.asm.OSASM=asmadmin
            oracle.install.crs.config.clusterNodes={2}
            oracle.install.crs.rootconfig.configMethod=ROOT
            oracle.install.asm.configureAFD=false
            oracle.install.crs.rootconfig.executeRootScript=false
            oracle.install.crs.configureRHPS=false
         '''.format(obase, invloc, clunodes, oraversion)

        elif int(version) == 26:
            rspdata = '''
            oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{3}
            oracle.install.option=CRS_ADDNODE
            ORACLE_BASE={0}
            INVENTORY_LOCATION={1}
            OSDBA=asmdba
            OSOPER=asmoper
            OSASM=asmadmin
            clusterNodes={2}
            configMethod=ROOT
            executeRootScript=false
         '''.format(obase, invloc, clunodes, oraversion)

        else:
            rspdata = '''
            oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{3}
            oracle.install.option=CRS_ADDNODE
            ORACLE_BASE={0}
            INVENTORY_LOCATION={1}
            OSDBA=asmdba
            OSOPER=asmoper
            OSASM=asmadmin
            clusterNodes={2}
            configMethod=ROOT
            executeRootScript=false
         '''.format(obase, invloc, clunodes, oraversion)
            major_ver, minor_ver = self.ocommon.get_ora_version()
            if int(minor_ver) < 9:
                rspdata += "configureAFD=false\n"
        self.ocommon.write_file(gridrsp, rspdata)
        return self._validate_response_file(gridrsp)

    def run_orainstsh(self):
        """
        Run orainstRoot.sh after grid setup.
        """
        giuser, gihome, gbase, oinv = self.ocommon.get_gi_params()
        pub_nodes, vip_nodes, priv_nodes = self.ocommon.process_cluster_vars(
            "CRS_NODES")
        for node in pub_nodes.split(" "):
            cmd = '''su - {0}  -c "ssh {1}  sudo {2}/orainstRoot.sh"'''.format(
                giuser, node, oinv)
            output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
            self.ocommon.check_os_err(output, error, retcode, True)

    def run_rootsh(self):
        """
        Run root.sh after grid setup.
        """
        giuser, gihome, gbase, oinv = self.ocommon.get_gi_params()
        pub_nodes, vip_nodes, priv_nodes = self.ocommon.process_cluster_vars(
            "CRS_NODES")
        for node in pub_nodes.split(" "):
            cmd = '''su - {0}  -c "ssh {1}  sudo {2}/root.sh"'''.format(
                giuser, node, gihome)
            output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
            self.ocommon.check_os_err(output, error, retcode, True)

    def updatecdp(self, operation):
        """
        Update CDP of existing RAC cluster
        """
        install_node,_=self.ocommon.get_installnode()
        retvalue = self.ocommon.update_cdp(operation,install_node)
        if not retvalue:
            self.ocommon.log_info_message(
                "Update CDP failed for the existing RAC cluster",
                self.file_name
            )
            self.ocommon.prog_exit("Error occurred")
        else:
            self.ocommon.log_info_message(
                "CDP is now updated for the existing RAC cluster",
                self.file_name
            )
