#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
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
from oracvu import *
import time

import os
import sys
import subprocess
import datetime

class OraGIProv:
   """
   This class performs the CVU checks
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

   def setup(self):
         """
         This function setup the grid on this machine
         """
         self.ocommon.log_info_message("Start setup()",self.file_name)
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
           self.ocommon.log_info_message("Start perform_ssh_setup()",self.file_name)
           self.perform_ssh_setup()
           self.ocommon.log_info_message("End perform_ssh_setup()",self.file_name)
           if self.ocommon.check_key("RESET_FAILED_SYSTEMD",self.ora_env_dict):
              self.ocommon.log_info_message("Start reset_failed_units()",self.file_name)
              self.reset_failed_units_on_all_nodes()
           if self.ocommon.check_key("PERFORM_CVU_CHECKS",self.ora_env_dict):
              self.ocommon.log_info_message("Start ocvu.node_reachability_checks()",self.file_name)
              self.ocvu.node_reachability_checks("public",self.ora_env_dict["GRID_USER"],"INSTALL")
              self.ocommon.log_info_message("End ocvu.node_reachability_checks()",self.file_name)
              self.ocommon.log_info_message("Start ocvu.node_connectivity_checks()",self.file_name)
              self.ocvu.node_connectivity_checks("public",self.ora_env_dict["GRID_USER"],"INSTALL")
              self.ocommon.log_info_message("End ocvu.node_connectivity_checks()",self.file_name)
           if retcode1 != 0 and self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
              self.ocommon.log_info_message("Start crs_sw_instal()",self.file_name)
              self.crs_sw_install()
              self.ocommon.log_info_message("End crs_sw_instal()",self.file_name)
              self.ocommon.log_info_message("Start run_rootsh() and run_orainstsh()",self.file_name)
              self.run_orainstsh()
              self.run_rootsh()
              self.ocommon.log_info_message("End run_rootsh() and run_orainstsh()",self.file_name)
           self.ocommon.log_info_message("Start install_cvuqdisk_on_all_nodes()",self.file_name)
           self.install_cvuqdisk_on_all_nodes()
           self.ocommon.log_info_message("Start crs_config_install()",self.file_name)
           gridrsp=self.crs_config_install()
           self.ocommon.log_info_message("End crs_config_install()",self.file_name)
           self.ocommon.log_info_message("Start run_rootsh()",self.file_name)
           self.run_rootsh()
           self.ocommon.log_info_message("End run_rootsh()",self.file_name)
           self.ocommon.log_info_message("Start execute_postconfig()",self.file_name)
           self.run_postroot(gridrsp)
           self.ocommon.log_info_message("End execute_postconfig()",self.file_name)
           retcode1=self.ocvu.check_ohasd(None)
           retcode3=self.ocvu.check_clu(None,None)
           if retcode1 != 0 and  retcode3 != 0:
              self.ocommon.log_info_message("Cluster state is not healthy. Exiting..",self.file_name)
              self.ocommon.prog_exit("127")
           else:
              self.ora_env_dict=self.ocommon.add_key("CLUSTER_SETUP_FLAG","running",self.ora_env_dict)

           self.ocommon.run_custom_scripts("CUSTOM_GRID_SCRIPT_DIR","CUSTOM_GRID_SCRIPT_FILE",giuser)

         ct = datetime.datetime.now()
         ets = ct.timestamp()
         totaltime=ets - bts
         self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

   def env_param_checks(self):
       """
       Perform the env setup checks
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
          self.ocommon.log_info_message("GRID_RESPONSE_FILE is set. Ignoring checking SCAN_NAME as CVU will validate responsefile",self.file_name)
       else:
          if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict):
             self.ocommon.log_info_message("SCAN_NAME variable is set: " + self.ora_env_dict["SCAN_NAME"],self.file_name)
             #ipaddr=self.ocommon.get_ip(self.ora_env_dict["SCAN_NAME"])
             #status=self.ocommon.validate_ip(ipaddr)
             #if status:
             #   self.ocommon.log_info_message("SCAN_NAME is a valid IP. Check passed...",self.file_name)
             #else:
             #   self.ocommon.log_error_message("SCAN_NAME is not a valid IP. Check failed. Exiting...",self.file_name)
             #   self.ocommon.prog_exit("127") 
          else:
           self.ocommon.log_error_message("SCAN_NAME is not set. Exiting...",self.file_name)
           self.ocommon.prog_exit("127")

   def perform_ssh_setup(self):
       """
       Perform ssh setup
       """
       #if not self.ocommon.detect_k8s_env():
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       crs_nodes_list=crs_nodes.split(",")
       if len(crs_nodes_list) == 1:
          self.ocommon.log_info_message("Cluster size=1. Node=" + crs_nodes_list[0],self.file_name)
          user=self.ora_env_dict["GRID_USER"]
          cmd='''su - {0} -c "/bin/rm -rf ~/.ssh ; sleep 1; /bin/ssh-keygen -t rsa -q -N \'\' -f ~/.ssh/id_rsa ; sleep 1; /bin/ssh-keyscan {1} > ~/.ssh/known_hosts 2>/dev/null ; sleep 1; /bin/cp ~/.ssh/id_rsa.pub  ~/.ssh/authorized_keys"'''.format(user,crs_nodes_list[0])
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,None)
       else:
          if not self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict) and not self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict):
            user=self.ora_env_dict["GRID_USER"]
            ohome=self.ora_env_dict["GRID_HOME"]
            self.osetupssh.setupssh(user,ohome,"INSTALL")
            #if self.ocommon.check_key("VERIFY_SSH",self.ora_env_dict):
            # self.osetupssh.verifyssh(user,"INSTALL")
          else:
            self.ocommon.log_info_message("SSH setup must be already completed during env setup as this this env variables SSH_PRIVATE_KEY and SSH_PUBLIC_KEY are set.",self.file_name)

   def crs_sw_install(self):
       """
       This function performs the crs software install on all the nodes
       """
       giuser,gihome,gibase,oinv=self.ocommon.get_gi_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       osdba=self.ora_env_dict["OSDBA_GROUP"] if self.ocommon.check_key("OSDBA",self.ora_env_dict) else "asmdba"
       osoper=self.ora_env_dict["OSPER_GROUP"] if self.ocommon.check_key("OSPER_GROUP",self.ora_env_dict) else "asmoper"
       osasm=self.ora_env_dict["OSASM_GROUP"] if self.ocommon.check_key("OSASM_GROUP",self.ora_env_dict) else "asmadmin"
       unixgrp="oinstall"
       hostname=self.ocommon.get_public_hostname()
       lang=self.ora_env_dict["LANGUAGE"] if self.ocommon.check_key("LANGUAGE",self.ora_env_dict) else "en"

       #copyflag=" -noCopy "
       copyflag=" -noCopy "
       if not self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
          copyflag=" -noCopy "

       oraversion=self.ocommon.get_rsp_version("INSTALL",None)
       version=oraversion.split(".",1)[0].strip()

       ## Clering the dictionary
       self.mythread.clear()
       mythreads=[]
       #self.mythread.clear()
       myproc=[]

       for node in pub_nodes.split(" "):
          #self.crs_sw_install_on_node(giuser,copyflag,crs_nodes,oinv,gihome,gibase,osdba,osoper,osasm,version,node)
          self.ocommon.log_info_message("Running CRS Sw install on node " + node,self.file_name)
          #thread=Thread(target=self.ocommon.crs_sw_install_on_node,args=(giuser,copyflag,crs_nodes,oinv,gihome,gibase,osdba,osoper,osasm,version,node))
          ##thread.setDaemon(True)
          #mythreads.append(thread)

          thread=Process(target=self.ocommon.crs_sw_install_on_node,args=(giuser,copyflag,crs_nodes,oinv,gihome,gibase,osdba,osoper,osasm,version,node))
          #thread.setDaemon(True)
          mythreads.append(thread)
          thread.start()

#       for thread in mythreads:
#          thread.start()
#          sleep(10)
#          self.ocommon.log_info_message("Starting thread ",self.file_name)
 
       for thread in mythreads:  # iterates over the threads
          thread.join()       # waits until the thread has finished work       
          self.ocommon.log_info_message("Joining the threads ",self.file_name)

   def crs_config_install(self):
       """
       This function performs the crs software install on all the nodes
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
                self.ocommon.log_info_message("networkInterfaceList parameter is found from response file in line:" + line, self.file_name)
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
                        except Exception as e:
                            self.ocommon.log_warning_message(f"Failed to retrieve subnet mask for {nwname} using ocommon, using default (may be inaccurate)", self.file_name)
                            subnet_mask = "255.255.255.0"  # Default subnet mask if retrieval fails
                            self.ocommon.log_info_message(f"Default subnet mask used: {subnet_mask}", self.file_name)

                    netmasklist += f"{nwname}:{subnet_mask},"

       # Remove the trailing comma
       netmasklist = netmasklist[:-1]
       self.ocommon.log_info_message("netmasklist parameter is set and returned from parse_gridrsp_file method:" + netmasklist ,self.file_name)
       return netmasklist

   def check_responsefile(self):
       """
        This function returns the valid response file
       """
       gridrsp=None
       netmasklist = ""
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
          gridrsp=self.ora_env_dict["GRID_RESPONSE_FILE"]
          self.ocommon.log_info_message("GRID_RESPONSE_FILE parameter is set and file location is:" + gridrsp ,self.file_name)
          netmasklist = self.parse_gridrsp_file(gridrsp)
          self.ocommon.log_info_message("netmasklist parameter is set to:" + netmasklist ,self.file_name)

       if os.path.isfile(gridrsp):
          return gridrsp, netmasklist
       else:
          self.ocommon.log_error_message("Grid response file does not exist at its location: " + gridrsp + ".Exiting..",self.file_name)
          self.ocommon.prog_exit("127")

   def prepare_responsefile(self):
       """
       This function prepare the response file if no response file passed
       """
       self.ocommon.log_info_message("Preparing Grid responsefile.",self.file_name)
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
       self.ocommon.log_info_message("oraversion" + oraversion, self.file_name)
       disksWithFGNames=asmdisk.replace(',',',,') + ','
       self.ocommon.log_info_message("disksWithFGNames" + disksWithFGNames, self.file_name)
       gridrsp="/tmp/grid.rsp"
    
       version=oraversion.split(".",1)[0].strip()
       self.ocommon.log_info_message("disk" + version, self.file_name)
       if int(version) < 23: 
         if self.ocommon.check_key("CRS_GPC",self.ora_env_dict):
            clsnodes=None
         return self.get_responsefile(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,crsconfig)
       else:
          return self.get_23c_responsefile(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,clusterusage)


   def get_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,crsconfig):
       """
       This function prepare the response file if no response file passed
       """      
       self.ocommon.log_info_message("I am in get_responsefile", self.file_name)
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
#      fdata="\n".join([s for s in rspdata.split("\n") if s])
       self.ocommon.write_file(gridrsp,rspdata)
       if os.path.isfile(gridrsp):
          return gridrsp,netmasklist
       else:
          self.ocommon.log_error_message("Grid response file does not exist at its location: " + gridrsp + ".Exiting..",self.file_name)
          self.ocommon.prog_exit("127")

   def get_23c_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist,clusterusage):
       """
       This function prepare the response file if no response file passed
       """
       self.ocommon.log_info_message("I am in get_23c_responsefile", self.file_name)
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
       configureAFD=false
       executeRootScript=false
       ignoreDownNodes=false
       managementOption=NONE
       '''.format(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,oraversion,clusterusage,disksWithFGNames)
#      fdata="\n".join([s for s in rspdata.split("\n") if s])
       self.ocommon.write_file(gridrsp,rspdata)
       if os.path.isfile(gridrsp):
          return gridrsp,netmasklist
       else:
          self.ocommon.log_error_message("Grid response file does not exist at its location: " + gridrsp + ".Exiting..",self.file_name)
          self.ocommon.prog_exit("127")

   def check_crs_config_install(self,swdata):
       """
       This function check the if the sw install went fine
       """
       #if not self.ocommon.check_substr_match(swdata,"orainstRoot.sh"):
       #   self.ocommon.log_error_message("Grid software install failed. Exiting...",self.file_name)
       #   self.ocommon.prog_exit("127")
       if not self.ocommon.check_substr_match(swdata,"root.sh"):
          self.ocommon.log_error_message("Grid software install failed. Exiting...",self.file_name)
          self.ocommon.prog_exit("127")        
       if not self.ocommon.check_substr_match(swdata,"executeConfigTools -responseFile"):
          self.ocommon.log_error_message("Grid software install failed. Exiting...",self.file_name)
          self.ocommon.prog_exit("127")

   def check_crs_sw_install(self,swdata):
       """
       This function check the if the sw install went fine
       """
       if not self.ocommon.check_substr_match(swdata,"orainstRoot.sh"):
          self.ocommon.log_error_message("Grid software install failed. Exiting...",self.file_name)
          self.ocommon.prog_exit("127")
       if not self.ocommon.check_substr_match(swdata,"root.sh"):
          self.ocommon.log_error_message("Grid software install failed. Exiting...",self.file_name)
          self.ocommon.prog_exit("127")

   def run_orainstsh(self):
       """
       This function run the orainst after grid setup
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       for node in pub_nodes.split(" "):
           cmd='''su - {0}  -c "ssh {1}  sudo {2}/orainstRoot.sh"'''.format(giuser,node,oinv)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
           self.ocommon.check_os_err(output,error,retcode,True)
          
   def run_rootsh(self):
       """
       This function run the root.sh after grid setup
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       # Clear the dict
       self.mythread.clear()
       mythreads=[]
       for node in pub_nodes.split(" "):
         oraversion=self.ocommon.get_rsp_version("INSTALL",None)
         version = oraversion.split(".", 1)[0].strip()
         self.ocommon.log_info_message("oraversion" + version, self.file_name)
         if int(version) == 19 or int(version) == 21:
             self.run_rootsh_on_node(node,giuser,gihome)
         else:
           self.ocommon.log_info_message("Running root.sh on node " + node,self.file_name)
           thread=Process(target=self.run_rootsh_on_node,args=(node,giuser,gihome))
           mythreads.append(thread)
           thread.start()
           for thread in mythreads:  # iterates over the threads
              thread.join()       # waits until the thread has finished wor
              self.ocommon.log_info_message("Joining the root.sh thread ",self.file_name)

   def run_rootsh_on_node(self,node,giuser,gihome):
       """
       This function run root.sh on a node
       """
       cmd='''su - {0}  -c "ssh {1}  sudo {2}/root.sh"'''.format(giuser,node,gihome)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,True)
#       if len(self.mythread) > 0:
#          if node in self.mythread.keys():
#             swthread_list=self.mythread[node]
#             value=swthread_list[0]
#             new_list=[value,'FALSE']
#             new_val={node,tuple(new_list)}
#             self.mythread.update(new_val)

   def run_postroot(self,gridrsp):
       """
       This function execute the post root steps:
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       cmd='''su - {0} -c "{1}/gridSetup.sh -executeConfigTools -responseFile {2} -silent"'''.format(giuser,gihome,gridrsp)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None) 

   def reset_systemd(self):
      """
      This function reset the systemd
      This function reset the systemd
      """
      pass
      while True:
         self.ocommon.log_info_message("Root.sh is running. Resetting systemd to avoid failure.",self.file_name)
         cmd='''systemctl reset-failed'''.format()
         cmd='''systemctl reset-failed'''.format()
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         self.ocommon.check_os_err(output,error,retcode,None)
         cmd = '''systemctl is-system-running'''.format()
         cmd = '''systemctl is-system-running'''.format()
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         self.ocommon.check_os_err(output,error,retcode,None)
         sleep(3)
         if self.stopThreaFlag:
            break
   def reset_failed_units_on_all_nodes(self):
      pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
      for node in pub_nodes.split(" "):
         self.ocommon.log_info_message("Running reset_failed_units() on node " + node,self.file_name)
         self.reset_failed_units(node)

   def reset_failed_units(self,node):
      RESET_FAILED_SYSTEMD = 'true'
      SERVICE_NAME = "rhnsd"
      SCRIPT_DIR = "/opt/scripts/startup/scripts"
      RESET_FAILED_UNITS = "resetFailedUnits.sh"
      GRID_USER = "grid"
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
                  output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                  self.ocommon.check_os_err(output,error,retcode,None)
                  cmd='''su - {0} -c "ssh {1}  sudo systemctl disable {2}"'''.format(giuser,node,SERVICE_NAME)
                  output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                  self.ocommon.check_os_err(output,error,retcode,None)
                  self.ocommon.log_info_message(SERVICE_NAME + "stopped.",self.file_name)
               else:
                  self.ocommon.log_info_message(SERVICE_NAME + " is responsive. No action needed.",self.file_name)
         else:
               self.ocommon.log_info_message(SERVICE_NAME + " is not running.",self.file_name)

         self.ocommon.log_info_message("Setting Crontab",self.file_name)         
         cmd = '''su - {0} -c "ssh {1} 'sudo crontab -l | {{ cat; echo \\"{2} {3}/{4}\\"; }} | sudo crontab -'"'''.format(giuser, node, CRON_JOB_FREQUENCY, SCRIPT_DIR, RESET_FAILED_UNITS)
         try:
               output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
               self.ocommon.check_os_err(output,error,retcode,None)             
               self.ocommon.log_info_message("Successfully installed " + SCRIPT_DIR + "/" + RESET_FAILED_UNITS + " using crontab",self.file_name)
         except subprocess.CalledProcessError:
               error_exit("Error occurred in crontab setup")

   def install_cvuqdisk_on_all_nodes(self):
      pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
      for node in pub_nodes.split(" "):
         self.ocommon.log_info_message("Running install_cvuqdisk() on node " + node,self.file_name)
         self.install_cvuqdisk(node)

   def install_cvuqdisk(self,node):
      rpm_directory = "/u01/app/23c/grid/cv/rpm"
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      try:
         # Construct the rpm command using wildcard for version
         cmd = '''su - {0} -c "ssh {1} 'sudo rpm -Uvh {2}/cvuqdisk-*.rpm'"'''.format(giuser, node, rpm_directory)
         # Run the rpm command using subprocess
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         self.ocommon.check_os_err(output,error,retcode,None)             
         self.ocommon.log_info_message("Successfully installed cvuqdisk file.",self.file_name)
         
      except subprocess.CalledProcessError as e:
         self.ocommon.log_error_message("Error installing cvuqdisk. Exiting..." + e,self.file_name)
