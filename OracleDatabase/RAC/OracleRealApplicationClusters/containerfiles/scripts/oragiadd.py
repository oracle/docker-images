#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file contains to the code call different classes objects based on setup type
"""

import os
import sys
import traceback

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oracvu import *
from oragiprov import *

class OraGIAdd:
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
         self.ocvu                = oracvu
         self.osetupssh           = orasetupssh
         self.ogiprov             = OraGIProv(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)

      except BaseException as ex:
         traceback.print_exc(file = sys.stdout)

   def setup(self):
         """
         This function setup the grid on this machine
         """
         self.ocommon.log_info_message("Start setup()",self.file_name)
         ct = datetime.datetime.now()
         bts = ct.timestamp()
         giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
         pubhostname = self.ocommon.get_public_hostname()
         retcode1=self.ocvu.check_home(pubhostname,gihome,giuser)
         if retcode1 == 0:
           bstr="Grid home is already installed on this machine"
           self.ocommon.log_info_message(self.ocommon.print_banner(bstr),self.file_name)
         if self.ocommon.check_key("GI_HOME_INSTALLED_FLAG",self.ora_env_dict):
           bstr="Grid is already configured on this machine"
           self.ocommon.log_info_message(self.ocommon.print_banner(bstr),self.file_name)
         else:
           self.env_param_checks()
           self.ocommon.log_info_message("Start perform_ssh_setup()",self.file_name)
           self.perform_ssh_setup()
           self.ocommon.log_info_message("End perform_ssh_setup()",self.file_name)
           if self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
            self.ocommon.log_info_message("Start crs_sw_install()",self.file_name)
            self.ogiprov.crs_sw_install()
            self.ocommon.log_info_message("End crs_sw_install()",self.file_name)
            self.ogiprov.run_orainstsh()
            self.ocommon.log_info_message("Start ogiprov.run_rootsh()",self.file_name)
            self.ogiprov.run_rootsh()
            self.ocommon.log_info_message("End ogiprov.run_rootsh()",self.file_name)
           self.ocvu.check_addnode()
           self.ocommon.log_info_message("Start crs_sw_configure()",self.file_name)
           gridrsp=self.crs_sw_configure()
           self.ocommon.log_info_message("End crs_sw_configure()",self.file_name)
           self.run_orainstsh()
           self.ocommon.log_info_message("Start run_rootsh()",self.file_name)
           self.run_rootsh()
           self.ocommon.log_info_message("End run_rootsh()",self.file_name)
           pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
           crs_nodes=pub_nodes.replace(" ",",")
           for node in crs_nodes.split(","):
             self.clu_checks(node)
           if self.ocommon.detect_k8s_env():
               self.ocommon.run_custom_scripts("CUSTOM_GRID_SCRIPT_DIR","CUSTOM_GRID_SCRIPT_FILE",giuser)
               self.ocommon.update_scan(giuser,gihome,None,pubhostname)
               self.ocommon.start_scan(giuser,gihome,pubhostname)
               self.ocommon.update_scan_lsnr(giuser,gihome,pubhostname)
               self.ocommon.start_scan_lsnr(giuser,gihome,pubhostname)
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
#       self.ocommon.check_env_variable("ASM_DISCOVERY_DIR",None)
        
   def scan_check(self):
       """
       Check if scan is set
       """
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
          self.ocommon.log_info_message("GRID_RESPONSE_FILE is set. Ignoring checking SCAN_NAME as CVU will validate responsefile",self.file_name)
       else:
          if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict):
             self.ocommon.log_info_message("SCAN_NAME variable is set: " + self.ora_env_dict["SCAN_NAME"],self.file_name)
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

   def clu_checks(self,hostname):
       """
       Performing clu checks
       """
       self.ocommon.log_info_message("Performing CVU checks before DB home installation to make sure clusterware is up and running",self.file_name)
       retcode1=self.ocvu.check_ohasd(hostname)
       retcode2=self.ocvu.check_asm(hostname)
       retcode3=self.ocvu.check_clu(hostname,None)

       if retcode1 == 0:
          msg="Cluvfy ohasd check passed!"
          self.ocommon.log_info_message(msg,self.file_name)
       else:
          msg="Cluvfy ohasd check faild. Exiting.."
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

       if retcode2 == 0:
          msg="Cluvfy asm check passed!"
          self.ocommon.log_info_message(msg,self.file_name)
       else:
          msg="Cluvfy asm check faild. Exiting.."
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

       if retcode3 == 0:
          msg="Cluvfy clumgr check passed!"
          self.ocommon.log_info_message(msg,self.file_name)
       else:
          msg="Cluvfy clumgr  check faild. Exiting.."
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

   def perform_ssh_setup(self):
       """
       Perform ssh setup
       """
       if not self.ocommon.detect_k8s_env():
           user=self.ora_env_dict["GRID_USER"]
           ohome=self.ora_env_dict["GRID_HOME"]
           self.osetupssh.setupssh(user,ohome,'ADDNODE')
           #if self.ocommon.check_key("VERIFY_SSH",self.ora_env_dict):
              #self.osetupssh.verifyssh(user,'ADDNODE')
       else:
         self.ocommon.log_info_message("SSH setup must be already completed during env setup as this this k8s env.",self.file_name)

   def crs_sw_configure(self):
       """
       This function performs the crs software install on all the nodes
       """
       ohome=self.ora_env_dict["GRID_HOME"]
       gridrsp=""
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
          gridrsp=self.check_responsefile()  
       else:
          gridrsp=self.prepare_responsefile()

       node=""
       nodeflag=False
       existing_crs_nodes=self.ocommon.get_existing_clu_nodes(True)
       for cnode in existing_crs_nodes.split(","):
           retcode3=self.ocvu.check_clu(cnode,True)
           if retcode3 == 0:
              node=cnode
              nodeflag=True
              break

       #self.ocvu.cluvfy_addnode(gridrsp,self.ora_env_dict["GRID_HOME"],self.ora_env_dict["GRID_USER"])
       if node:
          user=self.ora_env_dict["GRID_USER"]
          self.ocommon.scpfile(node,gridrsp,gridrsp,user)
          status=self.ocommon.check_home_inv(None,ohome,user)
          if status:
             self.ocommon.sync_gi_home(node,ohome,user)
          cmd=self.ocommon.get_sw_cmd("ADDNODE",gridrsp,node,None)    
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,None)
          self.ocommon.check_crs_sw_install(output)
       else:
          self.ocommon.log_error_message("Clusterware is not up on any node : " + existing_crs_nodes + ".Exiting...",self.file_name)
          self.ocommon.prog_exit("127")

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
       giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
       ## Variable Assignments
       #asmstr="/dev/asm*"
       x = datetime.datetime.now()
       rspdata=""
       gridrsp='''{1}/grid_addnode_{0}.rsp'''.format(x.strftime("%f"),"/tmp")
       clunodes=self.ocommon.get_crsnodes()
       node=""
       nodeflag=False
       existing_crs_nodes=self.ocommon.get_existing_clu_nodes(True)
       for cnode in existing_crs_nodes.split(","):
           retcode3=self.ocvu.check_clu(cnode,True)
           if retcode3 == 0:
              node=cnode
              nodeflag=True
              break

       if not nodeflag:
          self.ocommon.log_error_message("Unable to find any existing healthy cluster node to verify the cluster status. This can be a ssh problem or cluster is not healthy. Error occurred!")
          self.ocommon.prog_exit("127")
      
       oraversion=self.ocommon.get_rsp_version("ADDNODE",node)

       version=oraversion.split(".",1)[0].strip() 
       if int(version) < 23:
         rspdata='''
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
         '''.format(obase,invloc,clunodes,oraversion,"false")
#        fdata="\n".join([s for s in rspdata.split("\n") if s])
       else:
         rspdata=''' 
           oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v{3}
           oracle.install.option=CRS_ADDNODE
           ORACLE_BASE={0}
           INVENTORY_LOCATION={1}
           OSDBA=asmdba
           OSOPER=asmoper
           OSASM=asmadmin
           clusterNodes={2}
           configMethod=ROOT
           configureAFD=false
           executeRootScript=false
         '''.format(obase,invloc,clunodes,oraversion,"false")

       self.ocommon.write_file(gridrsp,rspdata)
       if os.path.isfile(gridrsp):
         return gridrsp
       else:
        self.ocommon.log_error_message("Grid response file does not exist at its location: " + gridrsp + ".Exiting..",self.file_name)
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
       for node in pub_nodes.split(" "):
           cmd='''su - {0}  -c "ssh {1}  sudo {2}/root.sh"'''.format(giuser,node,gihome)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
           self.ocommon.check_os_err(output,error,retcode,True) 
