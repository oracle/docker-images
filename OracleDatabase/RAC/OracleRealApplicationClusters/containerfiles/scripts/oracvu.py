#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
#############################

"""
 This file contains to the code call different classes objects based on setup type
"""

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *

import os
import sys

class OraCvu:
   """
   This class performs the CVU checks
   """
   def __init__(self,oralogger,orahandler,oraenv,oracommon):
      try:
         self.ologger             = oralogger
         self.ohandler            = orahandler
         self.oenv                = oraenv.get_instance()
         self.ocommon             = oracommon
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
       pass

   def node_reachability_checks(self,checktype,user,ctype):
       """
       This function performs the cluvfy checks
       """
       exiting_cls_node=""
       if ctype == 'ADDNODE':
           exiting_cls_node=self.ocommon.get_existing_clu_nodes(True)

       if self.ocommon.check_key("CRS_NODES",self.ora_env_dict):
          pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
          if checktype=="private":
             crs_nodes=priv_nodes.replace(" ",",")
          else:
             crs_nodes=pub_nodes.replace(" ",",")
             if exiting_cls_node:
                crs_nodes = crs_nodes + "," +  exiting_cls_node

          nwmask,nwsubnet,nwname=self.ocommon.get_nwlist(checktype)   
          self.cluvfy_nodereach(crs_nodes,nwname,user)
          

   def node_connectivity_checks(self,checktype,user,ctype):
       """
       This function performs the cluvfy checks
       """
       exiting_cls_node=""
       if ctype == 'ADDNODE':
           exiting_cls_node=self.ocommon.get_existing_clu_nodes(True)

       if self.ocommon.check_key("CRS_NODES",self.ora_env_dict):
          pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
          if checktype=="private":
             crs_nodes=priv_nodes.replace(" ",",")
          else:
             crs_nodes=pub_nodes.replace(" ",",")
             if exiting_cls_node:
                crs_nodes = crs_nodes + "," +  exiting_cls_node

          nwmask,nwsubnet,nwname=self.ocommon.get_nwlist(checktype)
          self.cluvfy_nodereach(crs_nodes,nwname,user)

   def cluvfy_nodereach(self,crs_nodes,nwname,user):
       """
       This function performs the cluvfy checks
       """
       ohome=self.ora_env_dict["GRID_HOME"]
       self.ocommon.log_info_message("Performing cluvfy check to perform node reachability.",self.file_name) 
       cmd='''su - {2} -c "{1}/runcluvfy.sh comp nodereach -n {0} -verbose"'''.format(crs_nodes,ohome,user)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,True)

   def cluvfy_nodecon(self,crs_nodes,nwname,user):
       """
       This function performs the cluvfy checks
       """
       ohome=self.ora_env_dict["GRID_HOME"]
       self.ocommon.log_info_message("Performing cluvfy check to perform node connectivty.",self.file_name)
       cmd='''su - {3} -c "{1}/runcluvfy.sh comp nodecon -n {0} -networks {2} -verbose"'''.format(crs_nodes,ohome,nwname,user)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None) 

   def cluvfy_compsys(self,ctype,user):
       """
       This function performs the cluvfy comp sys checks
       """
       ohome=self.ora_env_dict["GRID_HOME"]
       self.ocommon.log_info_message("Performing cluvfy check to perform node connectivty.",self.file_name)
       cmd='''su - {2} -c "{1}/runcluvfy.sh comp sys  -n racnode6,racnode8 -p {0} -verbose"'''.format(ctype,ohome,user)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)

   def cluvfy_checkrspfile(self,fname,ohome,user):
       """
       This function performs the cluvfy check on a responsefile 
       """
       self.cluvfy_updcvucfg(ohome,user)
       self.ocommon.log_info_message("Performing cluvfy check on a responsefile: " + fname,self.file_name) 
       cmd='''su - {0} -c "{1}/runcluvfy.sh stage -pre crsinst -responseFile {2} | tee -a {3}/cluvfy_check.txt"'''.format(user,ohome,fname,"/tmp")
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       if self.ocommon.check_key("IGNORE_CVU_CHECKS",self.ora_env_dict):  
          self.ocommon.check_os_err(output,error,retcode,None)
       else:
          self.ocommon.check_os_err(output,error,retcode,None)
          
   def cluvfy_updcvucfg(self,ohome,user):
       """
       This function update the CVU config file with the correct CV_DESTLOC 
       """
       match=None
       tmpdir=self.ocommon.get_tmpdir()
       fname='''{0}/cv/admin/cvu_config'''.format(ohome)
       self.ocommon.log_info_message("Updating CVU config file: " + fname,self.file_name)
       fdata=self.ocommon.read_file(fname)       
       match=re.search("CV_DESTLOC=",fdata,re.MULTILINE)
       if not match:
          cmd='''su - {0} -c "echo CV_DESTLOC=\"{1}\" >> {2}"'''.format(user,tmpdir,fname)
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       else:
          cmd='''su - {0} -c "echo CV_DESTLOC=\"{1}\" >> {2}"'''.format(user,tmpdir,fname)
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       
   def check_ohasd(self,node):
       """
       This function check if crs is configued properly
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       crs_nodes=""
       if not node:
          crs_nodes=" -allnodes "
       else:
          crs_nodes=" -n " + node

       cmd='''su - {0} -c "{1}/bin/cluvfy comp ohasd {2}"'''.format(giuser,gihome,crs_nodes)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)
       return retcode

   def check_asm(self,node):
       """
       This function check if crs is configued properly
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       crs_nodes=""
       if not node:
          crs_nodes=" -allnodes "
       else:
          crs_nodes=" -n " + node
        
       cmd='''su - {0} -c "{1}/bin/cluvfy comp asm {2}"'''.format(giuser,gihome,crs_nodes)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)
       return retcode

   def check_clu(self,node,sshflag):
       """
       This function check if crs is configued properly
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       crs_nodes=""
       if not node:
          crs_nodes=" -allnodes "
          cmd='''su - {0} -c "{1}/bin/cluvfy comp clumgr {2}"'''.format(giuser,gihome,crs_nodes)
       else:
          crs_nodes=" -n " + node
          cmd='''su - {0} -c "{1}/bin/cluvfy comp clumgr {2}"'''.format(giuser,gihome,crs_nodes)
       
       if sshflag:
          crs_nodes=" -n " + node
          cmd='''su - {0} -c "ssh {3} '{1}/bin/cluvfy comp clumgr {2}'"'''.format(giuser,gihome,crs_nodes,node)
           
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)
       return retcode

   def check_home(self,node,home,user):
       """
       This function check if crs is configued properly
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       if not node:
          crs_nodes=" -allnodes "
       else:
          crs_nodes=" -n " + node

       cvufile='''{0}/bin/cluvfy'''.format(gihome)
       if not self.ocommon.check_file(cvufile,True,None,None):
          return 1
          
       cmd='''su - {0} -c "{1}/bin/cluvfy comp software -d {3} -verbose"'''.format(user,gihome,node,home)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       if not self.ocommon.check_substr_match(output,"FAILED"):
         return 0
       else:
         return 1

   def check_db_homecfg(self,node):
       """
       This function check if  db home is configured properly
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       dbuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()

       if not node:
          crs_nodes=" -allnodes "
       else:
          crs_nodes=" -n " + node

       cmd='''su - {0} -c "{1}/bin/cluvfy stage -pre dbcfg {2} -d {3}"'''.format(dbuser,gihome,crs_nodes,dbhome)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None) 
       return retcode

   def check_addnode(self):
       """
       This function check if the node can be added
       """
       exiting_cls_node=self.ocommon.get_existing_clu_nodes(True)
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       node=exiting_cls_node.split(",")[0]
       tmpdir=self.ocommon.get_tmpdir()
       if self.ocommon.check_key("CRS_NODES",self.ora_env_dict):
          pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
          crs_nodes=pub_nodes.replace(" ",",")
       cmd='''su - {0} -c "ssh {1} '{2}/runcluvfy.sh stage -pre nodeadd -n {3}'"'''.format(giuser,node,gihome,crs_nodes,tmpdir)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       if self.ocommon.check_key("IGNORE_CVU_CHECKS",self.ora_env_dict):
          self.ocommon.log_info_message("Ignoring CVU checks failure as IGNORE_CVU_CHECKS set to ignore CVU checks.",self.file_name)          
          self.ocommon.check_os_err(output,error,retcode,None)
       else:
          self.ocommon.check_os_err(output,error,retcode,None)

