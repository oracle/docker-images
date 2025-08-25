#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
#############################

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
from oraracstdby import *
from oraracadd import *
from oracvu import *
from oragiadd import *

class OraRacAdd:
   """
   This class Add the RAC home and RAC instances
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
         self.ogiadd              = OraGIAdd(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
      except BaseException as ex:
         traceback.print_exc(file = sys.stdout)
   def setup(self):
       """
       This function setup the grid on this machine
       """
       self.ocommon.log_info_message("Start setup()",self.file_name)
       ct = datetime.datetime.now()
       bts = ct.timestamp()
       sshFlag=False
       self.ocommon.log_info_message("Start ogiadd.setup()",self.file_name)
       self.ogiadd.setup()
       self.ocommon.log_info_message("End ogiadd.setup()",self.file_name)
       self.env_param_checks()
       self.clu_checks()
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       status=self.ocommon.check_rac_installed(retcode1)
       if not status:
          sshFlag=True
          self.ocommon.log_info_message("Start perform_ssh_setup()",self.file_name)
          self.perform_ssh_setup()
          self.ocommon.log_info_message("End perform_ssh_setup()",self.file_name)
          self.ocommon.log_info_message("Start db_sw_install()",self.file_name)
          self.db_sw_install()
          self.ocommon.log_info_message("End db_sw_install()",self.file_name)
          self.ocommon.log_info_message("Start run_rootsh()",self.file_name)
          self.run_rootsh()
          self.ocommon.log_info_message("End run_rootsh()",self.file_name)
       if not self.ocommon.check_key("SKIP_DBCA",self.ora_env_dict):
            status,osid,host,mode=self.ocommon.check_dbinst()
            hostname=self.ocommon.get_public_hostname()
            if status:
               msg='''Database instance {0} already exist on this machine {1}.'''.format(osid,hostname)
               self.ocommon.update_statefile("completed") 
               self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)
            else:
               if not sshFlag:
                  self.perform_ssh_setup()
               self.ocommon.log_info_message("Start add_dbinst()",self.file_name)
               self.add_dbinst()
               self.ocommon.log_info_message("End add_dbinst()",self.file_name)
               self.ocommon.log_info_message("Setting db listener",self.file_name)
               self.ocommon.setup_db_lsnr()
               self.ocommon.log_info_message("Setting local listener",self.file_name)
               self.ocommon.set_local_listener()
               self.ocommon.setup_db_service("modify")
               sname,osid,opdb,sparams=self.ocommon.get_service_name()
               if sname is not None:
                  self.ocommon.start_db_service(sname,osid)
                  self.ocommon.check_db_service_status(sname,osid) 
               self.ocommon.log_info_message("End create_db()",self.file_name)
               self.ocommon.perform_db_check("ADDNODE")
            self.ocommon.update_statefile("completed")
       ct = datetime.datetime.now()
       ets = ct.timestamp()
       totaltime=ets - bts
       self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)
          
   def env_param_checks(self):
       """
       Perform the env setup checks
       """
       self.ocommon.check_env_variable("DB_HOME",True)
       self.ocommon.check_env_variable("DB_BASE",True)
       self.ocommon.check_env_variable("INVENTORY",True)

   def clu_checks(self):
       """
       Performing clu checks
       """
       self.ocommon.log_info_message("Performing CVU checks on new  nodes before DB home installation to make sure clusterware is up and running",self.file_name)
       hostname=self.ocommon.get_public_hostname()
       retcode1=self.ocvu.check_ohasd(hostname)
       retcode2=self.ocvu.check_asm(hostname)
       retcode3=self.ocvu.check_clu(hostname,None,None)
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
           dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
           self.osetupssh.setupssh(dbuser,dbhome,'ADDNODE')
           #if self.ocommon.check_key("VERIFY_SSH",self.ora_env_dict):
            #self.osetupssh.verifyssh(dbuser,'ADDNODE')
       else:
         self.ocommon.log_info_message("SSH setup must be already completed during env setup as this this k8s env.",self.file_name)

   def db_sw_install(self):
       """
       Perform the db_install
       """
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       hostname=self.ocommon.get_public_hostname()
       existing_crs_nodes=self.ocommon.get_existing_clu_nodes(True)
       oraversion=self.ocommon.get_rsp_version("ADDNODE",hostname)
       version=oraversion.split(".",1)[0].strip()
       node=""
       nodeflag=False
       cmd=None
       for cnode in existing_crs_nodes.split(","):
           retcode3=self.ocvu.check_clu(cnode,True,None)
           if retcode3 == 0:
              node=cnode
              nodeflag=True
              break

       copyflag=""
       if not self.ocommon.check_key("COPY_GRID_SOFTWARE",self.ora_env_dict):
          copyflag=" -noCopy "

       if nodeflag:
          #cmd='''su - {0} -c "ssh -vvv {4} 'sh {1}/addnode/addnode.sh \\"CLUSTER_NEW_NODES={{{2}}}\\" -skipPrereqs -waitForCompletion -ignoreSysPrereqs {3} -silent'"'''.format(dbuser,dbhome,crs_nodes,copyflag,node)
          if int(version) < 23:
              cmd='''su - {0} -c "ssh -vvv {4} 'sh {1}/addnode/addnode.sh \\"CLUSTER_NEW_NODES={{{2}}}\\"  -waitForCompletion  {3} -silent'"'''.format(dbuser,dbhome,crs_nodes,copyflag,node)
          else:
             cmd='''su - {0} -c "ssh -vvv {4} 'sh {1}/addnode/addnode.sh \\"CLUSTER_NEW_NODES={{{2}}}\\"  -waitForCompletion  {3} -silent'"'''.format(dbuser,dbhome,crs_nodes,copyflag,node)
             #cmd='''su - {0} -c "ssh -vvv {4} 'sh {1}/runInstaller -setupDBHome -OSDBA <group> -OSBACKUPDBA <group> -OSDGDBA <group> -OSKMDBA <group> -OSRACDBA <group> -ORACLE_BASE <base> -clusterNodes <new nodes>'"'''
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,None)
       else:
          self.ocommon.log_error_message("Clusterware is not up on any node : " + existing_crs_nodes + ".Exiting...",self.file_name)
          self.prog_exit("127")

   def run_rootsh(self):
       """
       This function run the root.sh after DB home install
       """
       dbuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       for node in pub_nodes.split(" "):
           cmd='''su - {0}  -c "ssh {1}  sudo {2}/root.sh"'''.format(dbuser,node,dbhome)
           output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
           self.ocommon.check_os_err(output,error,retcode,True) 

   def add_dbinst(self):
       """
       This function add the DB inst
       """
       dbuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       existing_crs_nodes=self.ocommon.get_existing_clu_nodes(True)
       node=""
       nodeflag=False
       for cnode in existing_crs_nodes.split(","):
           retcode3=self.ocvu.check_clu(cnode,True,None)
           if retcode3 == 0:
              node=cnode
              nodeflag=True
              break
       if nodeflag:
          dbname,osid,dbuname=self.ocommon.getdbnameinfo()
          for new_node in pub_nodes.split(" "):
             cmd='''su - {0} -c "ssh {2} '{1}/bin/dbca -addInstance -silent  -nodeName {3} -gdbName {4}'"'''.format(dbuser,dbhome,node,new_node,osid)
             output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
             self.ocommon.check_os_err(output,error,retcode,True)
       else:
          self.ocommon.log_error_message("Clusterware is not up on any node : " + existing_crs_nodes + ".Exiting...",self.file_name)
          self.prog_exit("127")
