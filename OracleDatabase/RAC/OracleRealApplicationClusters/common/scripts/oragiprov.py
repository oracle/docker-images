#!/usr/bin/python3

#############################
# Copyright 2021, Oracle Corporation and/or affiliates.  All rights reserved.
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
           self.ocommon.log_info_message("Start perform_ssh_setup()",self.file_name)
           self.perform_ssh_setup()
           self.ocommon.log_info_message("End perform_ssh_setup()",self.file_name)
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
       if not self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict) and not self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict):
         user=self.ora_env_dict["GRID_USER"]
         ohome=self.ora_env_dict["GRID_HOME"]
         self.osetupssh.setupssh(user,ohome,"INSTALL")
         if self.ocommon.check_key("VERIFY_SSH",self.ora_env_dict):
            self.osetupssh.verifyssh(user,"INSTALL")
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
           gridrsp=self.check_responsefile()  
       else:
          gridrsp,netmasklist=self.prepare_responsefile()
    
       if self.ocommon.check_key("PERFORM_CVU_CHECKS",self.ora_env_dict): 
          self.ocvu.cluvfy_checkrspfile(gridrsp,self.ora_env_dict["GRID_HOME"],self.ora_env_dict["GRID_USER"])
       cmd=self.ocommon.get_sw_cmd("INSTALL",gridrsp,None,netmasklist)    
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)
       self.check_crs_config_install(output)

       return gridrsp

   def check_responsefile(self):
       """
        This function returns the valid response file
       """
       gridrsp=None 
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
          gridrsp=self.ora_env_dict["GRID_RESPONSE_FILE"]
          self.ocommon.log_info_message("GRID_RESPONSE_FILE parameter is set and file location is:" + gridrsp ,self.file_name)

       if os.path.isfile(gridrsp):
          return gridrsp
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
       scanname=self.ora_env_dict["SCAN_NAME"]
       scanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else "1521"
       clutype=self.ora_env_dict["CLUSTER_TYPE"] if self.ocommon.check_key("CLUSTER_TYPE",self.ora_env_dict) else "STANDALONE"
       cluname=self.ora_env_dict["CLUSTER_NAME"] if self.ocommon.check_key("CLUSTER_NAME",self.ora_env_dict) else "racnode-c"
       clunodes=self.ocommon.get_crsnodes()
       nwiface,netmasklist=self.ocommon.get_nwifaces()
       gimrflag=self.ora_env_dict["GIMR_FLAG"] if self.ocommon.check_key("GIMR",self.ora_env_dict)  else "false" 
       passwd=self.ocommon.get_asm_passwd().replace('\n', ' ').replace('\r', '')
       dgname=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "DATA"
       fgname=asmfg_disk
       asmdisk=asm_disk
       discovery_str=self.ocommon.build_asm_discovery_str("CRS_ASM_DEVICE_LIST")
       asmstr=self.ora_env_dict["CRS_ASM_DISK_DISCOVERY_STR"] if self.ocommon.check_key("CRS_ASM_DISK_DISCOVERY_STR",self.ora_env_dict) else discovery_str
       oraversion=self.ocommon.get_rsp_version("INSTALL",None)
       self.ocommon.log_info_message("oraversion" + oraversion, self.file_name)
       disksWithFGNames=asmdisk.replace(',',',,') + ','
       self.ocommon.log_info_message("disksWithFGNames" + disksWithFGNames, self.file_name)
       gridrsp="/tmp/grid.rsp"
    
       version=oraversion.split(".",1)[0].strip()
       self.ocommon.log_info_message("disk" + version, self.file_name)
       if int(version) < 23: 
          return self.get_responsefile(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist)
       else:
          return self.get_23c_responsefile(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist)


   def get_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist):
       """
       This function prepare the response file if no response file passed
       """      
       self.ocommon.log_info_message("I am in get_responsefile", self.file_name)
       rspdata='''
       oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{15} 
       oracle.install.option=CRS_CONFIG
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
       oracle.install.crs.config.storageOption=
       oracle.install.asm.SYSASMPassword={9}
       oracle.install.asm.diskGroup.name={10}
       oracle.install.asm.diskGroup.redundancy={11}
       oracle.install.asm.diskGroup.AUSize=4
       oracle.install.asm.diskGroup.disksWithFailureGroupNames={18}
       oracle.install.asm.diskGroup.disks={13}
       oracle.install.asm.diskGroup.quorumFailureGroupNames=
       oracle.install.asm.diskGroup.diskDiscoveryString={14}
       oracle.install.asm.monitorPassword={9}
       oracle.install.crs.rootconfig.configMethod=ROOT
       oracle.install.asm.configureAFD=false
       oracle.install.crs.rootconfig.executeRootScript=false
       oracle.install.crs.config.ignoreDownNodes=false
       oracle.install.config.managementOption=NONE
       oracle.install.crs.configureRHPS={16}
       oracle.install.crs.config.ClusterConfiguration={17}
       '''.format(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,oraversion,"false","STANDALONE",disksWithFGNames)
#      fdata="\n".join([s for s in rspdata.split("\n") if s])
       self.ocommon.write_file(gridrsp,rspdata)
       if os.path.isfile(gridrsp):
          return gridrsp,netmasklist
       else:
          self.ocommon.log_error_message("Grid response file does not exist at its location: " + gridrsp + ".Exiting..",self.file_name)
          self.ocommon.prog_exit("127")

   def get_23c_responsefile(self,obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,disksWithFGNames,oraversion,gridrsp,netmasklist):
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
       sysasmPassword={9}
       diskGroupName={10}
       redundancy={11}
       auSize=4
       disksWithFailureGroupNames={17}
       diskList={13}
       quorumFailureGroupNames=
       diskString={14}
       asmsnmpPassword={9}
       configMethod=ROOT
       configureAFD=false
       executeRootScript=false
       ignoreDownNodes=false
       managementOption=NONE
       '''.format(obase,invloc,scanname,scanport,clutype,cluname,clunodes,nwiface,gimrflag,passwd,dgname,dgred,fgname,asmdisk,asmstr,oraversion,"RAC",disksWithFGNames)
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
         self.ocommon.log_info_message("Running root.sh on node " + node,self.file_name)
         thread=Process(target=self.run_rootsh_on_node,args=(node,giuser,gihome))
         #thread.setDaemon(True)
         mythreads.append(thread)
         thread.start()
         thread.join() 
         self.ocommon.log_info_message("Joining the root.sh thread inside for loop in serial order",self.file_name)

#       for thread in mythreads:
#          thread.start()
#          sleep(10)
#          self.ocommon.log_info_message("Starting root.sh thread ",self.file_name)

      #  for thread in mythreads:  # iterates over the threads
         #  thread.join()       # waits until the thread has finished wor
         #  self.ocommon.log_info_message("Joining the root.sh thread ",self.file_name)

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

   def reset_systemd(self,giuser,node):
      """
      This function reset the systmd
      """
      pass
      while True:
         self.ocommon.log_info_message("Root.sh is running. Resetting systemd to avoid failure.",self.file_name)
         cmd='''su - {0}  -c "ssh {1} sudo systemctl reset-failed"'''.format(giuser,node)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         self.ocommon.check_os_err(output,error,retcode,None)
         cmd='''su - {0}  -c "ssh {1} sudo systemctl is-system-running"'''.format(giuser,node)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         self.ocommon.check_os_err(output,error,retcode,None)
         sleep(3)
         if self.stopThreaFlag:
            break
