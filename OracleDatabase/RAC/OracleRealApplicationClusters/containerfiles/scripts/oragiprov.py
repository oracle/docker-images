#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
#############################

"""
This file contains Grid Infrastructure provisioning and CVU orchestration logic.
"""

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oracvu import *
from oraops import OperationRunner, CommandBuilder
import time

import os
import sys
import subprocess
import datetime
from multiprocessing import Process

class OraGIProv:
   """
   This class performs Grid Infrastructure provisioning and related checks
   """
   def __init__(self,oralogger,orahandler,oraenv,oracommon,oracvu,orasetupssh):
      try:
         self.ologger             = oralogger
         self.ohandler            = orahandler
         self.oenv                = oraenv.get_instance()
         self.ocommon             = oracommon
         self.ora_env_dict        = oraenv.get_env_vars()
         self.file_name           = os.path.basename(__file__)
         self.osetupssh           = orasetupssh
         self.op_runner           = OperationRunner(self.ocommon, self.file_name, "GI")
         self.cmd_builder         = CommandBuilder(self.ocommon)
         self.ocvu                = oracvu
         self.stopThreaFlag       = False
         self.mythread            = {}
         self.myproc              = {}
      except BaseException as ex:
         ex_type, ex_value, ex_traceback = sys.exc_info()
         trace_back = sys.tracebacklimit.extract_tb(ex_traceback)
         stack_trace = list()
         for trace in trace_back:
             stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1], trace[2], trace[3]))
         self.ocommon.log_info_message(ex_type.__name__,self.file_name)
         self.ocommon.log_info_message(ex_value,self.file_name)
         self.ocommon.log_info_message(stack_trace,self.file_name)

   def _get_public_nodes(self):
      """
      Return CRS public nodes as a list while filtering empty entries.
      """
      pub_nodes, vip_nodes, priv_nodes = self.ocommon.process_cluster_vars("CRS_NODES")
      return [node for node in pub_nodes.split(" ") if node]

   def _run_remote_sudo(self, giuser, node, command, check_status=True):
      """
      Execute a remote sudo command over SSH via grid user.
      """
      cmd = self.cmd_builder.build_remote_sudo(giuser, node, command)
      output, error, retcode = self.op_runner.run_command("gi_remote_sudo", cmd, None, None, check_status)
      return output, error, retcode

   def _write_responsefile(self, gridrsp, rspdata, netmasklist):
      """
      Write response file and validate existence.
      """
      self.ocommon.write_file(gridrsp, rspdata)
      gridrsp = self.ocommon.validate_response_file(gridrsp, "grid")
      return gridrsp, netmasklist

   def _validate_install_markers(self, swdata, required_markers):
      """
      Validate required output markers from install output.
      """
      for marker in required_markers:
         if not self.ocommon.check_substr_match(swdata, marker):
            self.ocommon.log_error_message("Grid software install failed. Exiting...", self.file_name)
            self.ocommon.prog_exit("127")

   def setup(self):
         """
         This function sets up Grid on this machine
         """
         self.ocommon.log_step("GI", "setup", "start", None, self.file_name)
         ct = datetime.datetime.now()
         bts = ct.timestamp()
         giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
         pubhostname = self.ocommon.get_public_hostname()
         retcode1=1
         if not self.ocommon.check_key("GI_SW_UNZIPPED_FLAG",self.ora_env_dict): 
            retcode1=self.ocvu.check_home(pubhostname,gihome,giuser)
         if retcode1 == 0:
           bstr="Grid home is already installed on this machine"
           self.ocommon.log_info_message(self.ocommon.print_banner(bstr),self.file_name)
         if self.ocommon.check_key("GI_HOME_CONFIGURED_FLAG",self.ora_env_dict):
           bstr="Grid is already configured on this machine"
           self.ocommon.log_info_message(self.ocommon.print_banner(bstr),self.file_name)             
         else:
           self.env_param_checks()
           self.ocommon.reset_os_password(giuser)
           self.ocommon.log_step("GI", "perform_ssh_setup", "start", None, self.file_name)
           self.perform_ssh_setup()
           self.ocommon.log_step("GI", "perform_ssh_setup", "end", None, self.file_name)
           if self.ocommon.check_key("RESET_FAILED_SYSTEMD",self.ora_env_dict):
              self.ocommon.log_step("GI", "reset_failed_units", "start", None, self.file_name)
              self.reset_failed_units_on_all_nodes()
           if self.ocommon.check_key("PERFORM_CVU_CHECKS",self.ora_env_dict):
              self.ocommon.log_step("GI", "ocvu.node_reachability_checks", "start", None, self.file_name)
              self.ocvu.node_reachability_checks("public",self.ora_env_dict["GRID_USER"],"INSTALL")
              self.ocommon.log_step("GI", "ocvu.node_reachability_checks", "end", None, self.file_name)
              self.ocommon.log_step("GI", "ocvu.node_connectivity_checks", "start", None, self.file_name)
              self.ocvu.node_connectivity_checks("public",self.ora_env_dict["GRID_USER"],"INSTALL")
              self.ocommon.log_step("GI", "ocvu.node_connectivity_checks", "end", None, self.file_name)
           if retcode1 != 0 and self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
              self.ocommon.log_step("GI", "crs_sw_install", "start", None, self.file_name)
              self.crs_sw_install()
              self.ocommon.log_step("GI", "crs_sw_install", "end", None, self.file_name)
              # run root should run in RAC all setups and CRS non RU Patch situation, else not
              self.ocommon.log_step("GI", "run_rootsh_and_orainstsh", "start", None, self.file_name)
              self.run_orainstsh()
              self.run_rootsh()
              self.ocommon.log_step("GI", "run_rootsh_and_orainstsh", "end", None, self.file_name)
           self.ocommon.log_step("GI", "install_cvuqdisk_on_all_nodes", "start", None, self.file_name)
           self.install_cvuqdisk_on_all_nodes()
           self.ocommon.log_step("GI", "crs_config_install", "start", None, self.file_name)
           gridrsp=self.crs_config_install()
           self.ocommon.log_step("GI", "crs_config_install", "end", None, self.file_name)
           self.ocommon.log_step("GI", "run_rootsh", "start", None, self.file_name)
           self.run_rootsh()
           self.ocommon.log_step("GI", "run_rootsh", "end", None, self.file_name)
           self.ocommon.log_step("GI", "execute_postconfig", "start", None, self.file_name)
           self.run_postroot(gridrsp)
           self.ocommon.log_step("GI", "execute_postconfig", "end", None, self.file_name)
           retcode1=self.ocvu.check_ohasd(None)
           retcode3=1
           if self.ocommon.check_key("CRS_GPC",self.ora_env_dict):
              self.ocommon.log_info_message("Start check_clu(): CRS_GPC is set; validating Oracle Restart CRS configuration",self.file_name) 
              retcode3=self.ocvu.check_clu(pubhostname,None,True)
              self.ocommon.log_info_message("End check_clu()",self.file_name) 
           else:
              self.ocommon.log_info_message("Start check_clu(): validating CRS configuration",self.file_name) 
              retcode3=self.ocvu.check_clu(None,None,None)
              self.ocommon.log_info_message("End check_clu()",self.file_name) 
           if retcode1 != 0 and  retcode3 != 0:
              self.ocommon.log_info_message("Cluster state is not healthy. Exiting...",self.file_name)
              self.ocommon.prog_exit("127")
           else:
              self.ora_env_dict=self.ocommon.add_key("CLUSTER_SETUP_FLAG","running",self.ora_env_dict)

           self.ocommon.run_custom_scripts("CUSTOM_GRID_SCRIPT_DIR","CUSTOM_GRID_SCRIPT_FILE",giuser)
         self.backup_oracle_etc_files()
         ct = datetime.datetime.now()
         ets = ct.timestamp()
         totaltime=ets - bts
         self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

   def env_param_checks(self):
       """
       Perform environment setup checks.
       """
       if not self.ocommon.check_key("CRS_GPC",self.ora_env_dict):
          self.scan_check()
       self.ocommon.check_env_variable("GRID_HOME",True)
       self.ocommon.check_env_variable("GRID_BASE",True)
       self.ocommon.check_env_variable("INVENTORY",True)
       self.ocommon.check_env_variable("ASM_DISCOVERY_DIR",None)
        
   def scan_check(self):
       """
       Check if scan is set
       """
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
          self.ocommon.log_info_message("GRID_RESPONSE_FILE is set. Skipping SCAN_NAME check because CVU will validate the response file.",self.file_name)
       else:
          if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict):
             self.ocommon.log_info_message("SCAN_NAME variable is set: " + self.ora_env_dict["SCAN_NAME"],self.file_name)
          else:
           self.ocommon.log_error_message("SCAN_NAME is not set. Exiting...",self.file_name)
           self.ocommon.prog_exit("127")

   def perform_ssh_setup(self):
      """
      Perform ssh setup
      """

      pub_nodes, vip_nodes, priv_nodes = self.ocommon.process_cluster_vars("CRS_NODES")
      crs_nodes = pub_nodes.replace(" ", ",")
      nodes = crs_nodes.split(",")

      is_gpc = self.ocommon.check_key("CRS_GPC", self.ora_env_dict)
      is_k8s = self.ocommon.detect_k8s_env()

      has_injected_keys = (
         self.ocommon.check_key("SSH_PRIVATE_KEY", self.ora_env_dict) and
         self.ocommon.check_key("SSH_PUBLIC_KEY", self.ora_env_dict)
      )

      user = self.ora_env_dict["GRID_USER"]
      ohome = self.ora_env_dict["GRID_HOME"]

      # --------------------------------------------------
      # Case 1: Local SSH bootstrap
      #   - CRS_GPC with no injected keys (K8s or non-K8s)
      #   - OR single-node RAC on non-K8s
      # --------------------------------------------------
      if (is_gpc and not has_injected_keys) or \
         (not is_gpc and len(nodes) == 1 and not is_k8s):

         node = nodes[0]

         self.ocommon.log_info_message(
               f"Bootstrapping local SSH for GRID user on node {node}",
               self.file_name
         )

         cmd = (
               'su - {0} -c '
               '"/bin/rm -rf ~/.ssh ; '
               '/bin/mkdir -p ~/.ssh && chmod 700 ~/.ssh ; '
               '/bin/ssh-keygen -t rsa -b 4096 -q -N \'\' -f ~/.ssh/id_rsa ; '
               '/bin/ssh-keyscan -H {1} >> ~/.ssh/known_hosts 2>/dev/null ; '
               '/bin/cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys ; '
               '/bin/chmod 600 ~/.ssh/authorized_keys ~/.ssh/known_hosts"'
         ).format(user, node)

         output, error, retcode = self.op_runner.run_command("gi_local_ssh_bootstrap", cmd, None, None, None)
         return

      # --------------------------------------------------
      # Case 2: Multi-node RAC → CVU SSH setup
      # --------------------------------------------------
      if not is_gpc and len(nodes) > 1:
         if not has_injected_keys:
               self.ocommon.log_info_message(
                  "Multi-node RAC detected; running legacy SSH setup for GRID user",
                  self.file_name
               )
               self.osetupssh.setupssh(user, ohome, "INSTALL")
         else:
               self.ocommon.log_info_message(
                  "Injected SSH keys detected; skipping legacy SSH setup",
                  self.file_name
               )
      else:
         self.ocommon.log_info_message(
            "Skipping legacy SSH setup for current topology/keys combination",
            self.file_name
         )

   def crs_sw_install(self):
       """
       This function performs CRS software install on all nodes
       """
       giuser,gihome,gibase,oinv=self.ocommon.get_gi_params()
       nodes=self._get_public_nodes()
       crs_nodes=",".join(nodes)
       osdba=self.ora_env_dict["OSDBA_GROUP"] if self.ocommon.check_key("OSDBA",self.ora_env_dict) else "asmdba"
       osoper=self.ora_env_dict["OSPER_GROUP"] if self.ocommon.check_key("OSPER_GROUP",self.ora_env_dict) else "asmoper"
       osasm=self.ora_env_dict["OSASM_GROUP"] if self.ocommon.check_key("OSASM_GROUP",self.ora_env_dict) else "asmadmin"

       copyflag=" -noCopy "
       if not self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
          copyflag=" -noCopy "

       oraversion=self.ocommon.get_rsp_version("INSTALL",None)
       version=oraversion.split(".",1)[0].strip()

       ## Clearing the dictionary
       self.mythread.clear()
       mythreads=[]
       self.ocommon.log_step("GI", "crs_sw_install", "nodes", ",".join(nodes), self.file_name)
       for node in nodes:
          self.ocommon.log_step("GI", "crs_sw_install", "node", node, self.file_name)

          thread=Process(target=self.ocommon.crs_sw_install_on_node,args=(giuser,copyflag,crs_nodes,oinv,gihome,gibase,osdba,osoper,osasm,version,node))
          mythreads.append(thread)
          thread.start()
          time.sleep(10)

 
       for thread in mythreads:  # iterates over the threads
          thread.join()       # waits until the thread has finished work       
          self.ocommon.log_info_message("Joining worker processes",self.file_name)


   def crs_config_install(self):
       """
       This function performs CRS software install on all nodes
       """
       gridrsp=""
       netmasklist=None

       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
           gridrsp,netmasklist=self.check_responsefile()  
       else:
           gridrsp,netmasklist=self.prepare_responsefile()
       if self.ocommon.check_key("PERFORM_CVU_CHECKS",self.ora_env_dict): 
          self.ocvu.cluvfy_checkrspfile(gridrsp,self.ora_env_dict["GRID_HOME"],self.ora_env_dict["GRID_USER"])
       cmd=self.ocommon.get_sw_cmd("INSTALL",gridrsp,None,netmasklist)
       passwd=self.ocommon.get_asm_passwd().replace('\n', ' ').replace('\r', '')
       self.ocommon.set_mask_str(passwd)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.unset_mask_str()
       self.ocommon.check_os_err(output,error,retcode,None)
       self.check_crs_config_install(output)
       return gridrsp
   def parse_gridrsp_file(self, filename):
       """
       Parses the grid_setup_new_23ai.rsp file and extracts network interface details into a formatted string.

       Args:
            filename: The name of the grid_setup_new_23ai.rsp file.

       Returns:
            A string containing the formatted network interface list.
       """
       netmasklist = ""
       with open(filename, 'r') as f:
        for line in f:
            if line.startswith('networkInterfaceList='):
                self.ocommon.log_info_message("networkInterfaceList parameter found in response file line: " + line, self.file_name)
                # Extract network interface details
                interface_data = line.strip().split('=')[1].split(',')
                for interface in interface_data:
                    nwname, _, suffix = interface.split(':')
                    if interface.endswith(":1"):
                        subnet_mask = "255.255.0.0"  # Hardcoded subnet mask for public interfaces with ":1"
                        # self.ocommon.log_info_message(f"Subnet mask (hardcoded for :1): {subnet_mask}", self.file_name)
                    else:
                        try:
                            subnet_mask = self.ocommon.get_netmask_info(nwname)
                           #  self.ocommon.log_info_message(f"Subnet mask (from ocommon): {subnet_mask}", self.file_name)
                        except Exception:
                            self.ocommon.log_warning_message(f"Failed to retrieve subnet mask for {nwname} using ocommon, using default (may be inaccurate)", self.file_name)
                            subnet_mask = "255.255.255.0"  # Default subnet mask if retrieval fails
                            self.ocommon.log_info_message(f"Default subnet mask used: {subnet_mask}", self.file_name)

                    netmasklist += f"{nwname}:{subnet_mask},"

       # Remove the trailing comma
       netmasklist = netmasklist[:-1]
       self.ocommon.log_info_message("netmasklist generated from parse_gridrsp_file(): " + netmasklist ,self.file_name)
       return netmasklist

   def check_responsefile(self):
       """
        This function returns the valid response file
       """
       gridrsp=None
       netmasklist = ""
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
          gridrsp=self.ora_env_dict["GRID_RESPONSE_FILE"]
          self.ocommon.log_info_message("GRID_RESPONSE_FILE parameter is set. File location: " + gridrsp ,self.file_name)

       gridrsp = self.ocommon.validate_response_file(gridrsp, "grid")
       netmasklist = self.parse_gridrsp_file(gridrsp)
       self.ocommon.log_info_message("netmasklist parameter is set to: " + netmasklist ,self.file_name)
       return gridrsp, netmasklist

   def prepare_responsefile(self):
       """
       This function prepares a response file if no response file is passed
       """
       self.ocommon.log_info_message("Preparing Grid response file.",self.file_name)
       asmfg_disk=""
       asm_disk=""
       gimrfg_disk=""
       gimr_disk=""
       giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
       dgred=self.ora_env_dict["CRS_ASMDG_REDUNDANCY"] if self.ocommon.check_key("CRS_ASMDG_REDUNDANCY",self.ora_env_dict) else "EXTERNAL"
       asmfg_disk,asm_disk=self.ocommon.build_asm_device("CRS_ASM_DEVICE_LIST",dgred)
       if self.ocommon.check_key("CLUSTER_TYPE",self.ora_env_dict):
          if self.ora_env_dict["CLUSTER_TYPE"] == 'DOMAIN':
              gimrfg_disk,gimr_disk=self.ocommon.build_asm_device("GIMR_ASM_DEVICE_LIST",dgred)

       ## Variable Assignments
       clusterusage="GENERAL_PURPOSE" if self.ocommon.check_key("CRS_GPC",self.ora_env_dict) else "RAC"
       crsconfig="HA_CONFIG" if self.ocommon.check_key("CRS_GPC",self.ora_env_dict) else "CRS_CONFIG"
       if clusterusage != "GENERAL_PURPOSE":
         scanname=self.ora_env_dict["SCAN_NAME"]
         scanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else "1521"
       else:
          scanname=""
          scanport=""
       clutype=self.ora_env_dict["CLUSTER_TYPE"] if self.ocommon.check_key("CLUSTER_TYPE",self.ora_env_dict) else "STANDALONE"
       cluname=self.ora_env_dict["CLUSTER_NAME"] if self.ocommon.check_key("CLUSTER_NAME",self.ora_env_dict) else "racnode-c"
       clunodes=self.ocommon.get_crsnodes()
       nwiface,netmasklist=self.ocommon.get_nwifaces()
       gimrflag=self.ora_env_dict["GIMR_FLAG"] if self.ocommon.check_key("GIMR",self.ora_env_dict)  else "false" 
       passwd=self.ocommon.get_asm_passwd().replace('\n', ' ').replace('\r', '')
       dgname=self.ocommon.rmdgprefix(self.ora_env_dict["CRS_ASM_DISKGROUP"]) if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "DATA" 
       fgname=asmfg_disk
       asmdisk=asm_disk
       discovery_str=self.ocommon.build_asm_discovery_str("CRS_ASM_DEVICE_LIST")
       asmstr=self.ora_env_dict["CRS_ASM_DISCOVERY_STRING"] if self.ocommon.check_key("CRS_ASM_DISCOVERY_STRING",self.ora_env_dict) else discovery_str
       oraversion=self.ocommon.get_rsp_version("INSTALL",None)
       self.ocommon.log_info_message("Oracle version: " + oraversion, self.file_name)
       disksWithFGNames=asmdisk.replace(',',',,') + ','
       self.ocommon.log_info_message("disksWithFGNames: " + disksWithFGNames, self.file_name)
       gridrsp="/tmp/grid.rsp"
    
       version=oraversion.split(".",1)[0].strip()
       self.ocommon.log_info_message("disk" + version, self.file_name)
       if int(version) < 23: # 21,19 etc. versions
         return self.get_responsefile(
            obase, invloc, scanname, scanport, clutype, cluname, clunodes,
            nwiface, gimrflag, passwd, dgname, dgred, fgname, asmdisk,
            asmstr, disksWithFGNames, oraversion, gridrsp, netmasklist, crsconfig
         )
       elif int(version) >= 26: # 26 onwards versions
         return self.get_26ai_responsefile(
            obase, invloc, scanname, scanport, clutype, cluname, clunodes,
            nwiface, gimrflag, passwd, dgname, dgred, fgname, asmdisk,
            asmstr, disksWithFGNames, oraversion, gridrsp, netmasklist, clusterusage
         )
       else:
         return self.get_23c_responsefile( # Exactly for 23ai version
            obase, invloc, scanname, scanport, clutype, cluname, clunodes,
            nwiface, gimrflag, passwd, dgname, dgred, fgname, asmdisk,
            asmstr, disksWithFGNames, oraversion, gridrsp, netmasklist, clusterusage
         )

   def get_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,crsconfig):
       """
       This function prepares a response file if no response file is passed
       """      
       self.ocommon.log_info_message("Generating legacy response file (pre-23c format)", self.file_name)
       rspdata='''
       oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{15} 
       oracle.install.option={19}
       ORACLE_BASE={0}
       INVENTORY_LOCATION={1}
       oracle.install.asm.OSDBA=asmdba
       oracle.install.asm.OSOPER=asmoper
       oracle.install.asm.OSASM=asmadmin
       oracle.install.crs.config.gpnp.scanName={2}
       oracle.install.crs.config.gpnp.scanPort={3}
       oracle.install.crs.config.clusterName={5}
       oracle.install.crs.config.clusterNodes={6}
       oracle.install.crs.config.networkInterfaceList={7}
       oracle.install.crs.configureGIMR={8}
       oracle.install.asm.SYSASMPassword={9}
       oracle.install.asm.monitorPassword={9}
       oracle.install.crs.config.storageOption=
       oracle.install.asm.diskGroup.name={10}
       oracle.install.asm.diskGroup.redundancy={11}
       oracle.install.asm.diskGroup.AUSize=4
       oracle.install.asm.diskGroup.disksWithFailureGroupNames={18}
       oracle.install.asm.diskGroup.disks={13}
       oracle.install.asm.diskGroup.quorumFailureGroupNames=
       oracle.install.asm.diskGroup.diskDiscoveryString={14}
       oracle.install.crs.rootconfig.configMethod=ROOT
       oracle.install.asm.configureAFD=false
       oracle.install.crs.rootconfig.executeRootScript=false
       oracle.install.crs.config.ignoreDownNodes=false
       oracle.install.config.managementOption=NONE
       oracle.install.crs.configureRHPS={16}
       oracle.install.crs.config.ClusterConfiguration={17}
       '''.format(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,oraversion,"false","STANDALONE",disksWithFGNames,crsconfig)
       return self._write_responsefile(gridrsp, rspdata, netmasklist)

   def get_23c_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,clusterusage):
       """
       This function prepares a response file if no response file is passed
       """
       self.ocommon.log_info_message("Generating 23c response file", self.file_name)
       rspdata='''
       oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{15}
       installOption=CRS_CONFIG
       ORACLE_BASE={0}
       INVENTORY_LOCATION={1}
       OSDBA=asmdba
       OSOPER=asmoper
       OSASM=asmadmin
       clusterUsage={16}
       scanName={2}
       scanPort={3}
       clusterName={5}
       clusterNodes={6}
       networkInterfaceList={7}
       storageOption=
       diskGroupName={10}
       redundancy={11}
       auSize=4
       disksWithFailureGroupNames={17}
       diskList={13}
       quorumFailureGroupNames=
       diskString={14}
       configMethod=ROOT
       executeRootScript=false
       ignoreDownNodes=false
       managementOption=NONE
       '''.format(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,oraversion,clusterusage,disksWithFGNames)
       major_ver,minor_ver=self.ocommon.get_ora_version()
       if int(minor_ver) < 9: 
          rspdata+="configureAFD=false\n"
       return self._write_responsefile(gridrsp, rspdata, netmasklist)

   def get_26ai_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,clusterusage):
       """
       This function prepares a response file if no response file is passed
       """
       self.ocommon.log_info_message("Generating 26ai response file", self.file_name)
       rspdata='''
       oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{15}
       installOption=CRS_CONFIG
       ORACLE_BASE={0}
       INVENTORY_LOCATION={1}
       OSDBA=asmdba
       OSOPER=asmoper
       OSASM=asmadmin
       clusterUsage={16}
       scanName={2}
       scanPort={3}
       clusterName={5}
       clusterNodes={6}
       networkInterfaceList={7}
       storageOption=
       diskGroupName={10}
       redundancy={11}
       auSize=4
       disksWithFailureGroupNames={17}
       diskList={13}
       quorumFailureGroupNames=
       diskString={14}
       configMethod=ROOT
       executeRootScript=false
       ignoreDownNodes=false
       managementOption=NONE
       '''.format(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,oraversion,clusterusage,disksWithFGNames)
       return self._write_responsefile(gridrsp, rspdata, netmasklist)

   def check_crs_config_install(self,swdata):
       """
       This function checks whether software install completed successfully
       """
       self._validate_install_markers(swdata, ("root.sh", "executeConfigTools -responseFile"))

   def check_crs_sw_install(self,swdata):
       """
       This function checks whether software install completed successfully
       """
       self._validate_install_markers(swdata, ("orainstRoot.sh", "root.sh"))

   def run_orainstsh(self):
       """
       This function runs orainstRoot.sh after Grid setup
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       for node in self._get_public_nodes():
           self._run_remote_sudo(giuser, node, "{0}/orainstRoot.sh".format(oinv), True)

   def run_rootsh(self):
      """
      This function runs rsync from first node to other nodes
      (when APPLY_RU_LOCATION is set and CRS_GPC is not set)
      and then executes root.sh after grid setup
      """
      giuser, gihome, gbase, oinv = self.ocommon.get_gi_params()
      node_list = self._get_public_nodes()



      # Clear thread tracking
      self.mythread.clear()
      mythreads = []

      # Run root.sh on each node
      oraversion = self.ocommon.get_rsp_version("INSTALL", None)
      version = oraversion.split(".", 1)[0].strip()
      self.ocommon.log_info_message("Oracle version: " + version, self.file_name)

      for node in node_list:
         if int(version) == 19 or int(version) == 21:
               self.run_rootsh_on_node(node, giuser, gihome)
         else:
               self.ocommon.log_step("GI", "run_rootsh", "node", node, self.file_name)
               thread = Process(target=self.run_rootsh_on_node, args=(node, giuser, gihome))
               mythreads.append(thread)
               thread.start()

      for thread in mythreads:
         thread.join()
         self.ocommon.log_info_message("Joining root.sh worker process", self.file_name)


   def run_rootsh_on_node(self,node,giuser,gihome):
       """
       This function runs root.sh on a node
       """
       self._run_remote_sudo(giuser, node, "{0}/root.sh".format(gihome), True)

   def run_postroot(self,gridrsp):
       """
       This function executes post-root steps
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       cmd=self.cmd_builder.build_gi_postroot_config(giuser, gihome, gridrsp)
       output,error,retcode=self.op_runner.run_command("gi_execute_config_tools", cmd, None, None, None)

   def reset_systemd(self):
      """
      This function resets systemd
      """
      while True:
         self.ocommon.log_info_message("Root.sh is running. Resetting systemd to avoid failure.",self.file_name)
         cmd="systemctl reset-failed"
         output,error,retcode=self.op_runner.run_command("gi_systemd_reset_failed", cmd, None, None, None)
         cmd = "systemctl is-system-running"
         output,error,retcode=self.op_runner.run_command("gi_systemd_is_running", cmd, None, None, None)
         time.sleep(3)
         if self.stopThreaFlag:
            break
   def reset_failed_units_on_all_nodes(self):
      for node in self._get_public_nodes():
         self.ocommon.log_step("GI", "reset_failed_units", "node", node, self.file_name)
         self.reset_failed_units(node)

   def reset_failed_units(self,node):
      RESET_FAILED_SYSTEMD = 'true'
      SERVICE_NAME = "rhnsd"
      SCRIPT_DIR = "/opt/scripts/startup/scripts"
      RESET_FAILED_UNITS = "resetFailedUnits.sh"
      CRON_JOB_FREQUENCY = "* * * * *"

      def error_exit(message):
         raise Exception(message)
      
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()

      if RESET_FAILED_SYSTEMD != 'false':
         if subprocess.run(["pgrep", "-x", SERVICE_NAME], stdout=subprocess.DEVNULL).returncode == 0:
               self.ocommon.log_info_message(SERVICE_NAME + " is running.",self.file_name)
               # Check if the service is responding
               if subprocess.run(["systemctl", "is-active", "--quiet", SERVICE_NAME]).returncode != 0:
                  self.ocommon.log_info_message(SERVICE_NAME + " is not responding. Stopping the service.",self.file_name)
                  cmd='''su - {0} -c "ssh {1}  sudo systemctl stop {2}"'''.format(giuser,node,SERVICE_NAME)
                  output,error,retcode=self.op_runner.run_command("gi_reset_failed_units_stop_service", cmd, None, None, None)
                  cmd='''su - {0} -c "ssh {1}  sudo systemctl disable {2}"'''.format(giuser,node,SERVICE_NAME)
                  output,error,retcode=self.op_runner.run_command("gi_reset_failed_units_disable_service", cmd, None, None, None)
                  self.ocommon.log_info_message(SERVICE_NAME + " stopped.",self.file_name)
               else:
                  self.ocommon.log_info_message(SERVICE_NAME + " is responsive. No action needed.",self.file_name)
         else:
               self.ocommon.log_info_message(SERVICE_NAME + " is not running.",self.file_name)

         self.ocommon.log_info_message("Setting crontab",self.file_name)         
         cmd = '''su - {0} -c "ssh {1} 'sudo crontab -l | {{ cat; echo \\"{2} {3}/{4}\\"; }} | sudo crontab -'"'''.format(giuser, node, CRON_JOB_FREQUENCY, SCRIPT_DIR, RESET_FAILED_UNITS)
         try:
               output,error,retcode=self.op_runner.run_command("gi_reset_failed_units_crontab", cmd, None, None, None)
               self.ocommon.log_info_message("Successfully installed " + SCRIPT_DIR + "/" + RESET_FAILED_UNITS + " using crontab",self.file_name)
         except subprocess.CalledProcessError:
               error_exit("Error occurred in crontab setup")

   def install_cvuqdisk_on_all_nodes(self):
      for node in self._get_public_nodes():
         self.ocommon.log_step("GI", "install_cvuqdisk", "node", node, self.file_name)
         self.install_cvuqdisk(node)

   def install_cvuqdisk(self, node):
      """
      Install cvuqdisk rpm on the given node.
      Dynamically picks RPM location from GRID_HOME instead of hardcoding.
      """
      # Get GI parameters
      giuser, gihome, obase, invloc = self.ocommon.get_gi_params()

      # Construct rpm directory path based on GRID_HOME
      rpm_directory = os.path.join(gihome, "cv", "rpm")

      try:
         # Construct and run rpm install command
         cmd = self.cmd_builder.build_gi_install_cvuqdisk(giuser, node, rpm_directory)
         output, error, retcode = self.op_runner.run_command("gi_install_cvuqdisk", cmd, None, None, None)
         self.ocommon.log_info_message("Successfully installed cvuqdisk file.", self.file_name)

      except subprocess.CalledProcessError as e:
         self.ocommon.log_error_message(f"Error installing cvuqdisk. Exiting... {e}", self.file_name)

   def backup_oracle_etc_files(self):
      """
      Backup /etc/oracle based on Oracle version rules.

      - Version > 19  : always backup
      - Version == 19 : backup only if CRS_GPC is set
      """

      oraversion = self.ocommon.get_rsp_version("INSTALL", None)
      self.ocommon.log_info_message(
         "Oracle version: {0}".format(oraversion),
         self.file_name
      )

      if not oraversion:
         self.ocommon.log_info_message(
               "Oracle version not detected; skipping /etc/oracle backup",
               self.file_name
         )
         return True

      version = oraversion.split(".", 1)[0].strip()
      self.ocommon.log_info_message(
         "Oracle major version: {0}".format(version),
         self.file_name
      )

      # --------------------------------------------------
      # Decide whether backup is required
      # --------------------------------------------------
      if int(version) == 19 and not self.ocommon.check_key("CRS_GPC", self.ora_env_dict):
         self.ocommon.log_info_message(
               "Oracle 19c detected and CRS_GPC not set; skipping /etc/oracle backup",
               self.file_name
         )
         return True

      self.ocommon.log_info_message(
         "Running backup_oracle_etc_files()",
         self.file_name
      )

      giuser, gihome, gibase, oinv = self.ocommon.get_gi_params()
      node = self.ocommon.get_public_hostname()

      targetdir = "{0}/.etcoraclebackup".format(gibase)
      backup_dir = "/etc/oracle"

      # --------------------------------------------------
      # 1. Create backup directory
      # --------------------------------------------------
      cmd = (
         'su - {0} -c "ssh {1} sudo mkdir -p {2}"'
         .format(giuser, node, targetdir)
      )
      output, error, retcode = self.op_runner.run_command("gi_backup_oracle_etc_mkdir", cmd, None, None, None)

      if retcode != 0:
         self.ocommon.log_error_message(
               "Failed to create backup directory {0} on node {1}".format(targetdir, node),
               self.file_name
         )
         return False

      # --------------------------------------------------
      # 2. Copy /etc/oracle
      # --------------------------------------------------
      cmd = (
         'su - {0} -c "ssh {1} sudo cp -rp {3} {2}/"'
         .format(giuser, node, targetdir, backup_dir)
      )
      output, error, retcode = self.op_runner.run_command("gi_backup_oracle_etc_copy", cmd, None, None, None)

      if retcode != 0:
         self.ocommon.log_error_message(
               "Failed to backup {0} on node {1}".format(backup_dir, node),
               self.file_name
         )
         return False

      # --------------------------------------------------
      # Success
      # --------------------------------------------------
      self.ocommon.log_info_message(
         "Successfully backed up {0} to {1} on node {2}".format(
               backup_dir, targetdir, node
         ),
         self.file_name
      )

      return True
