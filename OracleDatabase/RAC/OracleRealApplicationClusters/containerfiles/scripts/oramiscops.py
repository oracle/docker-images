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
from oraasmca import *
from oraracdel import *
from oraracadd import *
from oraracprov import *
from oraracstdby import *

class OraMiscOps:
   """
   This class performs the misc RAC options such as RAC delete
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
         self.oracstdby           = OraRacStdby(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
      except BaseException as ex:
         traceback.print_exc(file = sys.stdout)

   def setup(self):
       """
       This function setup the RAC home on this machine
       """
       self.ocommon.log_info_message("Start setup()",self.file_name)
       ct = datetime.datetime.now()
       bts = ct.timestamp()
       #default version as 0 integer, will read from rsp file
       version=0
       if self.ocommon.check_key("GRID_RESPONSE_FILE",self.ora_env_dict):
               gridrsp=self.ora_env_dict["GRID_RESPONSE_FILE"]
               self.ocommon.log_info_message("GRID_RESPONSE_FILE parameter is set and file location is:" + gridrsp ,self.file_name)

               if os.path.isfile(gridrsp):
                 with open(gridrsp) as fp:
                   for line in fp:
                      if len(line.split("=")) == 2:
                         key=(line.split("=")[0]).strip()
                         value=(line.split("=")[1]).strip()
                         self.ocommon.log_info_message("KEY and Value pair set to: " + key + ":" + value ,self.file_name)
                         if key == "oracle.install.responseFileVersion":
                            match = re.search(r'v(\d{2})', value)
                            if match:
                              version=int(match.group(1))
                            else:
                                 # Default to version 23 if no match is found
                              version=23
               #print version in logs
               msg="Version detected in response file is {0}".format(version)
               self.ocommon.log_info_message(msg,self.file_name)                    
         ## Calling this function from here to make sure INSTALL_NODE is set
       if version == int(19) or version == int(21):
            self.ocommon.update_pre_23c_gi_env_vars_from_rspfile()
       else:
            # default to read when its either set as 23 in response file or if response file is not present
            self.ocommon.update_gi_env_vars_from_rspfile()
       if self.ocommon.check_key("DBCA_RESPONSE_FILE",self.ora_env_dict):
          self.ocommon.update_rac_env_vars_from_rspfile(self.ora_env_dict["DBCA_RESPONSE_FILE"])
       if self.ocommon.check_key("DEL_RACHOME",self.ora_env_dict):
          self.delracnode()
       else:
          pass

       if self.ocommon.check_key("TNS_PARAMS",self.ora_env_dict):
           self.populate_tnsfile()
       else:
           pass

       if self.ocommon.check_key("CHECK_RAC_INST",self.ora_env_dict):
          self.checkraclocal()
       else:
          pass

       if self.ocommon.check_key("CHECK_RAC_STATUS",self.ora_env_dict):
          mode1=self.checkracinst()
          if mode1=='OPEN':
             sys.exit(0)
          else:
             sys.exit(127)
       else:
          pass
         
       if self.ocommon.check_key("CHECK_GI_LOCAL",self.ora_env_dict):
          self.checkgilocal()
       else:
          pass

       if self.ocommon.check_key("CHECK_RAC_DB",self.ora_env_dict):
          self.checkracdb()
       else:
          pass

       if self.ocommon.check_key("CHECK_DB_ROLE",self.ora_env_dict):
          self.checkdbrole()
       else:
          pass


       if self.ocommon.check_key("CHECK_CONNECT_STR",self.ora_env_dict):
          self.checkconnstr()
       else:
          pass

       if self.ocommon.check_key("CHECK_PDB_CONNECT_STR",self.ora_env_dict):
          self.checkpdbconnstr()
       else:
          pass

       if self.ocommon.check_key("NEW_DB_LSNR_ENDPOINTS",self.ora_env_dict):
          self.setupdblsnr()
       else:
          pass

       if self.ocommon.check_key("NEW_LOCAL_LISTENER",self.ora_env_dict):
          self.setuplocallsnr()
       else:
          pass

       if self.ocommon.check_key("CHECK_DB_SVC",self.ora_env_dict):
          self.checkdbsvc()
       else:
          pass

       if self.ocommon.check_key("MODIFY_DB_SVC",self.ora_env_dict):
          self.modifydbsvc()
       else:
          pass

       if self.ocommon.check_key("CHECK_DB_VERSION",self.ora_env_dict):
          self.checkdbversion()
       else:
          pass

       if self.ocommon.check_key("RESET_PASSWORD",self.ora_env_dict):
          self.resetpassword()
       else:
          pass
       if self.ocommon.check_key("MODIFY_SCAN",self.ora_env_dict):
          self.modifyscan()
       else:
          pass
       if self.ocommon.check_key("UPDATE_ASMCOUNT",self.ora_env_dict):
          self.updateasmcount()
       else:
          pass
       if self.ocommon.check_key("UPDATE_LISTENERENDP",self.ora_env_dict):
          self.updatelistenerendp()
       else:
          pass
       if self.ocommon.check_key("LIST_ASMDG",self.ora_env_dict):
          self.listasmdg()
       else:
          pass
       if self.ocommon.check_key("LIST_ASMDISKS",self.ora_env_dict):
          self.listasmdisks()
       else:
          pass
       if self.ocommon.check_key("LIST_ASMDGREDUNDANCY",self.ora_env_dict):
          self.listasmdgredundancy()
       else:
          pass
       if self.ocommon.check_key("LIST_ASMINSTNAME",self.ora_env_dict):
          self.listasminstname()
       else:
          pass      
       if self.ocommon.check_key("LIST_ASMINSTSTATUS",self.ora_env_dict):
          self.listasminststatus()
       else:
          pass
       if self.ocommon.check_key("UPDATE_ASMDEVICES",self.ora_env_dict):
          self.updateasmdevices()
       else:
          pass
       if self.ocommon.check_key("RUN_DATAPATCH",self.ora_env_dict):
          self.run_datapatch()
       else:
          pass


       ct = datetime.datetime.now()
       ets = ct.timestamp()
       totaltime=ets - bts
       self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

   def delracnode(self):
       """
       This function delete the racnode
       """
       self.ocommon.del_node_params("DEL_PARAMS")
       msg="Creating and calling instance to delete the rac node"
       oracdel = OraRacDel(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
       self.ocommon.log_info_message(msg,self.file_name)
       oracdel.setup()

   def populate_tnsfile(self):
       """
       This function populate the tns entry
       """
       scanname,scanport,dbuname=self.process_tns_params("TNS_PARAMS")
       osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       self.oracstdby.create_local_tns_enteries(dbhome,dbuname,scanname,scanport,osuser,"oinstall") 
       tnsfile='''{0}/network/admin/tnsnames.ora'''.format(dbhome)
       self.ocommon.copy_file_cluster(tnsfile,tnsfile,osuser)

   def process_tns_params(self,key):
       """
        Process TNS params
       """
       scanname=None
       scanport=None
       dbuname=None

       self.ocommon.log_info_message("Processing TNS Params",self.file_name) 
       cvar_str=self.ora_env_dict[key]
       cvar_str=cvar_str.replace('"', '')
       cvar_dict=dict(item.split("=") for item in cvar_str.split(";"))
       for ckey in cvar_dict.keys():
           if ckey == 'scan_name':
              scanname = cvar_dict[ckey] 
           if ckey == 'scan_port':
              scanport = cvar_dict[ckey]
           if ckey == 'db_unique_name':
              dbuname = cvar_dict[ckey]

       if not scanport:
         scanport=1521

       if scanname and scanport and dbuname:
          return scanname,scanport,dbuname
       else:
           msg1='''scan_name={0},scan_port={1}'''.format((scanname or "Missing Value"),(scanport or "Missing Value"))
           self.ocommon.log_info_message(msg1,self.file_name)
           msg2='''db_unique_name={0}'''.format((dbuname or "Missing Value"))
           self.ocommon.log_info_message(msg2,self.file_name)
           self.ocommon.prog_exit("Error occurred")

   def checkracdb(self):
       """
        This will verify RAC DB
       """
       status=""
       mode=""
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       retcode1=0
       if retcode1 != 0:
          status="RAC_NOT_INSTALLED_OR_CONFIGURED"
       else:
          mode=self.checkracsvc()
          status=mode
             
       msg='''Database state is {0}'''.format(status)
       self.ocommon.log_info_message(msg,self.file_name)
       print(status)

   def checkconnstr(self):
       """
       Check the connect str
       """
       status=""
       mode=""
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       retcode1=0
       if retcode1 != 0:
          status="RAC_NOT_INSTALLED_OR_CONFIGURED"
       else:
          state=self.checkracsvc()
          if state == 'OPEN':
             mode=self.getconnectstr()
          else:
             mode="NOTAVAILABLE"

          status=mode

       msg='''Database connect str is {0}'''.format(status)
       self.ocommon.log_info_message(msg,self.file_name)
       print(status)

   def checkpdbconnstr(self):
       """
       Check the PDB connect str
       """
       status=""
       mode=""
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       retcode1=0
       if retcode1 != 0:
          status="RAC_NOT_INSTALLED_OR_CONFIGURED"
       else:
          state=self.checkracsvc()
          if state == 'OPEN':
             mode=self.getpdbconnectstr()
          else:
             mode="NOTAVAILABLE"

          status=mode

       msg='''PDB connect str is {0}'''.format(status)
       self.ocommon.log_info_message(msg,self.file_name)
       print(status)

   def checkdbrole(self):
       """
        This will verify RAC DB Role
       """
       status=""
       mode=""
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       #retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       retcode1=0
       if retcode1 != 0:
          status="RAC_NOT_INSTALLED_OR_CONFIGURED"
       else:
          mode=self.checkracsvc()
          if (mode == "OPEN") or ( mode == "MOUNT"):
            osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
            osid=self.ora_env_dict["DB_NAME"] if self.ocommon.check_key("DB_NAME",self.ora_env_dict) else "ORCLCDB"
            scanname=self.ora_env_dict["SCAN_NAME"]
            scanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else "1521"
            connect_str=self.ocommon.get_sqlplus_str(dbhome,osid,osuser,"sys",'HIDDEN_STRING',scanname,scanport,osid,None,None,None)
            status=self.ocommon.get_db_role(osuser,dbhome,osid,connect_str)
          else:
             status="NOTAVAILABLE"

       msg='''Database role set to {0}'''.format(status)
       self.ocommon.log_info_message(msg,self.file_name)
       print(status)

   def getconnectstr(self):
       """
       get the connect str
       """
       osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       osid=self.ora_env_dict["DB_NAME"] if self.ocommon.check_key("DB_NAME",self.ora_env_dict) else "ORCLCDB"
       scanname=self.ora_env_dict["SCAN_NAME"]
       scanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else "1521"
       ##connect_str=self.ocommon.get_sqlplus_str(dbhome,osid,osuser,"sys",'HIDDEN_STRING',scanname,scanport,osid,None,None,None)
       connect_str='''{0}:{1}/{2}'''.format(scanname,scanport,osid)
       
       return connect_str

   def getpdbconnectstr(self):
       """
       get the PDB connect str
       """
       svcname=None
       osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       pdb=self.ora_env_dict["PDB_NAME"] if self.ocommon.check_key("PDB_NAME",self.ora_env_dict) else "ORCLPDB"
       osid=self.ora_env_dict["DB_NAME"] if self.ocommon.check_key("DB_NAME",self.ora_env_dict) else "ORCLCDB"
       scanname=self.ora_env_dict["SCAN_NAME"]
       scanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else "1521"
       sname,osid,opdb,sparams=self.ocommon.get_service_name()
       status,msg=self.ocommon.check_db_service_status(sname,osid)
       if status:
          svcname = sname
       else:
          svcname = pdb
       self.ocommon.log_info_message(msg,self.file_name)
       ##connect_str=self.ocommon.get_sqlplus_str(dbhome,osid,osuser,"sys",'HIDDEN_STRING',scanname,scanport,osid,None,None,None)
       connect_str='''{0}:{1}/{2}'''.format(scanname,scanport,svcname)
   
       return connect_str

   def checkracsvc(self):
       """
       Check the RAC SVC
       """
       mode=""
       osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
       osid=self.ora_env_dict["DB_NAME"] if self.ocommon.check_key("DB_NAME",self.ora_env_dict) else "ORCLCDB"
       scanname=self.ora_env_dict["SCAN_NAME"]
       scanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else "1521"
       connect_str=self.ocommon.get_sqlplus_str(dbhome,osid,osuser,"sys",'HIDDEN_STRING',scanname,scanport,osid,None,None,None)
       status=self.ocommon.get_dbinst_status(osuser,dbhome,osid,connect_str)
       if self.ocommon.check_substr_match(status,"OPEN"):
         mode="OPEN"
       elif self.ocommon.check_substr_match(status,"MOUNT"):
         mode="MOUNT"
       elif self.ocommon.check_substr_match(status,"NOMOUNT"):
         mode="NOMOUNT"
       else:
         mode="NOTAVAILABLE"

       return mode
    
   def checkraclocal(self):
       """
       Check the RAC software
       """
       status=""
       mode=""
       dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
       retcode1=self.ocvu.check_home(None,dbhome,dbuser)
       retcode1=0
       if retcode1 != 0:
          status="RAC_NOT_INSTALLED_OR_CONFIGURED" 
       else:
          mode=self.checkracinst()
          status=mode

       msg='''Database instance state is {0}'''.format(status)
       self.ocommon.log_info_message(msg,self.file_name)
       print(status)
        
   def checkracinst(self):
       """
       This function check the rac inst is up
       """
       mode1=""
       msg="Checking RAC instance status"
       oracdb = OraRacProv(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
       self.ocommon.log_info_message(msg,self.file_name)
       status,osid,host,mode=self.ocommon.check_dbinst()
       if self.ocommon.check_substr_match(mode,"OPEN"):
         mode1="OPEN"
       elif self.ocommon.check_substr_match(mode,"MOUNT"): 
         mode1="MOUNT"
       elif self.ocommon.check_substr_match(mode,"NOMOUNT"): 
         mode1="NOMOUNT"
       else:
         mode1="NOTAVAILABLE"

       return mode1

   def checkgilocal(self):
       """
       Check GI
       """
       status=""
       retcode=self.checkgihome()
       if retcode != 0:
         status="GI_NOT_INSTALLED_OR_CONFIGURED"
       else:
         node=self.ocommon.get_public_hostname()
         retcode1=self.checkclulocal(node)
         if retcode1 != 0:
             status="NOT HEALTHY"
         else:
             status="HEALTHY"
       msg='''GI status is {0}'''.format(status)
       self.ocommon.log_info_message(msg,self.file_name)
       print(status)
      
   def checkclulocal(self,node):
       """
       This function check the cluster health
       """
       retcode=self.ocvu.check_clu(node,None)
       return retcode

   def checkgihome(self):
      """
       Check the GI home
      """
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      pubhostname = self.ocommon.get_public_hostname()
      retcode1=self.ocvu.check_home(pubhostname,gihome,giuser)
      return retcode1

   def setupdblsnr(self):
      """
       update db lsnr
      """
      value=self.ora_env_dict["NEW_DB_LSNR_ENDPOINTS"]
      self.ocommon.log_info_message("lsnr new end Points are set to :" + value,self.file_name )
      if self.check_key("DB_LISTENER_ENDPOINTS",self.ora_env_dict):
         self.ocommon.log_info_message("lsnr old end points were set to :" + self.ora_env_dict["DB_LISTENER_ENDPOINTS"],self.file_name )
         self.ora_env_dict=self.update_key("DB_LISTENER_ENDPOINTS",value,self.ora_env_dict)
      else:
         self.ora_env_dict=self.add_key("DB_LISTENER_ENDPOINTS",value,self.ora_env_dict) 
      self.ocommon.setup_db_lsnr()

   def setuplocallsnr(self):
      """
       update db lsnr
      """
      value=self.ora_env_dict["NEW_LOCAL_LISTENER"]
      self.ocommon.log_info_message("local lsnr new end Points are set to :" + value,self.file_name )
      if self.check_key("LOCAL_LISTENER",self.ora_env_dict):
         self.ocommon.log_info_message("lsnr old end points were set to :" + self.ora_env_dict["LOCAL_LISTENER"],self.file_name )
         self.ora_env_dict=self.update_key("LOCAL_LISTENER",value,self.ora_env_dict)
      else:
         self.ora_env_dict=self.add_key("LOCAL_LISTENER",value,self.ora_env_dict) 
      self.ocommon.set_local_listener()

   def checkdbversion(self):
         """
         This function check the db version
         """
         output=self.ocommon.get_dbversion()
         print(output)
            
   def checkdbsvc(self):
         """
         This function check the db service
         """
         svcname,osid,preferred,available=self.process_dbsvc_params("CHECK_DB_SVC")
         #osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
         if svcname and osid:
            status,msg=self.ocommon.check_db_service_status(svcname,osid)
            self.ocommon.log_info_message(msg,self.file_name)
            print(msg)
         else:
            print("NOTAVAILABLE")
            
   def modifydbsvc(self):
         """
         This function check the db service
         """
         svcname,osid,preferred,available=self.process_dbsvc_params("CHECK_DB_SVC")
         #osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
         if svcname and osid and preferred:
            status,msg=self.ocommon.check_db_service_status(svcname,osid)
            self.ocommon.log_info_message(msg,self.file_name)
            print(msg.strip("\r\n"))
         else:
            print("NOTAVAILABLE")
            
   def process_dbsvc_params(self,key):
       """
        check svc params
       """
       svcname=None
       preferred=None
       available=None
       dbsid=None

       self.ocommon.log_info_message("processing service params",self.file_name) 
       cvar_str=self.ora_env_dict[key]
       cvar_str=cvar_str.replace('"', '')
       cvar_dict=dict(item.split("=") for item in cvar_str.split(";"))
       for ckey in cvar_dict.keys():
           if ckey == 'service':
              svcname = cvar_dict[ckey] 
           if ckey == 'preferred':
              preferred = cvar_dict[ckey]
           if ckey == 'available':
              available = cvar_dict[ckey]
           if ckey == 'dbname':
              dbsid = cvar_dict[ckey]

       
       return svcname,dbsid,preferred,available

   def resetpassword(self):
      """
      resetting password
      """
      user,pdb,type,containerall=self.process_dbsvc_params("CHECK_DB_SVC")
      if type.lower() != 'os':
         self.ocommon.reset_dbuser_passwd(user,pdb,containerall)
      
   def process_resetpasswd_params(self,key):
       """
        process reset DB password params
       """
       user=None
       pdb=None
       type=None
       containerall=None

       self.ocommon.log_info_message("processing reset password params",self.file_name) 
       cvar_str=self.ora_env_dict[key]
       cvar_str=cvar_str.replace('"', '')
       cvar_dict=dict(item.split("=") for item in cvar_str.split(";"))
       for ckey in cvar_dict.keys():
           if ckey == 'user':
              user = cvar_dict[ckey] 
           if ckey == 'pdb':
              pdb = cvar_dict[ckey]
           if ckey == 'type':
              type = cvar_dict[ckey]
           if ckey == 'container':
              containerall = "all"

       
       return user,pdb,type,containerall
   
   def modifyscan(self):
      """
      modify scan details
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("modifing scan details params",self.file_name) 
      scanname=self.ora_env_dict["MODIFY_SCAN"]
      retvalue=self.ocommon.modify_scan(giuser,gihome,scanname)
      if not retvalue:
         status="MODIFY_SCAN_NOT_UPDATED"
         msg='''Scan Details not modified to {0}'''.format(scanname)
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)
         self.ocommon.prog_exit("Error occurred")
      else:
         msg='''Scan Details is now modified to {0}'''.format(scanname)
         status="MODIFY_SCAN_UPDATED_SUCCESSFULLY"
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)

   def updateasmcount(self):
      """
      update asm count details
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("updating asm count details params",self.file_name) 
      asmcount=self.ora_env_dict["UPDATE_ASMCOUNT"]
      retvalue=self.ocommon.updateasmcount(giuser,gihome,asmcount)
      if not retvalue:
         status="UPDATE_ASMCOUNT_NOT_UPDATED"
         msg='''ASM Counts Details is not updated to {0}'''.format(asmcount)
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)
         self.ocommon.prog_exit("Error occurred")
      else:
         msg='''ASM Counts Details is now updated to {0}'''.format(asmcount)
         status="UPDATE_ASMCOUNT_UPDATED_SUCCESSFULLY"
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)   
   
   def process_listenerendpoint_params(self,key):
      """
      check listenerendpoint params
      """
      status=""
      msg=""
      listenername=None
      portlist=None
   
      self.ocommon.log_info_message("processing listenerendpoint params {0}".format(key),self.file_name) 
      cvar_str=self.ora_env_dict[key]
      self.ocommon.log_info_message("processing listenerendpoint params {0}".format(cvar_str),self.file_name)
      cvar_str=cvar_str.replace('"', '')
      try:
         cvar_dict = dict(item.split("=") for item in cvar_str.split(";") if "=" in item)
      except ValueError as e:
         self.ocommon.prog_exit("Error occurred")
      for ckey in cvar_dict.keys():
         if ckey == 'lsnrname':
            listenername = cvar_dict[ckey]
         if ckey == 'portlist':
            portlist = cvar_dict[ckey]
      return listenername,portlist
          
   def updatelistenerendp(self):
      """
      update listener end points details
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("updating listener end points details params",self.file_name)
      listenername,portlist=self.process_listenerendpoint_params("UPDATE_LISTENERENDP")
      retvalue=self.ocommon.updatelistenerendp(giuser,gihome,listenername,portlist)
      if not retvalue:
         status="UPDATE_LISTENERENDPOINT_NOT_UPDATED"
         msg='''Listener {0} End Point Details is not updated to portlist {1}'''.format(listenername,portlist)
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)
         self.ocommon.prog_exit("Error occurred")
      else:
         msg='''Listener End Point Details is now updated to listenername-> {0} portlist-> {1}'''.format(listenername,portlist)
         status="UPDATE_LISTENERENDPOINT_UPDATED_SUCCESSFULLY"
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)   
   
   def process_asmdevices_params(self,key):
      """
      check asmdevices params
      """
      status=""
      msg=""
      diskname=None
      diskgroup=None
      processtype=None
   
      self.ocommon.log_info_message("processing asmdevices params {0}".format(key),self.file_name) 
      cvar_str=self.ora_env_dict[key]
      self.ocommon.log_info_message("processing asmdevices params {0}".format(cvar_str),self.file_name)
      cvar_str=cvar_str.replace('"', '')
      try:
         cvar_dict = dict(item.split("=") for item in cvar_str.split(";") if "=" in item)
      except ValueError as e:
         self.ocommon.prog_exit("Error occurred")
      for ckey in cvar_dict.keys():
         if ckey == 'diskname':
            diskname = cvar_dict[ckey]
         if ckey == 'diskgroup':
            diskgroup = cvar_dict[ckey]
         if ckey == 'processtype':
            processtype = cvar_dict[ckey]
      return diskname,diskgroup,processtype
   
   def updateasmdevices(self):
      """
      update asm devices details
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("updating asm devices details params",self.file_name) 
      diskname,diskgroup,processtype=self.process_asmdevices_params("UPDATE_ASMDEVICES")
      retvalue=self.ocommon.updateasmdevices(giuser,gihome,diskname,diskgroup,processtype)
      if not retvalue:
         status="UPDATE_ASMDEVICES_NOT_UPDATED"
         msg='''ASM Devices Details is not processed {0} to disk {1} for disk group {2}'''.format(processtype,diskname,diskgroup)
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)
         self.ocommon.prog_exit("Error occurred")
      else:
         msg='''ASM Devices Details is now processed {0} to disk {1} for disk group {2}'''.format(processtype,diskname,diskgroup)
         status="UPDATE_ASMDEVICES_UPDATED_SUCCESSFULLY"
         self.ocommon.log_info_message(msg,self.file_name)
         print(status)

   def listasmdg(self):
      """
      getting the ams details
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("getting the asm diskgroup list",self.file_name)
      retvalue=self.ocommon.check_asminst(giuser,gihome)
      if retvalue == 0:
         dglist=self.ocommon.get_asmdg(giuser,gihome)
         print(dglist)
      else:
         print("NOT READY")

   def listasmdisks(self):
      """
      getting the ams details
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("getting the asm diskgroup list",self.file_name)
      dg=self.ora_env_dict["LIST_ASMDISKS"]
      retvalue=self.ocommon.check_asminst(giuser,gihome)
      if retvalue == 0:
         dsklist=self.ocommon.get_asmdsk(giuser,gihome,dg)
         print(dsklist)
      else:
         print("NOT READY") 

   def listasmdgredundancy(self):
      """
      getting the asm disk redundancy
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      self.ocommon.log_info_message("getting the asm diskgroup list",self.file_name)
      dg=self.ora_env_dict["LIST_ASMDGREDUNDANCY"]
      retvalue=self.ocommon.check_asminst(giuser,gihome)
      if retvalue == 0:
         asmdgrd=self.ocommon.get_asmdgrd(giuser,gihome,dg)
         print(asmdgrd)
      else:
         print("NOT READY")


   def listasminststatus(self):
      """
      getting the asm instance status
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      retvalue=self.ocommon.check_asminst(giuser,gihome)      
      if retvalue == 0:
          print("STARTED")
      else:
          print("NOT_STARTED")

   def listasminstname(self):
      """
      getting the asm disk redundancy
      """
      status=""
      msg=""
      giuser,gihome,obase,invloc=self.ocommon.get_gi_params()
      sid=self.ocommon.get_asmsid(giuser,gihome)
      if sid is not None:
         print(sid)
      else:
         print("NOT READY")

   def run_datapatch(self):
      """
      Function to check and apply Oracle database patches using OPatch and Datapatch.
      """
      self.ocommon.log_info_message("Starting run_datapatch()", self.file_name)
      rundatapatch = self.ora_env_dict.get("RUN_DATAPATCH", "").strip().lower() in ["true", "1", "yes"]

      self.ocommon.log_info_message(f"Running datapatch with passed argument: {rundatapatch}", self.file_name)

      if not rundatapatch:
         self.ocommon.log_info_message("RUN_DATAPATCH is not set to true. Skipping datapatch execution.", self.file_name)
         return
      dbuser, dbhome, dbbase, oinv = self.ocommon.get_db_params()
      self.ocommon.log_info_message("ORACLE_HOME set to " + dbhome, self.file_name)
      self.ocommon.log_info_message("ORACLE_USER set to " + dbuser, self.file_name)
      self.ocommon.log_info_message("ORACLE_BASE set to " + dbbase, self.file_name)

      dbname, osid, dbuname = self.ocommon.getdbnameinfo()
      hostname = self.ocommon.get_public_hostname()
      inst_sid = self.ocommon.get_inst_sid(dbuser, dbhome, osid, hostname)
      self.ocommon.log_info_message("ORACLE_SID set to " + inst_sid, self.file_name)

      if not all([inst_sid, dbbase, dbhome, dbuser]):
         self.ocommon.log_info_message("Missing required Oracle environment variables.", self.file_name)
         return

      # Export required environment variables
      env_setup_cmd = "export ORACLE_SID={0}; export ORACLE_HOME={1}; export ORACLE_BASE={2}; ".format(inst_sid, dbhome, dbbase)

      # Fetch patches from OPatch
      cmd_lspatches = '''su - {0} -c "{1} {2}/OPatch/opatch lspatches"'''.format(dbuser, env_setup_cmd, dbhome)
      output, error, retcode = self.ocommon.execute_cmd(cmd_lspatches, None, None)
      self.ocommon.check_os_err(output, error, retcode, None)

      if retcode != 0:
         self.ocommon.log_info_message("Failed to fetch OPatch patches.", self.file_name)
         return

      opatch_patches = {line.split(";")[0].strip() for line in output.splitlines() if ";" in line}
      self.ocommon.log_info_message("OPatch Patches: " + str(opatch_patches), self.file_name)

      # Fetch patches from DBA_REGISTRY_SQLPATCH with proper ORACLE_SID export
      sql_query = "SELECT PATCH_ID FROM DBA_REGISTRY_SQLPATCH;"
      cmd_sqlpatch = '''su - {0} -c "{1} echo \\"{2}\\" | sqlplus -S / as sysdba"'''.format(dbuser, env_setup_cmd, sql_query)
      output, error, retcode = self.ocommon.execute_cmd(cmd_sqlpatch, None, None)
      self.ocommon.check_os_err(output, error, retcode, None)

      if retcode != 0:
         self.ocommon.log_info_message("Failed to fetch DBA_REGISTRY_SQLPATCH patches.", self.file_name)
         return

      sqlpatch_patches = {line.strip() for line in output.splitlines() if line.strip().isdigit()}

      # Compare patch lists
      missing_patches = opatch_patches - sqlpatch_patches
      extra_patches = sqlpatch_patches - opatch_patches

      self.ocommon.log_info_message("OPatch Patches: " + str(opatch_patches), self.file_name)
      self.ocommon.log_info_message("SQL Patch Patches: " + str(sqlpatch_patches), self.file_name)

      if not missing_patches and not extra_patches:
         self.ocommon.log_info_message("All patches are correctly applied.", self.file_name)
      else:
         if missing_patches:
            self.ocommon.log_info_message("These patches are missing in DBA_REGISTRY_SQLPATCH: " + str(missing_patches), self.file_name)
            self.ocommon.log_info_message("Running datapatch...", self.file_name)
            
            cmd_datapatch = '''su - {0} -c "{1} {2}/OPatch/datapatch -skip_upgrade_check"'''.format(dbuser, env_setup_cmd, dbhome)
            output, error, retcode = self.ocommon.execute_cmd(cmd_datapatch, None, None)
            self.ocommon.check_os_err(output, error, retcode, None)

            if retcode == 0:
                  self.ocommon.log_info_message("Datapatch execution completed successfully.", self.file_name)
            else:
                  self.ocommon.log_info_message("Datapatch execution failed.", self.file_name)

         if extra_patches:
            self.ocommon.log_info_message("These patches appear in DBA_REGISTRY_SQLPATCH but not in OPatch: " + str(extra_patches), self.file_name)

      self.ocommon.log_info_message("End run_datapatch()", self.file_name)