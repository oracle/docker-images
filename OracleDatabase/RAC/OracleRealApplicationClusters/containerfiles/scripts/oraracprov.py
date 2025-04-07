#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file contains to the code call different classes objects based on setup type
"""

from distutils.log import debug
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
from oraasmca import *

dgname=""
dbfiledest=""
dbrdest=""

class OraRacProv:
   """
   This class provision the RAC database
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
         self.mythread            = {}
         self.ogiprov             = OraGIProv(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
         self.oasmca              = OraAsmca(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
      except BaseException as ex:
         traceback.print_exc(file = sys.stdout) 
 
   def setup(self):
       """
       This function setup the RAC home on this machine
       """
       self.ocommon.log_info_message("Start setup()",self.file_name)
       ct = datetime.datetime.now()
       bts = ct.timestamp()
       sshFlag=False
       self.ogiprov.setup() 
       self.env_param_checks()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       if not self.ocommon.check_key("CLUSTER_SETUP_FLAG",self.ora_env_dict):
          for node in crs_nodes.split(","):
              self.clu_checks(node)
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       status=self.ocommon.check_rac_installed(retcode1)
       self.ocommon.reset_os_password(dbuser)
       if not status:
         self.ocommon.log_info_message("Start perform_ssh_setup()",self.file_name)
         self.perform_ssh_setup()
         self.ocommon.log_info_message("End perform_ssh_setup()",self.file_name)
         sshFlag=True
         status=self.ocommon.check_home_inv(None,dbhome,dbuser)
         if not status:
            self.ocommon.log_info_message("Start db_sw_install()",self.file_name)
            self.db_sw_install()
            self.ocommon.log_info_message("End db_sw_install()",self.file_name)
            self.ocommon.log_info_message("Start run_rootsh()",self.file_name)
            self.run_rootsh()
            self.ocommon.log_info_message("End run_rootsh()",self.file_name)
       if not self.ocommon.check_key("SKIP_DBCA",self.ora_env_dict):
            self.create_asmdg()
            status,osid,host,mode=self.ocommon.check_dbinst()
            hostname=self.ocommon.get_public_hostname()
            if status:
               msg='''Database instance {0} already exist on this machine {1}.'''.format(osid,hostname)
               self.ocommon.update_statefile("completed")
               self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)
               
            elif self.ocommon.check_key("CLONE_DB",self.ora_env_dict):
               self.ocommon.log_info_message("Start clone_db()",self.file_name)
               self.clone_db(crs_nodes)
            else:
               if not sshFlag:
                  self.perform_ssh_setup()
               self.ocommon.log_info_message("Start create_db()",self.file_name)
               self.create_db()
               self.ocommon.log_info_message("Setting db listener",self.file_name)
               self.ocommon.setup_db_lsnr()
               self.ocommon.log_info_message("Setting local listener",self.file_name)
               self.ocommon.set_local_listener()
               self.ocommon.setup_db_service("create")
               sname,osid,opdb,sparams=self.ocommon.get_service_name()
               if sname is not None:
                  self.ocommon.start_db_service(sname,osid)
                  self.ocommon.check_db_service_status(sname,osid) 
               self.ocommon.log_info_message("End create_db()",self.file_name)
               self.ocommon.perform_db_check("INSTALL")
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

   def clu_checks(self,hostname):
       """
       Performing clu checks
       """
       self.ocommon.log_info_message("Performing CVU checks before DB home installation to make sure clusterware is up and running on " + hostname,self.file_name) 
      # hostname=self.ocommon.get_public_hostname()  
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
          #self.ocommon.prog_exit("127")

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
       #if not self.ocommon.detect_k8s_env():
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       crs_nodes_list=crs_nodes.split(",")
       if len(crs_nodes_list) == 1:
          self.ocommon.log_info_message("Cluster size=1. Node=" + crs_nodes_list[0],self.file_name)
          user=self.ora_env_dict["DB_USER"]
          cmd='''su - {0} -c "/bin/rm -rf ~/.ssh ; sleep 1; /bin/ssh-keygen -t rsa -q -N \'\' -f ~/.ssh/id_rsa ; sleep 1; /bin/ssh-keyscan {1} > ~/.ssh/known_hosts 2>/dev/null ; sleep 1; /bin/cp ~/.ssh/id_rsa.pub  ~/.ssh/authorized_keys"'''.format(user,crs_nodes_list[0])
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,None)
       else:
          if not self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict) and not self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict):
            dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
            self.osetupssh.setupssh(dbuser,dbhome,"INSTALL")
            #if self.ocommon.check_key("VERIFY_SSH",self.ora_env_dict):
            #self.osetupssh.verifyssh(dbuser,"INSTALL")
          else:
            self.ocommon.log_info_message("SSH setup must be already completed during env setup as this this env variables SSH_PRIVATE_KEY and SSH_PUBLIC_KEY are set.",self.file_name)

   def db_sw_install(self):
       """
       Perform the db_install
       """
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       osdba=self.ora_env_dict["OSDBA_GROUP"] if self.ocommon.check_key("OSDBA",self.ora_env_dict) else "dba"
       osbkp=self.ora_env_dict["OSBACKUPDBA_GROUP"] if self.ocommon.check_key("OSBACKUPDBA_GROUP",self.ora_env_dict) else "backupdba" 
       osoper=self.ora_env_dict["OSPER_GROUP"] if self.ocommon.check_key("OSPER_GROUP",self.ora_env_dict) else "oper"
       osdgdba=self.ora_env_dict["OSDGDBA_GROUP"] if self.ocommon.check_key("OSDGDBA_GROUP",self.ora_env_dict) else "dgdba" 
       oskmdba=self.ora_env_dict["OSKMDBA_GROUP"] if self.ocommon.check_key("OSKMDBA_GROUP",self.ora_env_dict) else "kmdba"
       osracdba=self.ora_env_dict["OSRACDBA_GROUP"] if self.ocommon.check_key("OSRACDBA_GROUP",self.ora_env_dict) else "racdba"
       osasm=self.ora_env_dict["OSASM_GROUP"] if self.ocommon.check_key("OSASM_GROUP",self.ora_env_dict) else "asmadmin"
       unixgrp="oinstall"
       hostname=self.ocommon.get_public_hostname()
       lang=self.ora_env_dict["LANGUAGE"] if self.ocommon.check_key("LANGUAGE",self.ora_env_dict) else "en"
       edition= self.ora_env_dict["DB_EDITION"] if self.ocommon.check_key("DB_EDITION",self.ora_env_dict) else "EE"
       ignoreflag= " -ignorePrereq " if self.ocommon.check_key("IGNORE_DB_PREREQS",self.ora_env_dict) else " "

       copyflag=" -noCopy "
       if not self.ocommon.check_key("COPY_DB_SOFTWARE",self.ora_env_dict):
          copyflag=" -noCopy "
  
       mythread_list=[]

       oraversion=self.ocommon.get_rsp_version("INSTALL",None)
       version=oraversion.split(".",1)[0].strip()

       self.mythread.clear()
       mythreads=[]
       for node in pub_nodes.split(" "):
          self.ocommon.log_info_message("Running DB Sw install on node " + node,self.file_name)
          thread=Process(target=self.db_sw_install_on_node,args=(dbuser,hostname,unixgrp,crs_nodes,oinv,lang,dbhome,dbase,edition,osdba,osbkp,osdgdba,oskmdba,osracdba,copyflag,node,ignoreflag))
          #thread.setDaemon(True)
          mythreads.append(thread)
          thread.start()
  
#       for thread in mythreads:
#          self.ocommon.log_info_message("Starting Thread",self.file_name)
#          thread.start()

       for thread in mythreads:  # iterates over the threads
          thread.join()       # waits until the thread has finished wor

       #self.manage_thread()

   def db_sw_install_on_node(self,dbuser,hostname,unixgrp,crs_nodes,oinv,lang,dbhome,dbase,edition,osdba,osbkp,osdgdba,oskmdba,osracdba,copyflag,node,ignoreflag):
       """
       Perform the db_install
       """
       runCmd=""
       if self.ocommon.check_key("APPLY_RU_LOCATION",self.ora_env_dict):
          ruLoc=self.ora_env_dict["APPLY_RU_LOCATION"]
          runCmd='''runInstaller -applyRU "{0}"'''.format(self.ora_env_dict["APPLY_RU_LOCATION"])
       else:
          runCmd='''runInstaller '''
          
       
       if self.ocommon.check_key("DEBUG_MODE",self.ora_env_dict):
          dbgCmd='''{0} -debug '''.format(runCmd)
          runCmd=dbgCmd
          
       rspdata='''su - {0} -c "ssh {17} {1}/{16} {18} -waitforcompletion {15} -silent 
              oracle.install.option=INSTALL_DB_SWONLY
              ORACLE_HOSTNAME={2}
              UNIX_GROUP_NAME={3}
              oracle.install.db.CLUSTER_NODES={4}
              INVENTORY_LOCATION={5}
              SELECTED_LANGUAGES={6}
              ORACLE_HOME={7}
              ORACLE_BASE={8}
              oracle.install.db.InstallEdition={9}
              oracle.install.db.OSDBA_GROUP={10}
              oracle.install.db.OSBACKUPDBA_GROUP={11}
              oracle.install.db.OSDGDBA_GROUP={12}
              oracle.install.db.OSKMDBA_GROUP={13}
              oracle.install.db.OSRACDBA_GROUP={14}
              SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
              DECLINE_SECURITY_UPDATES=true"'''.format(dbuser,dbhome,hostname,unixgrp,crs_nodes,oinv,lang,dbhome,dbase,edition,osdba,osbkp,osdgdba,oskmdba,osracdba,copyflag,runCmd,node,ignoreflag)
       cmd=rspdata.replace('\n'," ")  
       #dbswrsp="/tmp/dbswrsp.rsp" 
       #self.ocommon.write_file(dbswrsp,rspdata)
       #if os.path.isfile(dbswrsp):
       #cmd='''su - {0} -c "{1}/runInstaller -ignorePrereq -waitforcompletion -silent  -responseFile {2}"'''.format(dbuser,dbhome,dbswrsp)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
       self.ocommon.check_os_err(output,error,retcode,None)
       #else:
       #   self.ocommon.log_error_message("DB response file does not exist at its location: " + dbswrsp + ".Exiting..",self.file_name)
       #   self.ocommon.prog_exit("127") 
       if len(self.mythread) > 0:
          if node in self.mythread.keys():
             swthread_list=self.mythread[node]
             value=swthread_list[0]
             new_list=[value,'FALSE']
             new_val={node,tuple(new_list)}
             self.mythread.update(new_val)

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

   def create_asmdg(self):
       """
       Perform the asm disk group creation
       """
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       if (self.ocommon.check_key("REDO_ASM_DEVICE_LIST",self.ora_env_dict)) and (self.ocommon.check_key("LOG_FILE_DEST",self.ora_env_dict)):
          lgdest=self.ocommon.rmdgprefix(self.ora_env_dict["LOG_FILE_DEST"])
          device_prop=self.ora_env_dict["REDO_ASMDG_PROPERTIES"] if self.ocommon.check_key("REDO_ASMDG_PROPERTIES",self.ora_env_dict) else None
          self.ocommon.log_info_message("dg validation for :" + lgdest + " is in progress", self.file_name)
          status=self.oasmca.validate_dg(self.ora_env_dict["REDO_ASM_DEVICE_LIST"],device_prop,lgdest)
          if not status:
             self.oasmca.create_dg(self.ora_env_dict["REDO_ASM_DEVICE_LIST"],device_prop,lgdest)
          else:
             self.ocommon.log_info_message("ASM diskgroup exist!",self.file_name)
         
       if (self.ocommon.check_key("RECO_ASM_DEVICE_LIST",self.ora_env_dict)) and (self.ocommon.check_key("DB_RECOVERY_FILE_DEST",self.ora_env_dict)):
          dbrdest=self.ocommon.rmdgprefix(self.ora_env_dict["DB_RECOVERY_FILE_DEST"]) 
          device_prop=self.ora_env_dict["RECO_ASMDG_PROPERTIES"] if self.ocommon.check_key("RECO_ASMDG_PROPERTIES",self.ora_env_dict) else None
          self.ocommon.log_info_message("dg validation for :" + dbrdest + " is in progress", self.file_name)
          status=self.oasmca.validate_dg(self.ora_env_dict["RECO_ASM_DEVICE_LIST"],device_prop,dbrdest)
          if not status:
             self.oasmca.create_dg(self.ora_env_dict["RECO_ASM_DEVICE_LIST"],device_prop,dbrdest)
          else:
             self.ocommon.log_info_message("ASM diskgroup exist!",self.file_name)

       if (self.ocommon.check_key("DB_ASM_DEVICE_LIST",self.ora_env_dict)) and (self.ocommon.check_key("DB_DATA_FILE_DEST",self.ora_env_dict)):
          dbfiledest=self.ocommon.rmdgprefix(self.ora_env_dict["DB_DATA_FILE_DEST"])
          device_prop=self.ora_env_dict["DB_ASMDG_PROPERTIES"] if self.ocommon.check_key("DB_ASMDG_PROPERTIES",self.ora_env_dict) else None
          self.ocommon.log_info_message("dg validation for :" + dbfiledest + " is in progress", self.file_name)
          status=self.oasmca.validate_dg(self.ora_env_dict["DB_ASM_DEVICE_LIST"],device_prop,dbfiledest)
          if not status:
             self.oasmca.create_dg(self.ora_env_dict["DB_ASM_DEVICE_LIST"],device_prop,dbfiledest)
          else:
             self.ocommon.log_info_message("ASM diskgroup exist!",self.file_name)

   def set_clonedb_params(self):
       """
       Set clone database parameters
       """
       osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       dgname=self.ocommon.setdgprefix(self.ocommon.getcrsdgname())
       dbfiledest=self.ocommon.setdgprefix(self.ocommon.getdbdestdgname(dgname))
       dbrdest=self.ocommon.setdgprefix(self.ocommon.getdbrdestdgname(dbfiledest))
       osid=self.ora_env_dict["GOLD_SID_NAME"]
       connect_str=self.ocommon.get_sqlplus_str(dbhome,osid,osuser,"sys",None,None,None,osid,None,None,None)
       sqlcmd='''
          alter system set control_files='{1}' scope=spfile;
          ALTER SYSTEM SET DB_CREATE_FILE_DEST='{0}' scope=spfile sid='*';
          ALTER SYSTEM SET DB_RECOVERY_FILE_DEST='{1}' scope=spfile sid='*';
       '''.format(dbfiledest,dbrdest) 
       output=self.ocommon.run_sql_cmd(sqlcmd,connect_str)  
 
   def clone_db(self,crs_nodes):
      """
      This function clone the DB
      """
      if self.ocommon.check_key("GOLD_DB_BACKUP_LOC",self.ora_env_dict) and self.ocommon.check_key("GOLD_DB_NAME",self.ora_env_dict) and self.ocommon.check_key("DB_NAME",self.ora_env_dict)  and  self.ocommon.check_key("GOLD_SID_NAME",self.ora_env_dict) and self.ocommon.check_key("GOLD_PDB_NAME",self.ora_env_dict):
         self.ocommon.log_info_message("GOLD_DB_BACKUP_LOC set to " + self.ora_env_dict["GOLD_DB_BACKUP_LOC"] ,self.file_name)
         self.ocommon.log_info_message("GOLD_DB_NAME set to " + self.ora_env_dict["GOLD_DB_NAME"] ,self.file_name)
         self.ocommon.log_info_message("DB_NAME set to " + self.ora_env_dict["DB_NAME"] ,self.file_name)
         pfile='''/tmp/pfile_{0}'''.format( datetime.datetime.now().strftime('%d%m%Y%H%M'))
         self.ocommon.create_file(pfile,"local",None,None)
         fdata='''db_name={0}'''.format(self.ora_env_dict["GOLD_DB_NAME"])
         self.ocommon.append_file(pfile,fdata)
         self.ocommon.start_db(self.ora_env_dict["GOLD_SID_NAME"],"nomount",pfile)
       ## VV  self.ocommon.catalog_bkp()
         self.ocommon.restore_spfile()
         cmd='''rm -f {0}'''.format(pfile)
         output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
         self.ocommon.check_os_err(output,error,retcode,False)
         self.ocommon.shutdown_db(self.ora_env_dict["GOLD_SID_NAME"])
         self.ocommon.start_db(self.ora_env_dict["GOLD_SID_NAME"],"nomount")
         self.set_clonedb_params()
         self.ocommon.shutdown_db(self.ora_env_dict["GOLD_SID_NAME"])
         self.ocommon.start_db(self.ora_env_dict["GOLD_SID_NAME"],"nomount")
         self.ocommon.restore_bkp(self.ocommon.setdgprefix(self.ocommon.getcrsdgname()))

         osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
         osid=self.ora_env_dict["GOLD_SID_NAME"]
         pfile=dbhome + "/dbs/init" + osid + ".ora"
         spfile=dbhome + "/dbs/spfile" + osid + ".ora"

         self.ocommon.create_pfile(pfile,spfile)
         self.ocommon.shutdown_db(self.ora_env_dict["GOLD_SID_NAME"])
         self.ocommon.set_cluster_mode(pfile,False)
         self.ocommon.start_db(self.ora_env_dict["GOLD_SID_NAME"],"mount",pfile)
         self.ocommon.change_dbname(pfile,self.ora_env_dict["DB_NAME"])
         
         self.ocommon.start_db(self.ora_env_dict["DB_NAME"] + "1","mount",pfile)
         spfile=self.ocommon.getdbdestdgname("+DATA") + "/" + self.ora_env_dict["DB_NAME"] + "/PARAMETERFILE/spfile" + self.ora_env_dict["DB_NAME"] + ".ora"
         self.ocommon.create_spfile(spfile,pfile)
         self.ocommon.resetlogs(self.ora_env_dict["DB_NAME"] + "1")
         self.ocommon.shutdown_db(self.ora_env_dict["DB_NAME"] + "1")
         self.ocommon.add_rac_db(osuser,dbhome,self.ora_env_dict["DB_NAME"],spfile)
         instance_number=1
         for node in crs_nodes.split(","):
            self.ocommon.add_rac_instance(osuser,dbhome,self.ora_env_dict["DB_NAME"],str(instance_number),node)
            instance_number +=1

         self.ocommon.start_rac_db(osuser,dbhome,self.ora_env_dict["DB_NAME"])
         self.ocommon.get_db_status(osuser,dbhome,self.ora_env_dict["DB_NAME"])
         self.ocommon.get_db_config(osuser,dbhome,self.ora_env_dict["DB_NAME"])
         self.ocommon.log_info_message("End clone_db()",self.file_name) 
                  
   def check_responsefile(self):
      """
      This function returns the valid response file
      """
      dbrsp=None
      if self.ocommon.check_key("DBCA_RESPONSE_FILE",self.ora_env_dict):
         dbrsp=self.ora_env_dict["DBCA_RESPONSE_FILE"]
         self.ocommon.log_info_message("DBCA_RESPONSE_FILE parameter is set and file location is:" + dbrsp ,self.file_name)
      else:
         self.ocommon.log_error_message("DBCA response file does not exist at its location: " + dbrsp + ".Exiting..",self.file_name)
         self.ocommon.prog_exit("127")
         
      if os.path.isfile(dbrsp):
	      return dbrsp
   
   def create_db(self):
      """
      Perform the DB Creation
      """
      cmd=""
      prereq=" "
      if self.ocommon.check_key("IGNORE_DB_PREREQS",self.ora_env_dict):
         prereq=" -ignorePreReqs " 
      dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
      if self.ocommon.check_key("DBCA_RESPONSE_FILE",self.ora_env_dict):
         dbrsp=self.check_responsefile()
         cmd='''su - {0} -c "{1}/bin/dbca  -silent {3} -createDatabase -responseFile {2}"'''.format(dbuser,dbhome,dbrsp,prereq)
      else:
         cmd=self.prepare_db_cmd() 

      dbpasswd=self.ocommon.get_db_passwd()
      tdepasswd=self.ocommon.get_tde_passwd() 
      self.ocommon.set_mask_str(dbpasswd) 
      output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
      self.ocommon.check_os_err(output,error,retcode,True)
      ### Unsetting the encrypt value to None
      self.ocommon.unset_mask_str()
      if self.ocommon.check_key("DBCA_RESPONSE_FILE",self.ora_env_dict):
        self.ocommon.reset_dbuser_passwd("sys",None,"all")       

   def prepare_db_cmd(self):
       """
       Perform the asm disk group creation
       """
       prereq=" "
       if self.ocommon.check_key("IGNORE_DB_PREREQS",self.ora_env_dict):
         prereq=" -ignorePreReqs "

       tdewallet=""
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
       crs_nodes=pub_nodes.replace(" ",",")
       dbname,osid,dbuname=self.ocommon.getdbnameinfo()
       dgname=self.ocommon.setdgprefix(self.ocommon.getcrsdgname())
       dbfiledest=self.ocommon.setdgprefix(self.ocommon.getdbdestdgname(dgname))
       cdbflag=self.ora_env_dict["CONTAINERDB_FLAG"] if self.ocommon.check_key("CONTAINERDB_FLAG",self.ora_env_dict) else "true"
       stype=self.ora_env_dict["DB_STORAGE_TYPE"] if self.ocommon.check_key("DB_STORAGE_TYPE",self.ora_env_dict) else  "ASM"
       charset=self.ora_env_dict["DB_CHARACTERSET"] if self.ocommon.check_key("DB_CHARACTERSET",self.ora_env_dict) else  "AL32UTF8"
       redosize=self.ora_env_dict["DB_REDOFILE_SIZE"] if self.ocommon.check_key("DB_REDOFILE_SIZE",self.ora_env_dict) else  "1024"
       dbtype=self.ora_env_dict["DB_TYPE"] if self.ocommon.check_key("DB_TYPE",self.ora_env_dict) else  "OLTP"
       dbctype=self.ora_env_dict["DB_CONFIG_TYPE"] if self.ocommon.check_key("DB_CONFIG_TYPE",self.ora_env_dict) else  "RAC"
       arcmode=self.ora_env_dict["ENABLE_ARCHIVELOG"] if self.ocommon.check_key("ENABLE_ARCHIVELOG",self.ora_env_dict) else  "true" 
       pdbsettings=self.get_pdb_params()
       initparams=self.get_init_params()
       if self.ocommon.check_key("SETUP_TDE_WALLET",self.ora_env_dict):
          tdewallet='''-configureTDE true -tdeWalletPassword HIDDEN_STRING -tdeWalletRoot {0} -tdeWalletLoginType AUTO_LOGIN -encryptTablespaces all'''.format(dbfiledest)
       #memorypct=self.get_memorypct()

       rspdata='''su - {0} -c "{1}/bin/dbca -silent {15} -createDatabase  \
       -templateName General_Purpose.dbc \
       -gdbname {2} \
       -createAsContainerDatabase {3} \
       -sysPassword HIDDEN_STRING \
       -systemPassword HIDDEN_STRING \
       -datafileDestination {4} \
       -storageType {5} \
       -characterSet {6} \
       -redoLogFileSize {7} \
       -databaseType {8} \
       -databaseConfigType {9} \
       -nodelist {10} \
       -useOMF true \
       {12} \
       {13} \
       {16} \
       -enableArchive {14}"'''.format(dbuser,dbhome,dbname,cdbflag,dbfiledest,stype,charset,redosize,dbtype,dbctype,crs_nodes,dbname,pdbsettings,initparams,arcmode,prereq,tdewallet)
       cmd='\n'.join(line.lstrip() for line in rspdata.splitlines())

       return cmd
   
   def get_pdb_params(self):
       """
       Perform the asm disk group creation
       """
       pdbnum=self.ora_env_dict["PDB_COUNT"] if self.ocommon.check_key("PDB_COUNT",self.ora_env_dict) else  "1"
       pdbname=self.ora_env_dict["ORACLE_PDB_NAME"] if self.ocommon.check_key("ORACLE_PDB_NAME",self.ora_env_dict) else  "ORCLPDB"
       rspdata='''-numberOfPDBs {0} \
        -pdbAdminPassword HIDDEN_STRING \
         -pdbName {1}'''.format(pdbnum,pdbname) 
       cmd='\n'.join(line.lstrip() for line in rspdata.splitlines()) 
       return  cmd

   def get_init_params(self):
       """
       Perform the asm disk group creation
       """
       sgasize=self.ora_env_dict["INIT_SGA_SIZE"] if self.ocommon.check_key("INIT_SGA_SIZE",self.ora_env_dict) else  None
       pgasize=self.ora_env_dict["INIT_PGA_SIZE"] if self.ocommon.check_key("INIT_PGA_SIZE",self.ora_env_dict) else  None
       processes=self.ora_env_dict["INIT_PROCESSES"] if self.ocommon.check_key("INIT_PROCESSES",self.ora_env_dict) else  None
       dbname,osid,dbuname=self.ocommon.getdbnameinfo()
       dgname=self.ocommon.setdgprefix(self.ocommon.getcrsdgname())
       dbdest=self.ocommon.setdgprefix(self.ocommon.getdbdestdgname(dgname))
       dbrdest=self.ocommon.setdgprefix(self.ocommon.getdbrdestdgname(dbdest))
       dbrdestsize=self.ora_env_dict["DB_RECOVERY_FILE_DEST_SIZE"] if self.ocommon.check_key("DB_RECOVERY_FILE_DEST_SIZE",self.ora_env_dict) else None
       cpucount=self.ora_env_dict["CPU_COUNT"] if self.ocommon.check_key("CPU_COUNT",self.ora_env_dict) else None
       dbfiles=self.ora_env_dict["DB_FILES"] if self.ocommon.check_key("DB_FILES",self.ora_env_dict) else "1024" 
       lgbuffer=self.ora_env_dict["LOG_BUFFER"] if self.ocommon.check_key("LOG_BUFFER",self.ora_env_dict) else "256M"
       dbrettime=self.ora_env_dict["DB_FLASHBACK_RETENTION_TARGET"] if self.ocommon.check_key("DB_FLASHBACK_RETENTION_TARGET",self.ora_env_dict) else "120" 
       dbblkck=self.ora_env_dict["DB_BLOCK_CHECKSUM"] if self.ocommon.check_key("DB_BLOCK_CHECKSUM",self.ora_env_dict) else "TYPICAL"
       dblwp=self.ora_env_dict["DB_LOST_WRITE_PROTECT"] if self.ocommon.check_key("DB_LOST_WRITE_PROTECT",self.ora_env_dict) else "TYPICAL"
       ptpc=self.ora_env_dict["PARALLEL_THREADS_PER_CPU"] if self.ocommon.check_key("PARALLEL_THREADS_PER_CPU",self.ora_env_dict) else "1"
       dgbr1=self.ora_env_dict["DG_BROKER_CONFIG_FILE1"] if self.ocommon.check_key("DG_BROKER_CONFIG_FILE1",self.ora_env_dict) else dbdest
       dgbr2=self.ora_env_dict["DG_BROKER_CONFIG_FILE2"] if self.ocommon.check_key("DG_BROKER_CONFIG_FILE2",self.ora_env_dict) else dbrdest
       remotepasswdfile="REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE"
       lgformat="LOG_ARCHIVE_FORMAT=%t_%s_%r.arc"
   
       initprm='''db_recovery_file_dest={0},db_create_file_dest={2},{3},{4},db_unique_name={5},db_files={6},LOG_BUFFER={7},DB_FLASHBACK_RETENTION_TARGET={8},DB_BLOCK_CHECKSUM={9},DB_LOST_WRITE_PROTECT={10},PARALLEL_THREADS_PER_CPU={11},DG_BROKER_CONFIG_FILE1={12},DG_BROKER_CONFIG_FILE2={13}'''.format(dbrdest,dbrdest,dbdest,remotepasswdfile,lgformat,dbuname,dbfiles,lgbuffer,dbrettime,dbblkck,dblwp,ptpc,dgbr1,dgbr2)

       if sgasize:
           initprm= initprm + ''',sga_target={0},sga_max_size={0}'''.format(sgasize)

       if pgasize:
          initprm= initprm + ''',pga_aggregate_size={0}'''.format(pgasize)
   
       if processes:
          initprm= initprm + ''',processes={0}'''.format(processes)
  
       if cpucount:
          initprm= initprm + ''',cpu_count={0}'''.format(cpucount)

       if dbrdestsize:
          initprm = initprm + ''',db_recovery_file_dest_size={0}'''.format(dbrdestsize)
 
       initparams=""" -initparams '{0}'""".format(initprm)

       return initparams
