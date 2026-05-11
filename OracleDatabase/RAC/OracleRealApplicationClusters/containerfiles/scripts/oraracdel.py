#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
This file contains RAC delete-node and deinstall workflow logic.
"""

import os
import sys
import traceback
import datetime
import time

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oracvu import *
from oragiprov import *
from oraasmca import *
from oraops import OperationRunner, CommandBuilder

class OraRacDel:
   """
   This class deletes RAC database components
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
         self.op_runner           = OperationRunner(self.ocommon, self.file_name, "RAC")
         self.cmd_builder         = CommandBuilder(self.ocommon)
         self.ocvu                = oracvu
      except BaseException as ex:
         traceback.print_exc(file = sys.stdout)

   def setup(self):
       """
       Run RAC delete workflow on this machine.
       """
       self.ocommon.log_step("RAC", "delete_setup", "start", None, self.file_name)
       ct = datetime.datetime.now()
       bts = ct.timestamp()
       self.env_param_checks()
       giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
       self.ocommon.populate_existing_cls_nodes() 
       #self.clu_checks()
       hostname=self.ocommon.get_public_hostname()
       if self.ocommon.check_key("EXISTING_CLS_NODE",self.ora_env_dict):
          if len(self.ora_env_dict["EXISTING_CLS_NODE"].split(",")) == 0:
             self.ora_env_dict=self.ocommon.add_key("LAST_CRS_NODE","true",self.ora_env_dict)
       if self.ocommon.detect_k8s_env():
         if self.ocommon.check_key("EXISTING_CLS_NODE", self.ora_env_dict):
            node = self.ora_env_dict["EXISTING_CLS_NODE"].split(",")[0]
            self.ocommon.stop_scan_lsnr(giuser, gihome, hostname)
            self.ocommon.stop_scan(giuser, gihome, hostname)

       # Remove Oracle stack from node to be deleted
       self.del_dbinst_main(hostname)
       self.del_dbhome_main(hostname)
       self.del_gihome_main(hostname)
       self.del_ginode(hostname)

       if self.ocommon.detect_k8s_env():
         if self.ocommon.check_key("EXISTING_CLS_NODE", self.ora_env_dict):
            node = self.ora_env_dict["EXISTING_CLS_NODE"].split(",")[0]
            self.ocommon.update_scan(giuser, gihome, None, node)
            self.ocommon.update_scan_lsnr(giuser, gihome, node)
       ct = datetime.datetime.now()
       ets = ct.timestamp()
       totaltime=ets - bts
       self.ocommon.log_info_message("Total time for delete setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

##### Check env vars ########
 
   def env_param_checks(self):
       """
       Perform environment setup checks.
       """
       self.ocommon.check_env_variable("DB_HOME",True)
       self.ocommon.check_env_variable("DB_BASE",True)
       self.ocommon.check_env_variable("INVENTORY",True)

   def clu_checks(self):
       """
       Perform cluster validation checks.
       """
       self.ocommon.log_info_message("Performing CVU checks before DB home installation to make sure clusterware is up and running",self.file_name) 
       hostname=self.ocommon.get_public_hostname() 
       retcode1=self.ocvu.check_ohasd(hostname)
       retcode2=self.ocvu.check_asm(hostname)
       retcode3=self.ocvu.check_clu(hostname,None,None)

       if retcode1 == 0:
          msg="Cluvfy ohasd check passed!"
          self.ocommon.log_info_message(msg,self.file_name)
       else:
          msg="Cluvfy ohasd check failed. Exiting..."
          self.ocommon.log_error_message(msg,self.file_name) 
          self.ocommon.prog_exit("127")

       if retcode2 == 0:
          msg="Cluvfy asm check passed!"
          self.ocommon.log_info_message(msg,self.file_name)
       else:
          msg="Cluvfy asm check failed. Exiting..."
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

       if retcode3 == 0:
          msg="Cluvfy clumgr check passed!"
          self.ocommon.log_info_message(msg,self.file_name)
       else:
          msg="Cluvfy clumgr check failed. Exiting..."
          self.ocommon.log_error_message(msg,self.file_name)
          self.ocommon.prog_exit("127")

         
######### Deleting DB Instnce #######
   def del_dbinst_main(self,hostname):
       """
       Call del_dbinst to perform DB instance deletion.
       """
       if  self.ocommon.check_key("LAST_CRS_NODE",self.ora_env_dict):
           msg='''This is a last node {0} in the cluster.'''.format(hostname)
           self.ocommon.log_info_message(msg,self.file_name)
       else:
           status,osid,host,mode=self.ocommon.check_dbinst()
           msg='''Database instance {0} exists on this machine {1}.'''.format(osid,hostname)
           self.ocommon.log_info_message(msg,self.file_name)
           self.del_dbinst()
           status,osid,host,mode=self.ocommon.check_dbinst()
           if status:
             msg='''Oracle Database {0} is still up and running on {1}.'''.format(osid,host)
             self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)
             self.ocommon.prog_exit("127")
           else:
             msg='''Oracle Database {0} is not up and running on {1}.'''.format(osid,host)
             self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)

   def _get_first_active_crs_node(self, existing_crs_nodes):
       """
       Return first cluster node where cluvfy clumgr passes.
       """
       return self.ocommon.get_first_active_crs_node(existing_crs_nodes, self.ocvu)

   def del_dbinst(self):
       """
       Perform the db instance deletion
       """
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       dbname,osid,dbuname=self.ocommon.getdbnameinfo()
       hostname=self.ocommon.get_public_hostname() 
       inst_sid=self.ocommon.get_inst_sid(dbuser,dbhome,dbname,hostname) 
       existing_crs_nodes=self.ocommon.get_existing_clu_nodes(True)
       node=self._get_first_active_crs_node(existing_crs_nodes)
       nodeflag=bool(node)

       if inst_sid:
         if nodeflag:
            cmd=self.cmd_builder.build_rac_delete_instance(dbuser, dbhome, dbname, inst_sid, node, hostname)
            output,error,retcode=self.op_runner.run_command("rac_delete_dbinst", cmd, None, None, True)
         else:
            self.ocommon.log_error_message("Clusterware is not up on any node: " + existing_crs_nodes + ". Exiting...",self.file_name) 
            self.ocommon.prog_exit("127")
       else:
           self.ocommon.log_info_message("No database instance is up and running on this machine!",self.file_name) 

#######  DEL RAC DB HOME ########
   def del_dbhome_main(self,hostname):
       """
       Call del_dbhome to perform DB home deletion.
       """
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       if self.ocommon.check_key("DEL_RACHOME",self.ora_env_dict):
          retcode1=self.ocvu.check_home(hostname,dbhome,dbuser)
          status=self.ocommon.check_rac_installed(retcode1)
          if status: 
             self.del_dbhome()
          else:
             self.ocommon.log_info_message("No configured RAC home exists on this machine",self.file_name)  

   def del_dbhome(self):
       """
       Perform the db home deletion
       """
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       tmpdir=self.ocommon.get_tmpdir()
       dbrspdir="/{1}/dbdeinstall_{0}".format(time.strftime("%T"),tmpdir) 
       self.ocommon.create_dir(dbrspdir,"local",None,"oracle","oinstall")
       self.generate_delrspfile(dbrspdir,dbuser,dbhome)
       dbrspfile=self.ocommon.latest_file(dbrspdir)
       if os.path.isfile(dbrspfile):    
          cmd='''su - {0} -c "{1}/deinstall/deinstall -silent -local -paramfile {2} "'''.format(dbuser,dbhome,dbrspfile)
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,False) 
       else:
          self.ocommon.log_error_message("No response file exists under " + dbrspdir,self.file_name)
          self.ocommon.prog_exit("127")

   def generate_delrspfile(self,rspdir,user,home):
       """
       Generate the response file to perform home deletion.
       """
       cmd='''su - {0} -c "{1}/deinstall/deinstall -silent -checkonly -local -o {2}"'''.format(user,home,rspdir)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,True)

#######  DEL GI HOME ########
   def del_gihome_main(self,hostname):
       """
       Call del_gihome to perform GI home deletion.
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       self.ocommon.log_info_message("gi params " + gihome ,self.file_name)
       hostname=self.ocommon.get_public_hostname()
       node=hostname
       if self.ocommon.check_key("DEL_GIHOME",self.ora_env_dict):
          retcode1=self.ocvu.check_home(hostname,gihome,giuser)
          status=self.ocommon.check_gi_installed(retcode1,gihome,giuser,node,oinv)
          if status:
             self.del_gihome()
          else:
             self.ocommon.log_info_message("No configured GI home exists on this machine",self.file_name)

   def del_gihome(self):
       """
       Perform the GI home deletion
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()
       tmpdir=self.ocommon.get_tmpdir()
       girspdir="/{1}/gideinstall_{0}".format(time.strftime("%T"),tmpdir)
       self.ocommon.create_dir(girspdir,"local",None,"grid","oinstall")
       self.generate_delrspfile(girspdir,giuser,gihome)
       girspfile=self.ocommon.latest_file(girspdir)
       if os.path.isfile(girspfile):
          cmd='''su - {0} -c "export TEMP={3};{1}/deinstall/deinstall -silent -local -paramfile {2} "'''.format(giuser,gihome,girspfile,"/var/tmp")
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,True)
          deinstallDir=self.ocommon.latest_dir(tmpdir,'deins*/')
          cmd='''{0}/rootdeinstall.sh'''.format(deinstallDir)
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,False)
       else:
          self.ocommon.log_error_message("No response file exists under " + girspdir,self.file_name)
          self.ocommon.prog_exit("127")

   def del_ginode(self,hostname):
       """
       Perform the GI Node deletion
       """
       giuser,gihome,gbase,oinv=self.ocommon.get_gi_params()

       existing_crs_nodes=self.ocommon.get_existing_clu_nodes(True)
       node=self._get_first_active_crs_node(existing_crs_nodes)
       nodeflag=bool(node)

       if nodeflag:
            cmd=self.cmd_builder.build_gi_delete_node(giuser, gihome, node, hostname)
            output,error,retcode=self.op_runner.run_command("rac_delete_ginode", cmd, None, None, True)
       else:
            self.ocommon.log_error_message("Clusterware is not up on any node: " + existing_crs_nodes + ". Exiting...",self.file_name) 
            self.ocommon.prog_exit("127")

