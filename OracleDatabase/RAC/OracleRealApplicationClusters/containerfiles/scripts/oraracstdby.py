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

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oracvu import *
from oragiprov import *
from oraasmca import *
from oraracprov import *

class OraRacStdby:
   """
   This class Add the RAC standby
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
         self.ogiprov             = OraGIProv(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
         self.oasmca              = OraAsmca(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
         self.oraracprov          = OraRacProv(self.ologger,self.ohandler,self.oenv,self.ocommon,self.ocvu,self.osetupssh)
      except BaseException as ex:
         ex_type, ex_value, ex_traceback = sys.exc_info()
         trace_back = traceback.extract_tb(ex_traceback)
         stack_trace = list()
         for trace in trace_back:
             stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1], trace[2], trace[3]))
         self.ocommon.log_info_message(ex_type.__name__,self.file_name)
         self.ocommon.log_info_message(ex_value,self.file_name)
         self.ocommon.log_info_message(stack_trace,self.file_name)

   def setup(self):
          """
           This function setup the RAC stndby on this machine
          """
          self.ocommon.log_info_message("Start setup()",self.file_name)
          ct = datetime.datetime.now()
          bts = ct.timestamp()
          sshFlag=False
          self.ogiprov.setup()
          pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
          crs_nodes=pub_nodes.replace(" ",",")
          for node in crs_nodes.split(","):
              self.oraracprov.clu_checks(node)          
          dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
          retcode1=self.ocvu.check_home(None,dbhome,dbuser)
          status=self.ocommon.check_rac_installed(retcode1)
          if not status:
            self.oraracprov.perform_ssh_setup()
            sshFlag=True
          status=self.ocommon.check_home_inv(None,dbhome,dbuser)
          if not status:
            self.ocommon.log_info_message("Start oraracprov.db_sw_install()",self.file_name)
            self.oraracprov.db_sw_install()
            self.ocommon.log_info_message("End oraracprov.db_sw_install()",self.file_name)
            self.ocommon.log_info_message("Start oraracprov.run_rootsh()",self.file_name)
            self.oraracprov.run_rootsh()
            self.ocommon.log_info_message("End oraracprov.run_rootsh()",self.file_name)
          if not self.ocommon.check_key("SKIP_DBCA",self.ora_env_dict):
             self.oraracprov.create_asmdg()
             status,osid,host,mode=self.ocommon.check_dbinst()
             hostname=self.ocommon.get_public_hostname()
             if status:
               msg='''Database instance {0} already exist on this machine {1}.'''.format(osid,hostname)
               self.ocommon.log_info_message(self.ocommon.print_banner(msg),self.file_name)
             else:
               if not sshFlag:
                  self.oraracprov.perform_ssh_setup()
               self.check_primary_db()
               self.ocommon.log_info_message("Start configure_primary_db()",self.file_name)
               self.configure_primary_db()
               self.ocommon.log_info_message("End configure_primary_db()",self.file_name)
               self.ocommon.log_info_message("Start create_standbylogs()",self.file_name)
               self.create_standbylogs()
               self.ocommon.log_info_message("End create_standbylogs()",self.file_name)
               #self.populate_tnsfile()
               #self.copy_tnsfile(dbhome,dbuser)
               self.ocommon.log_info_message("Start create_db()",self.file_name)
               self.create_db()
               self.ocommon.log_info_message("End create_db()",self.file_name)
               self.ocommon.log_info_message("Start configure_standby_db()",self.file_name)
               self.configure_standby_db()
               self.ocommon.log_info_message("End configure_standby_db()",self.file_name)
               ### Calling populate TNS again as create_db reset the oldtnames.ora
               #self.populate_tnsfile()
               #self.copy_tnsfile(dbhome,dbuser)
               self.configure_dgsetup() 
               self.restart_db()

          ct = datetime.datetime.now()
          ets = ct.timestamp()
          totaltime=ets - bts
          self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

   def get_stdby_variables(self):
         """
           Getting stdby variables
         """
         stdbydbuname =self.ora_env_dict["DB_UNIQUE_NAME"] if self.ocommon.check_key("DB_UNIQUE_NAME",self.ora_env_dict) else  "SORCLCDB"
         prmydbuname =self.ora_env_dict["PRIMARY_DB_UNIQUE_NAME"] if self.ocommon.check_key("PRIMARY_DB_UNIQUE_NAME",self.ora_env_dict) else  None
         prmydbport =self.ora_env_dict["PRIMARY_DB_SCAN_PORT"] if self.ocommon.check_key("PRIMARY_DB_SCAN_PORT",self.ora_env_dict) else  1521
         prmydbname =self.ora_env_dict["PRIMARY_DB_NAME"] if self.ocommon.check_key("PRIMARY_DB_NAME",self.ora_env_dict) else None
         prmyscanname =self.ora_env_dict["PRIMARY_DB_SCAN_NAME"] if self.ocommon.check_key("PRIMARY_DB_SCAN_NAME",self.ora_env_dict) else  None

         return stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname
        
   def get_primary_connect_str(self):
         '''
           return primary connect str
         '''
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
         osid=self.ora_env_dict["PRIMARY_DB_UNIQUE_NAME"] if self.ocommon.check_key("PRIMARY_DB_UNIQUE_NAME",self.ora_env_dict) else None
         connect_str=self.ocommon.get_sqlplus_str(dbhome,osid,osuser,"sys",'HIDDEN_STRING',prmyscanname,prmydbport,osid,None,None,None)

         return connect_str,osuser,dbhome,dbbase,oinv,osid

   def get_standby_connect_str(self):
         '''
           return standby connect str
         '''
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
         stdbyscanname=self.ora_env_dict["SCAN_NAME"] if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict) else self.prog_exit("127")
         stdbyscanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else  "1521"
         connect_str=self.ocommon.get_sqlplus_str(dbhome,stdbydbuname,osuser,"sys",'HIDDEN_STRING',stdbyscanname,stdbyscanport,stdbydbuname,None,None,None
)

         return connect_str,osuser,dbhome,dbbase,oinv,stdbydbuname

   def get_stdby_dg_name(self):
       '''
        return DG name
       '''
       dgname=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "+DATA"
       dbrdest=self.ora_env_dict["DB_RECOVERY_FILE_DEST"] if self.ocommon.check_key("DB_RECOVERY_FILE_DEST",self.ora_env_dict) else dgname
       dbrdestsize=self.ora_env_dict["DB_RECOVERY_FILE_DEST_SIZE"] if self.ocommon.check_key("DB_RECOVERY_FILE_DEST_SIZE",self.ora_env_dict) else "50G"
       dbdest=self.ora_env_dict["DB_CREATE_FILE_DEST"] if self.ocommon.check_key("DB_CREATE_FILE_DEST",self.ora_env_dict) else dbrdest
        
       return self.ocommon.setdgprefix(dbrdest),dbrdestsize,self.ocommon.setdgprefix(dbdest),self.ocommon.setdgprefix(dgname)

   def check_primary_db(self):
          """
          Checking primary DB before proceeding to STDBY Setup
          """
          stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
          self.ocommon.log_info_message("Checking primary DB",self.file_name)          
          status=None
          counter=1
          end_counter=45
    
          connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_primary_connect_str()
         
          while counter < end_counter:
             status=self.ocommon.check_setup_status(osuser,dbhome,osid,connect_str)
             if status == 'completed':
                break
             else:
               msg='''Primary DB {0} setup is still not completed as primary check did not return "completed". Sleeping for 60 seconds and sleeping count is {0}'''.format(counter)
               self.ocommon.log_info_message(msg,self.file_name)
               time.sleep(60)
               counter=counter+1

          if status == 'completed':
             msg='''Primary Database {0} is open!'''.format(prmydbuname)
             self.ocommon.log_info_message(msg,self.file_name)
          else:
             msg='''Primary DB {0} is not in open state.Primary DB setup did not complete or failed. Exiting...'''
             self.ocommon.log_error_message(msg,self.file_name)
             self.ocommon.prog_exit("127")
                                   
 
   def configure_primary_db(self):
         """
           Setup Primary for standby
         """
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_primary_connect_str()
         stdbyscanname=self.ora_env_dict["SCAN_NAME"] if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict) else self.prog_exit("127")
         stdbyscanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else  "1521"
         prmytnssvc=self.ocommon.get_tnssvc_str(prmydbuname,prmydbport,prmyscanname)
         stdbytnssvc=self.ocommon.get_tnssvc_str(stdbydbuname,stdbyscanport,stdbyscanname)
         msg='''Setting up Primary DB for standby'''
         self.ocommon.log_info_message(msg,self.file_name)
         stdbylgdg,dbrdestsize,stdbydbdg,dgname=self.get_stdby_dg_name() 
         lgdest1="""LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME={0}""".format(prmydbuname)
         lgdest2='''SERVICE="{0}" ASYNC VALID_FOR=(ONLINE_LOGFILE,PRIMARY_ROLE) DB_UNIQUE_NAME={1}'''.format(stdbytnssvc,stdbydbuname)
         dbconfig="""DG_CONFIG=({0},{1})""".format(prmydbuname,stdbydbuname)
         prmydbdg=self.ocommon.get_init_params("db_create_file_dest",connect_str)
         prmylsdg=self.ocommon.get_init_params("DB_RECOVERY_FILE_DEST",connect_str)
         dbconv="""'{0}','{1}'""".format(stdbydbdg,prmydbdg)
         lgconv="""'{0}','{1}'""".format(stdbylgdg,prmylsdg)
         prmy_dbname=self.ocommon.get_init_params("DB_NAME",connect_str)
         dgbroker=prmyscanname=self.ora_env_dict["DG_BROKER_START"] if self.ocommon.check_key("DG_BROKER_START",self.ora_env_dict) else "true"
         

         sqlcmd="""
          alter database force logging;
          alter database flashback on;
          alter system set db_recovery_file_dest_size=30G scope=both sid='*'; 
          alter system set LOG_ARCHIVE_DEST_1='{0}' scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_2='{1}' scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_STATE_1=ENABLE scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_STATE_2=ENABLE scope=both sid='*';
          alter system set LOG_ARCHIVE_CONFIG='{2}' scope=both sid='*';
          alter system set FAL_SERVER='{9}' scope=both sid='*';
          alter system set STANDBY_FILE_MANAGEMENT=AUTO scope=both sid='*';
          alter system set DB_FILE_NAME_CONVERT={4} scope=both sid='*';
          alter system set LOG_FILE_NAME_CONVERT={5} scope=both sid='*';
          alter system set  dg_broker_start=true scope=both sid='*';
          alter system set DB_BLOCK_CHECKSUM='TYPICAL' scope=both sid='*';
          alter system set DB_LOST_WRITE_PROTECT='TYPICAL' scope=both sid='*';
          alter system set DB_FLASHBACK_RETENTION_TARGET=120 scope=both sid='*';
          alter system set PARALLEL_THREADS_PER_CPU=1 scope=both sid='*'; 
         """.format(lgdest1,lgdest2,dbconfig,stdbydbuname,dbconv,lgconv,dgbroker,prmylsdg,prmydbdg,stdbytnssvc)

         output=self.ocommon.run_sql_cmd(sqlcmd,connect_str)

   def get_logfile_info(self,connect_str):
       """
         get the primary log info
       """
       sqlsetcmd=self.ocommon.get_sqlsetcmd()
       sqlcmd1='''
        {0}
        select max(thread#) from gv$log;
       '''.format(sqlsetcmd)        

       sqlcmd2='''
        {0}
        select count(*) from gv$log;
       '''.format(sqlsetcmd)

       sqlcmd3='''
        {0}
        select * from (select count(*) from v$log group by thread#)  where rownum < 2;
       '''.format(sqlsetcmd)

       sqlcmd4='''
        {0}
        select min(group#) from gv$log;
       '''.format(sqlsetcmd)

       sqlcmd5='''
        {0}
        select max(MEMBERS) from gv$log;
       '''.format(sqlsetcmd)

       sqlcmd6='''
        {0}
        select count(*) from gv$standby_log;
       ''' .format(sqlsetcmd)

       sqlcmd7='''
        {0}
        select max(group#) from gv$standby_log;
       '''.format(sqlsetcmd)

       sqlcmd8='''
       {0}
        select bytes from v$log where rownum < 2;
       '''.format(sqlsetcmd)
 
       sqlcmd9='''
       {0}
        select max(group#) from v$log;
       '''.format(sqlsetcmd)

       maxthread=self.ocommon.run_sql_cmd(sqlcmd1,connect_str)
       maxgrpcount=self.ocommon.run_sql_cmd(sqlcmd2,connect_str)
       maxgrpnum=self.ocommon.run_sql_cmd(sqlcmd3,connect_str)
       mingrpnum=self.ocommon.run_sql_cmd(sqlcmd4,connect_str)
       maxgrpmemnum=self.ocommon.run_sql_cmd(sqlcmd5,connect_str)
       maxstdbygrpcount=self.ocommon.run_sql_cmd(sqlcmd6,connect_str)
       maxstdbygrpnum=self.ocommon.run_sql_cmd(sqlcmd7,connect_str)
       filesize=self.ocommon.run_sql_cmd(sqlcmd8,connect_str)
       maxgrp=self.ocommon.run_sql_cmd(sqlcmd9,connect_str)

       return int(maxthread),int(maxgrpcount),int(maxgrpnum),int(mingrpnum),int(maxgrpmemnum),int(maxstdbygrpcount),maxstdbygrpnum,int(filesize),int(maxgrp)

   def create_standbylogs(self):
         """
         Setup standby logs on Primary
         """
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_primary_connect_str()
         maxthread,maxgrpcount,maxgrpnum,mingrpnum,maxgrpmemnum,maxstdbygrpcount,maxstdbygrpnum,filesize,maxgrp=self.get_logfile_info(connect_str)         
         threadcount=1
         mingrpmemnum=1
         stdbygrp=0
     
         msg='''
          Received Values :
           Max Thread={0}
           Max Log Group Count={1}
           Max Log Group Number={2}
           Min Log Group Num={3}
           Max Group Member = {4}
           Max Standby Group Count = {5}
           Max Standby Group Number = {6}
           File Size = {7}
           Max Groups = {8}
         '''.format(maxthread,maxgrpcount,maxgrpnum,mingrpnum,maxgrpmemnum,maxstdbygrpcount,maxstdbygrpnum,filesize,maxgrp)

         self.ocommon.log_info_message(msg,self.file_name)
         dbrdest=self.ocommon.get_init_params("DB_RECOVERY_FILE_DEST",connect_str)

         if maxstdbygrpcount != 0:
            if maxstdbygrpcount == ((maxgrp + 1) * maxthread):
              msg1='''The required standby logs already exist. The current number of max primary group is {1} and max threads are {3}. The standby logs groups is to  "((maxgrp + 1) * maxthread)"= {0} '''.format(((maxgrp + 1) * maxthread),maxgrp,maxthread)
              self.ocommon.log_info_message(msg1,self.file_name)
         else:
            stdbygrp=(maxgrp + 1) * maxthread
            msg1='''The current number of max primary log group is {1} and max threads are {2}. The required standby logs groups "((maxgrp + 1) * maxthread)"= {0}'''.format(((maxgrp + 1) * maxthread),maxgrp,maxthread)
            self.ocommon.log_info_message(msg1,self.file_name)

            # Setting the standby logs to the value which will start after maxgrpcount
            mingrpnum=(maxgrp+1)
            newstdbygrp=stdbygrp
            threadcount=1
            group_per_thread=((stdbygrp - maxgrp )/maxthread)
            group_per_thread_count=1

            msg='''Logfile thread maxthread={1}, groups per thread={2}'''.format(threadcount,maxthread,group_per_thread)
            self.ocommon.log_info_message(msg,self.file_name)
            msg='''Standby logfiles minigroup set to={0} and maximum group set to={1}'''.format(mingrpnum,newstdbygrp)
            self.ocommon.log_info_message(msg,self.file_name)
            msg='''Logfile group loop. mingrpnum={0},maxgrpnum={1}'''.format(mingrpnum,newstdbygrp)
            self.ocommon.log_info_message(msg,self.file_name)

            while threadcount <= maxthread:
              group_per_thread_count=1
              while group_per_thread_count <= group_per_thread:
                mingrpmemnum=1
                while mingrpmemnum <= maxgrpmemnum:
                  if mingrpmemnum == 1:
                      self.add_stdby_log_grp(threadcount,mingrpnum,filesize,dbrdest,connect_str,None)
                  else:
                      self.add_stdby_log_grp(threadcount,mingrpnum,filesize,dbrdest,connect_str,'member')
                  mingrpmemnum = mingrpmemnum + 1
                group_per_thread_count=group_per_thread_count + 1
                mingrpnum = mingrpnum + 1
              threadcount = threadcount + 1
              if mingrpnum >= newstdbygrp:
                break
                        
   def add_stdby_log_grp(self,threadcount,stdbygrp,filesize,dbrdest,connect_str,type):
     """
     This function will add standby log group
     """
     sqlcmd1=None
     sqlsetcmd=self.ocommon.get_sqlsetcmd()
     if type is None:   
        sqlcmd1='''
          {3}
          ALTER DATABASE ADD STANDBY LOGFILE THREAD {0} group {1} size {2};
        '''.format(threadcount,stdbygrp,filesize,sqlsetcmd)
     
     if type == 'member':
        sqlcmd1='''
          {2}
          ALTER DATABASE ADD STANDBY LOGFILE member '{0}' to group {1};
        '''.format(dbrdest,stdbygrp,sqlsetcmd)
    
     output=self.ocommon.run_sql_cmd(sqlcmd1,connect_str)
     
     
   def populate_tnsfile(self):
     """
      Populate TNS file"
     """
     stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
     connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_primary_connect_str()     
     prmyscanname=self.ora_env_dict["PRIMARY_DB_SCAN_NAME"] if self.ocommon.check_key("PRIMARY_DB_SCAN_NAME",self.ora_env_dict) else self.prog_exit("127")
     prmyscanport=self.ora_env_dict["PRIMARY_DB_SCAN_PORT"] if self.ocommon.check_key("PRIMARY_DB_SCAN_PORT",self.ora_env_dict) else  "1521" 
     stdbyscanname=self.ora_env_dict["SCAN_NAME"] if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict) else self.prog_exit("127")
     stdbyscanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else  "1521"
     self.create_local_tns_enteries(dbhome,prmydbuname,prmyscanname,prmyscanport,osuser,"oinstall")
     self.create_local_tns_enteries(dbhome,stdbydbuname,stdbyscanname,stdbyscanport,osuser,"oinstall")
     self.create_remote_tns_enteries(dbhome,stdbydbuname,connect_str,stdbyscanname,stdbyscanport)
     
   def create_local_tns_enteries(self,dbhome,dbuname,scan_name,port,osuser,osgroup):
       """
        Add enteries in tnsnames.ora
       """
       tnsfile='''{0}/network/admin/tnsnames.ora'''.format(dbhome)
       status=self.ocommon.check_file(tnsfile,"local",None,None)
       key='''{0}='''.format(dbuname)
       tnsentry='\n' + '''{2}=(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = {0})(PORT = {1})) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = {2})))'''.format(scan_name,port,dbuname)

       
       if status:
          fdata=self.ocommon.read_file(tnsfile)
          match=re.search(key,fdata,re.MULTILINE)
          if not match:
             msg='''tnsnames.ora : {1} exist. Populating tnsentry: {0}'''.format(tnsentry,tnsfile)
             self.ocommon.log_info_message(msg,self.file_name)
             self.ocommon.append_file(tnsfile,tnsentry)
       else:
          msg='''tnsnames.ora : {1} doesn't exist, creating the file. Populating tnsentry: {0}'''.format(tnsentry,tnsfile)
          self.ocommon.log_info_message(msg,self.file_name)
          self.ocommon.write_file(tnsfile,tnsentry) 

       cmd='''chown {1}:{2} {0}'''.format(tnsfile,osuser,osgroup)
       output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)

   def create_remote_tns_enteries(self,dbhome,dbuname,connect_str,scan_name,scan_port):
       """
        Add enteries in remote tnsnames.ora
       """
       sqlcmd="""
        begin
         dbms_scheduler.create_job (job_name    => 'OS_JOB',
            job_type    => 'executable',
            job_action  => '/opt/scripts/startup/scripts/cmdExec',
            number_of_arguments => 4,
            auto_drop   => TRUE);
            dbms_scheduler.set_job_argument_value ('OS_JOB', 1,'sudo');
            dbms_scheduler.set_job_argument_value ('OS_JOB', 2,'/usr/bin/python3');
	    dbms_scheduler.set_job_argument_value ('OS_JOB', 3,'/opt/scripts/startup/scripts/main.py');
            dbms_scheduler.set_job_argument_value ('OS_JOB', 4,'--addtns=\"scan_name={0};scan_port={1};db_unique_name={2}\"');
            DBMS_SCHEDULER.RUN_JOB(JOB_NAME => 'OS_JOB',USE_CURRENT_SESSION => TRUE);
        end; 
        /
        exit;        
       """.format(scan_name,scan_port,dbuname)

       output=self.ocommon.run_sql_cmd(sqlcmd,connect_str) 

   def copy_tnsfile(self,dbhome,osuser):
      """
       Copy TNSfile to remote machine
      """
      tnsfile='''{0}/network/admin/tnsnames.ora'''.format(dbhome)
      self.ocommon.copy_file_cluster(tnsfile,tnsfile,osuser) 

   def create_db(self):
     """
     Perform the DB Creation
     """
     cmd=""
     dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
     cmd=self.prepare_db_cmd()

     dbpasswd=self.ocommon.get_db_passwd()
     self.ocommon.set_mask_str(dbpasswd)
     output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
     self.ocommon.check_os_err(output,error,retcode,None)
     ### Unsetting the encrypt value to None
     self.ocommon.unset_mask_str()

   def prepare_db_cmd(self):
     """
     Perform the asm disk group creation
     """
     stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
     connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_primary_connect_str()
     dbuser,dbhome,dbase,oinv=self.ocommon.get_db_params()
     pub_nodes,vip_nodes,priv_nodes=self.ocommon.process_cluster_vars("CRS_NODES")
     crs_nodes=pub_nodes.replace(" ",",")

     dgname=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "+DATA"
     dbfiledest=self.ora_env_dict["DB_DATA_FILE_DEST"] if self.ocommon.check_key("DB_DATA_FILE_DEST",self.ora_env_dict) else dgname
     stype=self.ora_env_dict["DB_STORAGE_TYPE"] if self.ocommon.check_key("DB_STORAGE_TYPE",self.ora_env_dict) else  "ASM"
     dbctype=self.ora_env_dict["DB_CONFIG_TYPE"] if self.ocommon.check_key("DB_CONFIG_TYPE",self.ora_env_dict) else  "RAC"
     prmydbstr='''{0}:{1}/{2}'''.format(prmyscanname,prmydbport,prmydbuname)		 
     initparams=self.get_init_params()
     #memorypct=self.get_memorypct()

     rspdata='''su - {0} -c "echo HIDDEN_STRING | {1}/bin/dbca -silent -ignorePrereqFailure -createDuplicateDB  \
     -gdbname {2} \
     -sid {3} \
     -createAsStandby    \
     -adminManaged    \
     -sysPassword HIDDEN_STRING \
     -datafileDestination {4} \
     -storageType {5} \
     -nodelist {6} \
     -useOMF true \
     -remoteDBConnString {7} \
     -initparams {8} \
     -dbUniqueName {3} \
     -databaseConfigType {9}"'''.format(dbuser,dbhome,prmydbname,stdbydbuname,self.ocommon.setdgprefix(dbfiledest),stype,crs_nodes,prmydbstr,initparams,dbctype)
     cmd='\n'.join(line.lstrip() for line in rspdata.splitlines())

     return cmd

   def get_init_params(self):
      """
      Perform the asm disk group creation
      """
      stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
      connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_primary_connect_str()
		 
      prmydbdg=self.ocommon.get_init_params("db_create_file_dest",connect_str)
      prmylsdg=self.ocommon.get_init_params("DB_RECOVERY_FILE_DEST",connect_str)
      stdbylgdg,dbrdestsize,stdbydbdg,dgname=self.get_stdby_dg_name()
      dbrdest=stdbylgdg

      dbconfig="""DG_CONFIG=({0},{1})""".format(prmydbuname,stdbydbuname)
      lgdest1="""LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILE,ALL_ROLE) DB_UNIQUE_NAME={0}""".format(stdbydbuname)
      lgdest2="""SERVICE={0} ASYNC VALID_FOR=(ONLINE_LOGFILE,PRIMARY_ROLE) DB_UNIQUE_NAME={0}""".format(prmydbuname)
		 
      sgasize=self.ora_env_dict["INIT_SGA_SIZE"] if self.ocommon.check_key("INIT_SGA_SIZE",self.ora_env_dict) else  None
      pgasize=self.ora_env_dict["INIT_PGA_SIZE"] if self.ocommon.check_key("INIT_PGA_SIZE",self.ora_env_dict) else  None
      processes=self.ora_env_dict["INIT_PROCESSES"] if self.ocommon.check_key("INIT_PROCESSES",self.ora_env_dict) else  None
      dbuname=self.ora_env_dict["DB_UNIQUE_NAME"] if self.ocommon.check_key("DB_UNIQUE_NAME",self.ora_env_dict) else "SORCLCDB"
      dgname=self.ora_env_dict["CRS_ASM_DISKGROUP"] if self.ocommon.check_key("CRS_ASM_DISKGROUP",self.ora_env_dict) else "+DATA"
      dbconv="""'{0}','{1}'""".format(prmydbdg,stdbydbdg)
      lgconv="""'{0}','{1}'""".format(prmylsdg,stdbylgdg)
    

      cpucount=self.ora_env_dict["CPU_COUNT"] if self.ocommon.check_key("CPU_COUNT",self.ora_env_dict) else None 
      remotepasswdfile="REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE"
      lgformat="LOG_ARCHIVE_FORMAT=%t_%s_%r.arc"

      initprm="""db_recovery_file_dest={0},db_recovery_file_dest_size={1},db_create_file_dest={2}""".format(dbrdest,dbrdestsize,stdbydbdg,remotepasswdfile,lgformat,stdbydbuname,dbconv,lgconv,prmydbname,dbconfig,lgdest1,lgdest2,prmydbuname)
  
      #initprm="""db_recovery_file_dest={0},db_recovery_file_dest_size={1},db_create_file_dest={2},{3},{4},db_unique_name={5},db_file_name_convert={6},log_file_name_convert={7},db_name={8},LOG_ARCHIVE_CONFIG='{9}',LOG_ARCHIVE_DEST_1='{10}',LOG_ARCHIVE_DEST_2='{11}',STANDBY_FILE_MANAGEMENT='AUTO',FAL_SERVER={12}""".format(dbrdest,dbrdestsize,stdbydbdg,remotepasswdfile,lgformat,stdbydbuname,dbconv,lgconv,prmydbname,dbconfig,lgdest1,lgdest2,prmydbuname)

      if sgasize:
         initprm= initprm + ''',sga_target={0},sga_max_size={0}'''.format(sgasize)

      if pgasize:
        initprm= initprm + ''',pga_aggregate_size={0}'''.format(pgasize)

      if processes:
        initprm= initprm + ''',processes={0}'''.format(processes)

      if cpucount:
        initprm= initprm + ''',cpu_count={0}'''.format(cpucount)

      initparams='''{0}'''.format(initprm)

      return initparams

   def configure_standby_db(self):
         """
           Setup standby after creation using DBCA
         """
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_standby_connect_str()
         stdbyscanname=self.ora_env_dict["SCAN_NAME"] if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict) else self.prog_exit("127")
         stdbyscanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else  "1521"
         prmytnssvc=self.ocommon.get_tnssvc_str(prmydbuname,prmydbport,prmyscanname)
         stdbytnssvc=self.ocommon.get_tnssvc_str(stdbydbuname,stdbyscanport,stdbyscanname)

         msg='''Setting parameters in standby DB'''
         self.ocommon.log_info_message(msg,self.file_name)
         stdbylgdg,dbrdestsize,stdbydbdg,dgname=self.get_stdby_dg_name()
         lgdest1="""LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME={0}""".format(stdbydbuname)
         lgdest2='''SERVICE="{0}" ASYNC VALID_FOR=(ONLINE_LOGFILE,PRIMARY_ROLE) DB_UNIQUE_NAME={1}'''.format(prmytnssvc,prmydbuname)
         
 
         sqlcmd="""
          alter system set LOG_ARCHIVE_CONFIG='DG_CONFIG=({2},{3})' scope=both sid='*';
          alter system set dg_broker_config_file1='{4}' scope=spfile sid='*';
          alter system set dg_broker_config_file2='{4}' scope=spfile sid='*';
          alter system set FAL_SERVER='{5}' scope=both sid='*';
          alter system set  dg_broker_start=true scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_1='{0}' scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_2='{1}' scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_STATE_1=ENABLE scope=both sid='*';
          alter system set LOG_ARCHIVE_DEST_STATE_2=ENABLE scope=both sid='*';
          alter system set DB_FILES=1024 scope=spfile sid='*';
          alter system set LOG_BUFFER=256M scope=spfile sid='*';
          alter system set DB_BLOCK_CHECKSUM='TYPICAL' scope=spfile sid='*';
          alter system set DB_LOST_WRITE_PROTECT='TYPICAL' scope=spfile sid='*';
          alter system set DB_FLASHBACK_RETENTION_TARGET=120 scope=spfile sid='*';
          alter system set PARALLEL_THREADS_PER_CPU=1 scope=spfile sid='*';
          alter database recover managed standby database cancel;
          alter database flashback on;
          alter database recover managed standby database disconnect;
         """.format(lgdest1,lgdest2,prmydbuname,stdbydbuname,stdbydbdg,prmytnssvc)

         output=self.ocommon.run_sql_cmd(sqlcmd,connect_str)
         hostname = self.ocommon.get_public_hostname()
         self.ocommon.stop_rac_db(osuser,dbhome,stdbydbuname,hostname)
         self.ocommon.start_rac_db(osuser,dbhome,stdbydbuname,hostname,None)

   def configure_dgsetup(self):
         """
           Setup Data Guard
         """
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         osuser,dbhome,dbbase,oinv=self.ocommon.get_db_params()
         hostname = self.ocommon.get_public_hostname()
         inst_sid=self.ocommon.get_inst_sid(osuser,dbhome,stdbydbuname,hostname)
         connect_str=self.ocommon.get_dgmgr_str(dbhome,inst_sid,osuser,"sys","HIDDEN_STRING",prmyscanname,prmydbport,prmydbuname,None,"sysdba",None)
         stdbyscanname=self.ora_env_dict["SCAN_NAME"] if self.ocommon.check_key("SCAN_NAME",self.ora_env_dict) else self.prog_exit("127")
         stdbyscanport=self.ora_env_dict["SCAN_PORT"] if self.ocommon.check_key("SCAN_PORT",self.ora_env_dict) else  "1521"
         prmytnssvc=self.ocommon.get_tnssvc_str(prmydbuname,prmydbport,prmyscanname)
         stdbytnssvc=self.ocommon.get_tnssvc_str(stdbydbuname,stdbyscanport,stdbyscanname)

         dgcmd='''
           create configuration '{0}' as primary database is {0} connect identifier is "{2}";
           ADD DATABASE {1} AS CONNECT IDENTIFIER IS "{3}";
           enable configuration;            
            exit;
         '''.format(prmydbuname,stdbydbuname,prmytnssvc,stdbytnssvc)
         dbpasswd=self.ocommon.get_db_passwd()
         self.ocommon.set_mask_str(dbpasswd)
         output,error,retcode=self.ocommon.run_sqlplus(connect_str,dgcmd,None)
         self.ocommon.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
         self.ocommon.check_dgmgrl_err(output,error,retcode,None)
         self.ocommon.unset_mask_str()


   def restart_db(self):
         """
           restart DB
         """
         stdbydbuname,prmydbuname,prmydbport,prmydbname,prmyscanname=self.get_stdby_variables()
         connect_str,osuser,dbhome,dbbase,oinv,osid=self.get_standby_connect_str()
         hostname = self.ocommon.get_public_hostname()
         self.ocommon.stop_rac_db(osuser,dbhome,stdbydbuname,hostname)
         self.ocommon.start_rac_db(osuser,dbhome,stdbydbuname,hostname,None)
         

