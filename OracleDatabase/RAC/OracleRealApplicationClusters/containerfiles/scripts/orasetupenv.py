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
from orasshsetup import *
from oracvu import *

import os
import re
import sys
import itertools
from time import sleep, perf_counter
#from threading import Thread
from multiprocessing import Process

class OraSetupEnv:
    """
    This class setup the env before setting up the rac env
    """
    def __init__(self,oralogger,orahandler,oraenv,oracommon,oracvu,orasetupssh):
      try:
         self.ologger             = oralogger
         self.ohandler            = orahandler
         self.oenv                = oraenv.get_instance()
         self.ocommon             = oracommon
         self.ocvu                = oracvu
         self.osetupssh           = orasetupssh
         self.ora_env_dict        = oraenv.get_env_vars()
         self.file_name           = os.path.basename(__file__)
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
        if self.ocommon.check_key("RESET_PASSWORD",self.ora_env_dict):
           self.ocommon.log_info_message("RESET_PASSWORD variable is set. Resetting the OS password for users: " + self.ora_env_dict["RESET_PASSWORD"],self.file_name)
           for user in self.ora_env_dict["RESET_PASSWORD"].split(','):
               self.ocommon.reset_os_password(user)
        elif self.ocommon.check_key("CUSTOM_RUN_FLAG",self.ora_env_dict):
           self.populate_env_vars() 
        else:
         if self.ocommon.check_key("DBCA_RESPONSE_FILE",self.ora_env_dict):
            self.ocommon.update_rac_env_vars_from_rspfile(self.ora_env_dict["DBCA_RESPONSE_FILE"])
         if not self.ocommon.check_key("SINGLE_NETWORK",self.ora_env_dict):
            install_node,pubhost=self.ocommon.get_installnode()
            if install_node.lower() == pubhost.lower():
               if not self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
                  self.validate_private_nodes()
         #self.ocommon.update_domainfrom_resolvconf_file()
         self.populate_env_vars()
         self.check_statefile()
         self.env_var_checks()
         self.stdby_env_var_checks()
         self.set_gateway()
         self.add_ntp_conf()
         self.touch_fstab()
         self.reset_systemd()
         self.check_systemd()
         self.set_ping_permission()
         self.set_common_script()
         self.add_domain_search()
         self.add_dns_servers()
         self.populate_etchosts("localhost")
         self.populate_user_profiles()
         #self.setup_ssh_for_k8s()
         self.setup_gi_sw()
         self.set_asmdev_perm()
         self.reset_grid_user_passwd()        
         self.setup_db_sw()
         self.adjustMemlockLimits()
         self.reset_db_user_passwd()
        # self.ocommon.log_info_message("Start crs_sw_install()",self.file_name)
        # self.crs_sw_install()
        # self.ocommon.log_info_message("End crs_sw_install()",self.file_name)
         self.setup_ssh_for_k8s()
         self.set_banner()

        ct = datetime.datetime.now()
        ets = ct.timestamp()
        totaltime=ets - bts
        self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)
 
      ###########  SETUP_MACHINE ENDS here ####################

    ## Function to perfom DB checks ######
    def populate_env_vars(self):
        """
        Populate the env vars if not set
        """
        self.ocommon.populate_rac_env_vars()
        if self.ocommon.check_key("CRS_GPC",self.ora_env_dict):
           if self.ocommon.ora_env_dict["CRS_GPC"].lower() == 'true':
              self.ora_env_dict=self.ocommon.add_key("DB_CONFIG_TYPE","SINGLE",self.ora_env_dict)
           pubnode=self.ocommon.get_public_hostname()
           crs_nodes="pubhost="+pubnode
           if not self.ocommon.check_key("CRS_NODES",self.ora_env_dict):
              self.ora_env_dict=self.ocommon.add_key("CRS_NODES",crs_nodes,self.ora_env_dict)
           else:
              self.ora_env_dict=self.ocommon.update_key("CRS_NODES",crs_nodes,self.ora_env_dict)
        else:
         if not self.ocommon.check_key("CRS_NODES",self.ora_env_dict):
            msg="CRS_NODES is not passed as an env variable. If CRS_NODES is not passed as env variable then user must pass PUBLIC_HOSTS,VIRTUAL_HOSTS and PRIVATE_HOST as en env variable so that CRS_NODES can be populated."
            self.ocommon.log_error_message(msg,self.file_name)
            self.populate_crs_nodes()

    def check_statefile(self):
       """
       populate the state file
       """
       file=self.oenv.statelogfile_name()
       if not self.ocommon.check_file(file,"local",None,None):
          self.ocommon.create_file(file,"local",None,None)
       if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
         if self.ora_env_dict["OP_TYPE"] == 'setuprac':
           self.ocommon.update_statefile("provisioning")
         elif self.ora_env_dict["OP_TYPE"] == 'nosetup':
           self.ocommon.update_statefile("provisioning")
         elif self.ora_env_dict["OP_TYPE"] == 'addnode':
            self.ocommon.update_statefile("addnode")
         else:
            pass
          
    def populate_crs_nodes(self):
        """
        Populate CRS_NODES variable using PUBLIC_HOSTS,VIRTUAL_HOSTS and PRIVATE_HOSTS
        """
        pub_node_list=[]
        virt_node_list=[]
        priv_node_list=[]

        crs_nodes=""
        if not self.ocommon.check_key("PUBLIC_HOSTS",self.ora_env_dict):
           self.ocommon.log_error_message("PUBLIC_HOSTS list is not found in env variable list.Exiting...",self.file_name)
           self.ocommon.prog_exit("127")
        else:
           pub_node_list=self.ora_env_dict["PUBLIC_HOSTS"].split(",")

        if not self.ocommon.check_key("VIRTUAL_HOSTS",self.ora_env_dict):
           self.ocommon.log_error_message("VIRTUAL_HOSTS list is not found in env variable list.Exiting...",self.file_name)
           self.ocommon.prog_exit("127")
        else:
           virt_node_list=self.ora_env_dict["VIRTUAL_HOSTS"].split(",")

        if not self.ocommon.check_key("CRS_PRIVATE_IP1",self.ora_env_dict) and not self.ocommon.check_key("CRS_PRIVATE_IP2",self.ora_env_dict):
          if self.ocommon.check_key("PRIVATE_HOSTS",self.ora_env_dict):
              priv_node_list=self.ora_env_dict["PRIVATE_HOSTS"].split(",")

        if not self.ocommon.check_key("SINGLE_NETWORK",self.ora_env_dict): 
           if len(pub_node_list) == len(virt_node_list) and len(pub_node_list) == len(priv_node_list):
              for (pubnode,vipnode,privnode) in zip(pub_node_list,virt_node_list,priv_node_list):
                 crs_nodes= crs_nodes + "pubhost=" + pubnode + "," + "viphost=" + vipnode + "," + "privhost=" + privnode + ";"
           else:
             if len(pub_node_list) == len(virt_node_list):
                for (pubnode,vipnode,privnode) in zip(pub_node_list,virt_node_list):                 
                   crs_nodes= crs_nodes + "pubhost=" + pubnode + "," + "viphost=" + vipnode + ";"
             else:
                self.ocommon.log_error_message("public node and virtual host node count is not equal",self.file_name)
                self.ocommon.prog_exit("127")               
        else:
           if len(pub_node_list) == len(virt_node_list):
              for (pubnode,vipnode,privnode) in zip(pub_node_list,virt_node_list):
                 crs_nodes= crs_nodes + "pubhost=" + pubnode + "," + "viphost=" + vipnode + ";"              
        
        crs_nodes=crs_nodes.strip(";")
        self.ora_env_dict=self.ocommon.add_key("CRS_NODES",crs_nodes,self.ora_env_dict)
        self.ocommon.log_info_message("CRS_NODES is populated: " + self.ora_env_dict["CRS_NODES"] ,self.file_name)

    def validate_private_nodes(self):
        """
        This function validate the private network
        """
        priv_node_status=False

        if self.ocommon.check_key("PRIVATE_HOSTS",self.ora_env_dict):
           priv_node_status=True
           priv_node_list=self.ora_env_dict["PRIVATE_HOSTS"].split(",")
        else:
           self.ocommon.log_info_message("PRIVATE_HOSTS is not set.",self.file_name)

        if self.ocommon.check_key("CRS_GPC",self.ora_env_dict):
           pubnode=self.ocommon.get_public_hostname()
           domain=self.ora_env_dict["PUBLIC_HOSTS_DOMAIN"] if self.ocommon.check_key("PUBLIC_HOSTS_DOMAIN",self.ora_env_dict) else self.ocommon.get_host_domain()
           if domain is None:
               self.ocommon.log_error_message("PUBLIC_HOSTS_DOMAIN is not set.",self.file_name)
           value=self.ocommon.get_ip(pubnode,domain)
           if not self.ocommon.check_key("CRS_PRIVATE_IP1",self.ora_env_dict):
            self.ora_env_dict=self.ocommon.add_key("CRS_PRIVATE_IP1",value,self.ora_env_dict)
           else:   
            self.ora_env_dict=self.ocommon.update_key("CRS_PRIVATE_IP1",value,self.ora_env_dict)
           priv_node_status=True
        else:
         if self.ocommon.check_key("CRS_PRIVATE_IP1",self.ora_env_dict):
            priv_node_status=True
            priv_ip1_list=self.ora_env_dict["CRS_PRIVATE_IP1"].split(",")
            for ip in priv_ip1_list:
                  self.ocommon.ping_ip(ip,True)
         else:
            self.ocommon.log_info_message("CRS_PRIVATE_IP1 is not set.",self.file_name)

         if self.ocommon.check_key("CRS_PRIVATE_IP2",self.ora_env_dict):
            priv_node_status=True
            priv_ip2_list=self.ora_env_dict["CRS_PRIVATE_IP2"].split(",")
            for ip in priv_ip2_list:
                  self.ocommon.ping_ip(ip,True)
         else:
            self.ocommon.log_info_message("CRS_PRIVATE_IP2 is not set.",self.file_name)

        if not priv_node_status:
           self.ocommon.log_error_message("PRIVATE_HOSTS or CRS_PRIVATE_IP1 or CRS_PRIVATE_IP2 list is not found in env variable list.Exiting...",self.file_name)
           self.ocommon.prog_exit("127")

    def env_var_checks(self):
        """
        check the env vars
        """
        self.ocommon.check_env_variable("GRID_HOME",True)
        self.ocommon.check_env_variable("GRID_BASE",True)
        self.ocommon.check_env_variable("INVENTORY",True)
        self.ocommon.check_env_variable("DB_HOME",False)
        self.ocommon.check_env_variable("DB_BASE",False)

    def stdby_env_var_checks(self):
        """
        Check the stby env variable
        """
        if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
           if self.ora_env_dict["OP_TYPE"] == 'setupracstandby':
             self.ocommon.check_env_variable("DB_UNIQUE_NAME",False)
             self.ocommon.check_env_variable("PRIMARY_DB_SCAN_PORT",False)
             self.ocommon.check_env_variable("PRIMARY_DB_NAME",True)
             self.ocommon.check_env_variable("PRIMARY_DB_SERVICE_NAME",False)
             self.ocommon.check_env_variable("PRIMARY_DB_UNIQUE_NAME",True)
             self.ocommon.check_env_variable("PRIMARY_DB_SCAN_NAME",True)

    def set_gateway(self):
        """
        Set the default gateway
        """
        if self.ocommon.check_key("DEFAULT_GATEWAY",self.ora_env_dict):
            self.ocommon.log_info_message("DEFAULT_GATEWAY variable is set. Validating the gateway gw",self.file_name)
            if self.ocommon.validate_ip(self.ora_env_dict["DEFAULT_GATEWAY"]):
                #cmd='''ip route; ip route del default'''
                cmd='''ip route; ip route flush 0/0;ip route'''
                output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                self.ocommon.check_os_err(output,error,retcode,None)
                ### Set the Default gw
                self.ocommon.log_info_message("Setting default gateway based on new gateway setting",self.file_name)
                cmd='''route add default gw {0}'''.format(self.ora_env_dict["DEFAULT_GATEWAY"])
                output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                self.ocommon.check_os_err(output,error,retcode,None)
            else:
                self.ocommon.log_error_message("DEFAULT_GATEWAY IP is not correct. Exiting..",self.file_name)
                self.ocommon.prog_exit("NONE")

    def add_ntp_conf(self):
        """
        This function start the NTP daemon
        """
        if self.ocommon.check_key("NTP_START",self.ora_env_dict):
            self.ocommon.log_info_message("NTP_START variable is set. Touching /etc/ntpd.conf",self.file_name)
            cmd='''touch /etc/ntp.conf'''
            output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
            self.ocommon.check_os_err(output,error,retcode,True)
            ### Start NTP
            self.ocommon.log_info_message("NTP_START variable is set. Starting NTPD",self.file_name)
            cmd='''systemctl start ntpd'''
            output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
            self.ocommon.check_os_err(output,error,retcode,True)

    def populate_etchosts(self,entry):
        """
        Populating hosts file
        """
        cmd=None
        etchostfile="/etc/hosts"
        if not self.ocommon.detect_k8s_env(): 
            if self.ocommon.check_key("HOSTFILE",self.ora_env_dict):
               if os.path.exists(self.ora_env_dict["HOSTFILE"]):
                  cmd='''cat {0} > /etc/hosts'''.format(self.ora_env_dict["HOSTFILE"])
                  output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
            else:
               lentry='''127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 \n::1   localhost localhost.localdomain localhost6 localhost6.localdomain6'''
               
               self.write_etchost("localhost.localdomain",etchostfile,"write",lentry)
               if not self.ocommon.check_key("CRS_GPC",self.ora_env_dict):
                  if self.ocommon.check_key("CRS_NODES",self.ora_env_dict):
                     pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
                     pub_nodes1=pub_nodes.replace(" ",",")
                     vip_nodes1=vip_nodes.replace(" ",",")
                     for node in pub_nodes1.split(","):
                           self.ocommon.log_info_message("The node set to :" +  node + "-" + pub_nodes1,self.file_name)
                           self.write_etchost(node,etchostfile,"append",None)
                     for node in vip_nodes1.split(","):
                           self.write_etchost(node,etchostfile,"append",None)
                                                    
    def write_etchost(self,node,file,mode,lentry):
       """
       This funtion write an entry to /etc/host if the entry doesn't exit
       """
       if node == "":
          self.ocommon.log_info_message("write_etchost(): Node is : [NULL]. PASS",self.file_name)
          return
       if mode == 'append':
          #fdata=self.ocommon.read_file(file)
          #match=re.search(node,fdata,re.MULTILINE)
          #if not match:
           domain=self.ora_env_dict["PUBLIC_HOSTS_DOMAIN"] if self.ocommon.check_key("PUBLIC_HOSTS_DOMAIN",self.ora_env_dict) else self.ocommon.get_host_domain()
           if domain is None:
               self.ocommon.log_error_message("PUBLIC_HOSTS_DOMAIN is not set.",self.file_name)
           if self.ocommon.check_key("PUBLIC_HOSTS_DOMAIN",self.ora_env_dict):
             self.ora_env_dict=self.ocommon.update_key("PUBLIC_HOSTS_DOMAIN",domain,self.ora_env_dict)
           else:
             self.ora_env_dict=self.ocommon.add_key("PUBLIC_HOSTS_DOMAIN",domain,self.ora_env_dict)
           self.ocommon.log_info_message("Domain is :" + self.ora_env_dict["PUBLIC_HOSTS_DOMAIN"],self.file_name)
           self.ocommon.log_info_message("The hostname :" + node + "." + domain,self.file_name)
           ip=self.ocommon.get_ip(node,domain)
          # self.ocommon.log_info_message(" The Ip set to :", ip)
           entry='''{0}    {1}     {2}'''.format(ip,node + "." + domain,node)
          # self.ocommon.log_info_message(" The  entry set to :", entry)
           cmd='''echo {0} >> {1}'''.format(entry,file)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       elif mode == 'write':
          #fdata=self.ocommon.read_file(file)
          #match=re.search(node,fdata,re.MULTILINE)
          #if not match:
           #self.ocommon.log_info_message(" The  lentry set to :", lentry)
           cmd='''echo "{0}" > "{1}"'''.format(lentry,file)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)                   
       else:
         pass
               
    def touch_fstab(self):
        """
        This function toch fstab
        """
        cmd='''touch /etc/fstab'''
        output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
        self.ocommon.check_os_err(output,error,retcode,True)

    def  reset_systemd(self):
        """
        This function reset the systemd
        """
        self.ocommon.log_info_message("Checking systemd failed units.",self.file_name)
        cmd="""systemctl | grep failed | awk '{ print $2 }'"""
        output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
        self.ocommon.check_os_err(output,error,retcode,True)
        self.ocommon.log_info_message("Disabling failed units.",self.file_name)
        if output:
          for svc in output.split('\n'):
              if svc:
                cmd='''systemctl disable {0}'''.format(svc)
                output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                self.ocommon.check_os_err(output,error,retcode,True)
        self.ocommon.log_info_message("Resetting systemd.",self.file_name)
        cmd='''systemctl reset-failed'''
        output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
        self.ocommon.check_os_err(output,error,retcode,None)
        
    def check_systemd(self):
        """
        This function check systemd and exit the program if systemd status is not running
        """
        self.ocommon.log_info_message("Checking systemd. It must be in running state to setup clusterware inside containers for clusterware.",self.file_name)
        cmd="""systemctl status | awk '/State:/{ print $0 }' | grep -v 'awk /State:/' | awk '{ print $2 }'"""
        output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
        self.ocommon.check_os_err(output,error,retcode,True)
        if 'running' in output:
           self.ocommon.log_info_message("Systemctl status check passed!",self.file_name)
        else:
           self.ocommon.log_error_message("Systemctl is not in running state.",self.file_name)
           #self.ocommon.prog_exit("None")

    def set_ping_permission(self):
        """
        setting ping permission
        """
        pass
        #self.ocommon.log_info_message("Setting ping utility permissions so that it works correctly inside container",self.file_name)
        #cmd='''chmod 6755 /usr/bin/ping;chmod 6755 /bin/ping'''
        #output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
        #self.ocommon.check_os_err(output,error,retcode,None)
        
    def adjustMemlockLimits(self):
      """
      Adjust the soft and hard memory limits for the oracle db
      """
      oracleDBConfigFile=None
      gridDBConfigFile=None
      memoryFile=None
      
      cmd='''mount | grep -i cgroup | awk \'{ print $1 }\''''
      output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
      oraversion=self.ocommon.get_rsp_version("INSTALL",None)
      version=oraversion.split(".",1)[0].strip()
      if int(version) < 23:
         oracleDBConfigFile="/etc/security/limits.d/oracle-database-preinstall-23c.conf"
         gridDBConfigFile="/etc/security/limits.d/grid-database-preinstall-23c.conf"
      else:
         oracleDBConfigFile="/etc/security/limits.d/oracle-database-preinstall-23ai.conf"
         gridDBConfigFile="/etc/security/limits.d/grid-database-preinstall-23ai.conf"
         
      cgroupVersion=output.strip()
      if cgroupVersion == 'cgroup2':
         memoryFile="/sys/fs/cgroup/memory.max"
      else:
         memoryFile="/sys/fs/cgroup/memory/memory.limit_in_bytes"
         
      if self.ocommon.check_file(memoryFile,"local",None,None):
         self.ocommon.log_info_message("memoryFile=[" + memoryFile + "]",self.file_name)

         cmd='''expr `cat {0}` / 1024'''.format(memoryFile)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         containerMemory=output.strip()
         cmd='''expr {0} \* 9 / 10'''.format(containerMemory)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         containerMemory=output.strip()
         self.ocommon.log_info_message("containerMemory=[" + containerMemory + "]",self.file_name)

         cmd='''grep " memlock " {0} | grep -v "^#" | grep hard | awk \'{{ print $4 }}\''''.format(oracleDBConfigFile)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         fileMemlockVal=output.strip()

         cmd='''sed -i -e \'s,{0},{1},g\' {2}'''.format(fileMemlockVal,containerMemory,oracleDBConfigFile)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)

         cmd='''grep " memlock " {0} | grep -v "^#" | grep hard | awk \'{{ print $4 }}\''''.format(gridDBConfigFile)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         fileMemlockVal=output.strip()

         cmd='''sed -i -e \'s,{0},{1},g\' {2}'''.format(fileMemlockVal,containerMemory,gridDBConfigFile)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
        
    def set_common_script(self):
        """
        This function set the 775 permission on common script dir
        """
        if self.ocommon.check_key("COMMON_SCRIPTS",self.ora_env_dict):
            self.ocommon.log_info_message("COMMON_SCRIPTS variable is set.",self.file_name)
            if os.path.isdir(self.ora_env_dict["COMMON_SCRIPTS"]):
                self.ocommon.log_info_message("COMMON_SCRIPT variable is set. Changing permissions and ownership",self.file_name)
                cmd='''chown -R grid:oinstall {0}; chmod 775 {0}'''.format(self.ora_env_dict["COMMON_SCRIPTS"])
                output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                self.ocommon.check_os_err(output,error,retcode,True)
            else:
                self.ocommon.log_info_message("COMMON_SCRIPT variable is set but directory doesn't exist!",self.file_name)

    def set_asmdev_perm(self):
        """
        This function set the correct permissions for ASM Disks
        """
        self.ocommon.set_asmdisk_perm("CRS_ASM_DEVICE_LIST",True)
        self.ocommon.set_asmdisk_perm("REDO_ASM_DEVICE_LIST",None)
        self.ocommon.set_asmdisk_perm("RECO_ASM_DEVICE_LIST",None)
        self.ocommon.set_asmdisk_perm("DB_ASM_DEVICE_LIST",None)
        if self.ocommon.check_key("CLUSTER_TYPE",self.ora_env_dict):
            if self.ora_env_dict["CLUSTER_TYPE"] == 'DOMAIN':
                if self.ocommon.check_key("GIMR_ASM_DEVICE_LIST",self.ora_env_dict):
                   self.ocommon.set_asmdisk_perm("GIMR_ASM_DEVICE_LIST",True) 

    ## Function add DOMAIN Server 
    def add_domain_search(self):
        """
         This function update search in /etc/resolv.conf
        """
        dns_search_flag=None
        search_domain='search'
        if self.ocommon.check_key("PUBLIC_HOSTS_DOMAIN",self.ora_env_dict):
            self.ocommon.log_info_message("PUBLIC_HOSTS_DOMAIN variable is set. Populating /etc/resolv.conf.",self.file_name)
            dns_search_flag=True
            for domain in self.ora_env_dict["PUBLIC_HOSTS_DOMAIN"].split(','):
                search_domain = search_domain + ' ' + domain

        if self.ocommon.check_key("PRIVATE_HOSTS_DOMAIN",self.ora_env_dict):
            self.ocommon.log_info_message("PRIVATE_HOSTS_DOMAIN variable is set. Populating /etc/resolv.conf.",self.file_name)
            dns_search_flag=True
            for domain in self.ora_env_dict["PRIVATE_HOSTS_DOMAIN"].split(','):
                search_domain = search_domain + ' ' + domain

        if self.ocommon.check_key("CUSTOM_DOMAIN",self.ora_env_dict):
            self.ocommon.log_info_message("CUSTOM_DOMAIN variable is set. Populating /etc/resolv.conf.",self.file_name)
            dns_search_flag=True
            for domain in self.ora_env_dict["CUSTOM_DOMAIN"].split(','):
                search_domain = search_domain + ' ' + domain

        if dns_search_flag:
            self.ocommon.log_info_message("Search Domain {0} is ready. Adding enteries in /etc/resolv.conf".format(search_domain),self.file_name)
            cmd='''echo "{0}" > /etc/resolv.conf'''.format(search_domain)
            output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
            self.ocommon.check_os_err(output,error,retcode,True)
        
    ## Function to perfom grid sw installation ######
    def add_dns_servers(self):
        """
        This function add the dns servers
        """
        if self.ocommon.check_key("DNS_SERVERS",self.ora_env_dict):
           self.ocommon.log_info_message("DNS_SERVERS variable is set. Populating /etc/resolv.conf with DNS servers.",self.file_name)
           for server in self.ora_env_dict["DNS_SERVERS"].split(','):
               if server not in open('/etc/resolv.conf').read():
                    cmd='''echo "nameserver  {0}" >> /etc/resolv.conf'''.format(server)
                    output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                    self.ocommon.check_os_err(output,error,retcode,True)
        else:
            self.ocommon.log_info_message("DNS_SERVERS variable is not set.",self.file_name)

    ## Function to perfom oracle sw installation ######
    def setup_gi_sw(self):
      """
      This function unzip the Grid and Oracle Software
      """
      gihome=""
      oinv=""
      gibase=""
      giuser=""
      gigrp=""
      giswfie=""
         ### Unzipping Gi Software
      if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
      #if self.ocommon.check_key("OP_TYPE",self.ora_env_dict) and any(optype == self.ora_env_dict["OP_TYPE"] for optype not in ("racaddnode")):
         if self.ocommon.check_key("STAGING_SOFTWARE_LOC",self.ora_env_dict) and self.ocommon.check_key("GRID_SW_ZIP_FILE",self.ora_env_dict):  
            giswfile=self.ora_env_dict["STAGING_SOFTWARE_LOC"] + "/" + self.ora_env_dict["GRID_SW_ZIP_FILE"]
            if os.path.isfile(giswfile):
                  if not self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
                     self.ora_env_dict=self.ocommon.add_key("COPY_GRID_SOFTWARE","True",self.ora_env_dict) 
                  giuser,gihome,gibase,oinv=self.ocommon.get_gi_params()
                  gigrp=self.ora_env_dict["OINSTALL"]
                  self.ocommon.log_info_message("copy Software flag is set",self.file_name)
                  self.ocommon.log_info_message("Setting up oracle invetnory directory!",self.file_name) 
                  self.setup_sw_dirs(oinv,giuser,gigrp)
                  self.ocommon.log_info_message("Setting up Grid_BASE directory!",self.file_name)
                  self.setup_sw_dirs(gibase,giuser,gigrp)
                  self.ocommon.log_info_message("Setting up Grid_HOME directory!",self.file_name)
                  self.setup_sw_dirs(gihome,giuser,gigrp)
                  dir = os.listdir(gihome)
                  if len(dir) == 0:
                     self.ocommon.log_info_message("Grid software file is set : " + giswfile ,self.file_name)
                     self.ocommon.log_info_message("Starting grid software unzipping file",self.file_name) 
                     cmd='''su - {0} -c \" unzip -q {1} -d {2}\"'''.format(giuser,giswfile,gihome)
                     output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                     self.ocommon.check_os_err(output,error,retcode,True)
                     self.ora_env_dict=self.ocommon.add_key("GI_SW_UNZIPPED_FLAG","true",self.ora_env_dict)
                  else:
                     self.ocommon.log_error_message("oracle gi home directory is not empty. skipping software unzipping...",self.file_name)                                 
            else:
               install_node,pubhost=self.ocommon.get_installnode()
               if install_node.lower() == pubhost.lower():
                  self.ocommon.log_error_message("grid software file " + giswfile + " doesn't exist. Exiting...",self.file_name)
                  self.ocommon.prog_exit("127")
               else:
                  self.ocommon.log_info_message("grid software file " + giswfile + " doesn't exist. software will be copied from install node..." + install_node.lower(),self.file_name)

    ## Function to unzip the software 
    def setup_db_sw(self):
      """
      unzip the software
      """ 
      dbhome=""
      dbbase=""
      dbuser=""
      gigrp=""
      dbswfile=""                                                                    
      ### Unzipping Gi Software
      if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
      #if self.ocommon.check_key("OP_TYPE",self.ora_env_dict) and any(optype == self.ora_env_dict["OP_TYPE"] for optype not in ("racaddnode")):
         if self.ocommon.check_key("STAGING_SOFTWARE_LOC",self.ora_env_dict) and self.ocommon.check_key("DB_SW_ZIP_FILE",self.ora_env_dict):
            dbswfile=self.ora_env_dict["STAGING_SOFTWARE_LOC"] + "/" + self.ora_env_dict["DB_SW_ZIP_FILE"]  
            if os.path.isfile(dbswfile):
               if not self.ocommon.check_key("COPY_DB_SOFTWARE",self.ora_env_dict):
                     self.ora_env_dict=self.ocommon.add_key("COPY_DB_SOFTWARE","True",self.ora_env_dict) 
               dbuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
               gigrp=self.ora_env_dict["OINSTALL"]
               self.ocommon.log_info_message("Copy Software flag is set",self.file_name)
               self.ocommon.log_info_message("Setting up ORACLE_BASE directory!",self.file_name)
               self.setup_sw_dirs(dbbase,dbuser,gigrp)
               self.ocommon.log_info_message("Setting up DB_HOME directory!",self.file_name)
               self.setup_sw_dirs(dbhome,dbuser,gigrp) 
               dir = os.listdir(dbhome)
               if len(dir) == 0:  
                  self.ocommon.log_info_message("DB software file is set : " + dbswfile , self.file_name)
                  self.ocommon.log_info_message("Starting db software unzipping file",self.file_name)
                  cmd='''su - {0} -c \" unzip -q {1} -d {2}\"'''.format(dbuser,dbswfile,dbhome)
                  output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                  self.ocommon.check_os_err(output,error,retcode,True)
                  self.ora_env_dict=self.ocommon.add_key("RAC_SW_UNZIPPED_FLAG","true",self.ora_env_dict)
               else:
                  self.ocommon.log_error_message("oracle db home directory is not empty. skipping software unzipping...",self.file_name) 
            else:
               install_node,pubhost=self.ocommon.get_installnode()
               if install_node.lower() == pubhost.lower():
                  self.ocommon.log_error_message("db software file " + dbswfile + " doesn't exist. exiting...",self.file_name)
                  self.ocommon.prog_exit("127")
               else:
                  self.ocommon.log_info_message("db software file " + dbswfile + " doesn't exist. software will be copied from install node..." + install_node.lower(),self.file_name)
 
    def setup_sw_dirs(self,dir,user,group):
        """
        This function setup the Oracle Software directories if not already created
        """
        if os.path.isdir(dir):
           self.ocommon.log_info_message("Directory " + dir   +  " already exist!",self.file_name)   
        else:
           self.ocommon.log_info_message("Creating dir " + dir,self.file_name)
           cmd='''mkdir -p {0}'''.format(dir)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
           self.ocommon.check_os_err(output,error,retcode,True)         
           ####
           self.ocommon.log_info_message("Changing the permissions of directory",self.file_name)
           cmd='''chown -R {0}:{1} {2}'''.format(user,group,dir)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
           self.ocommon.check_os_err(output,error,retcode,True) 

###### Checking GI Home #######
    def reset_grid_user_passwd(self):
        """
        This function check the Gi home and if it is not setup the it will reset the GI user password
        """
        if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
          if self.ora_env_dict["OP_TYPE"] == 'nosetup':
             if not self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict) and not self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict):
                user=self.ora_env_dict["GRID_USER"]
                self.ocommon.log_info_message("Resetting OS Password for OS user : " + user,self.file_name)
                self.ocommon.reset_os_password(user)
               
###### Checking RAC Home #######
    def reset_db_user_passwd(self):
        """
        This function check the RAC home and if it is not setup the it will reset the DB user password
        """
        if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
          if self.ora_env_dict["OP_TYPE"] == 'nosetup':
             if not self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict) and not self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict):
               user=self.ora_env_dict["DB_USER"]
               self.ocommon.log_info_message("Resetting OS Password for OS user : " + user,self.file_name)
               self.ocommon.reset_os_password(user)
              
###### Setting up parallel Oracle and Grid User setup using Keys ####
    def setup_ssh_using_keys(self,sshi):
        """ 
        Setting up ssh  using keys
        """
        self.ocommon.log_info_message("I am in setup_ssh_using_keys",self.file_name)
        uohome=sshi.split(":")
        self.ocommon.log_info_message("I am in setup_ssh_using_keys + uhome[0] and uhome[1]",self.file_name)
        self.osetupssh.setupsshdirs(uohome[0],uohome[1],None)
        self.osetupssh.setupsshusekey(uohome[0],uohome[1],None)
        #self.osetupssh.verifyssh(uohome[0],None)
  
###### Setting up ssh for K8s #######
    def setup_ssh_for_k8s(self):
        """
        This function setup ssh using private and public key in K8s env
        """
        if self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict) and self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict):
           if self.ocommon.check_file(self.ora_env_dict["SSH_PRIVATE_KEY"],True,None,None) and self.ocommon.check_file(self.ora_env_dict["SSH_PUBLIC_KEY"],True,None,None):
              self.ocommon.log_info_message("Begin SSH Setup using SSH_PRIVATE_KEY and SSH_PUBLIC_KEY",self.file_name)
              giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
              dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
              self.ocvu.cluvfy_updcvucfg(gihome,giuser)
              SSH_USERS=giuser + ":" + gihome,dbuser + ":" + dbhome
              for sshi in SSH_USERS:
                 self.setup_ssh_using_keys(sshi)

              self.ocommon.log_info_message("End SSH Setup using SSH_PRIVATE_KEY and SSH_PUBLIC_KEY",self.file_name)
        else:
          if self.ocommon.detect_k8s_env():
             self.ocommon.log_error_message("SSH_PRIVATE_KEY and SSH_PUBLIC_KEY is ot set in K8s env. Exiting..",self.file_name)
             self.ocommon.prog_exit("127")               
###### Install CRS Software on node ######
    def crs_sw_install(self):
       """
       This function performs the crs software install on all the nodes
       """
       giuser,gihome,gibase,oinv=self.ocommon.get_gi_params()
       status=True
       if not self.ocommon.check_key("GI_HOME_INSTALLED_FLAG",self.ora_env_dict):
          status=self.ocommon.check_home_inv(None,gihome,giuser)
       if not status and self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
          pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
          crs_nodes=pub_nodes.replace(" ",",")
          osdba=self.ora_env_dict["OSDBA_GROUP"] if self.ocommon.check_key("OSDBA",self.ora_env_dict) else "asmdba"
          osoper=self.ora_env_dict["OSPER_GROUP"] if self.ocommon.check_key("OSPER_GROUP",self.ora_env_dict) else "asmoper"
          osasm=self.ora_env_dict["OSASM_GROUP"] if self.ocommon.check_key("OSASM_GROUP",self.ora_env_dict) else "asmadmin"
          unixgrp="oinstall"
          hostname=self.ocommon.get_public_hostname()
          lang=self.ora_env_dict["LANGUAGE"] if self.ocommon.check_key("LANGUAGE",self.ora_env_dict) else "en"
          node=hostname
          copyflag=" -noCopy "
          if not self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
             copyflag=" -noCopy "
          oraversion=self.ocommon.get_rsp_version("INSTALL",None)
          version=oraversion.split(".",1)[0].strip()
       
          #self.crs_sw_install_on_node(giuser,copyflag,crs_nodes,oinv,gihome,gibase,osdba,osoper,osasm,version,node)
          self.ocommon.log_info_message("Running CRS Sw install on node " + node,self.file_name)
          self.ocommon.crs_sw_install_on_node(giuser,copyflag,crs_nodes,oinv,gihome,gibase,osdba,osoper,osasm,version,node)
          self.ocommon.run_orainstsh_local(giuser,node,oinv)
          self.ocommon.run_rootsh_local(gihome,giuser,node)
          
###### Setting up ssh for K8s #######
    def populate_user_profiles(self):
        """
        This function setup the user profiles if the env is k8s
        """
        giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
        dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
        gipath='''{0}/bin:/bin:/usr/bin:/sbin:/usr/local/bin'''.format(gihome)
        dbpath='''{0}/bin:/bin:/usr/bin:/sbin:/usr/local/bin'''.format(dbhome)
        gildpath='''{0}/lib:/lib/:/usr/lib'''.format(gihome)
        dbldpath='''{0}/lib:/lib/:/usr/lib'''.format(dbhome)
        cdgihome='''cd {0}'''.format(gihome)
        cddbhome='''cd {0}'''.format(dbhome)
        cdgilogs='''cd {0}/diag/crs/*/crs/trace'''.format(obase)
        cddblogs='''cd {0}/diag/rdbms/'''.format(dbase)
        cdinvlogs='''cd {0}/logs'''.format(invloc)
              
        if not self.ocommon.check_key("PROFILE_FLAG",self.ora_env_dict):
          self.ora_env_dict=self.ocommon.add_key("PROFILE_FLAG","TRUE",self.ora_env_dict) 
 
        tmpdir=self.ocommon.get_tmpdir()
        self.ocommon.set_user_profile(giuser,"TMPDIR",tmpdir,"export")
        self.ocommon.set_user_profile(giuser,"TEMP",tmpdir,"export")
        self.ocommon.set_user_profile(dbuser,"TMPDIR",tmpdir,"export")
        self.ocommon.set_user_profile(dbuser,"TEMP",tmpdir,"export")
        if self.ocommon.check_key("PROFILE_FLAG",self.ora_env_dict):
           self.ocommon.set_user_profile(giuser,"ORACLE_HOME",gihome,"export")
           self.ocommon.set_user_profile(giuser,"GRID_HOME",gihome,"export")
           self.ocommon.set_user_profile(giuser,"PATH",gipath,"export")
           self.ocommon.set_user_profile(giuser,"LD_LIBRARY_PATH",gildpath,"export")
           self.ocommon.set_user_profile(dbuser,"ORACLE_HOME",dbhome,"export")
           self.ocommon.set_user_profile(dbuser,"DB_HOME",dbhome,"export")
           self.ocommon.set_user_profile(dbuser,"PATH",dbpath,"export")           
           self.ocommon.set_user_profile(dbuser,"LD_LIBRARY_PATH",dbldpath,"export")
           #### Setting alias
           self.ocommon.set_user_profile(giuser,"cdgihome",cdgihome,"alias")
           self.ocommon.set_user_profile(giuser,"cddbhome",cddbhome,"alias")
           self.ocommon.set_user_profile(dbuser,"cddbhome",cddbhome,"alias")
           self.ocommon.set_user_profile(giuser,"cdgilogs",cdgilogs,"alias")
           self.ocommon.set_user_profile(dbuser,"cddblogs",cddblogs,"alias")
           self.ocommon.set_user_profile(dbuser,"cdinvlogs",cdinvlogs,"alias")
           self.ocommon.set_user_profile(giuser,"cdinvlogs",cdinvlogs,"alias")


##### Set the banner ###
    def set_banner(self):
        """
        This function set the banner
        """
        if self.ocommon.check_key("OP_TYPE",self.ora_env_dict):
           if self.ocommon.check_key("GI_SW_UNZIPPED_FLAG",self.ora_env_dict) and self.ora_env_dict["OP_TYPE"] == 'nosetup':
               msg="Since OP_TYPE is setup to default value(nosetup),setup will be initated by other nodes based on the value OP_TYPES"
               self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name) 
           elif self.ocommon.check_key("GI_SW_UNZIPPED_FLAG",self.ora_env_dict) and self.ora_env_dict["OP_TYPE"] != 'nosetup':
               msg="Since OP_TYPE is set to " + self.ora_env_dict["OP_TYPE"] + " ,setup will be initated on this node"
               self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)                
           else:
              giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
              pubhostname = self.ocommon.get_public_hostname()
              retcode1=self.ocvu.check_home(pubhostname,gihome,giuser)
              if retcode1 == 0:
                 self.ora_env_dict=self.ocommon.add_key("GI_HOME_INSTALLED_FLAG","true",self.ora_env_dict)
              status=self.ocommon.check_gi_installed(retcode1,gihome,giuser,pubhostname,invloc)
              if status:
                 msg="Grid is already installed on this machine"
                 self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)
                 self.ora_env_dict=self.ocommon.add_key("GI_HOME_CONFIGURED_FLAG","true",self.ora_env_dict)
              else:
                 msg="Grid is not installed on this machine"
                 self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)
