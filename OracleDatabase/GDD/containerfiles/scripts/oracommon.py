#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

from oralogger import *
from oraenv import *
import subprocess
import sys
import os
import socket
import re
import string
import random

class OraCommon:
      def __init__(self,oralogger,orahandler,oraenv):
        self.ologger = oralogger
        self.ohandler = orahandler
        self.oenv  = oraenv.get_instance()
        self.ora_env_dict = oraenv.get_env_vars()
        self.file_name  = os.path.basename(__file__)
      def _get_exec_env(self, env):
          """
          Build the execution environment, preserving process env by default.
          """
          base_env = os.environ.copy()
          if env:
             merged = base_env
             merged.update(env)
             return merged
          return base_env

      def _log_message(self, level, lmessage, fname, force_console=False):
          """
          Common log formatter used by info/error/warn wrappers.
          """
          funcname = sys._getframe(2).f_code.co_name
          target_file = fname if fname else self.file_name
          message = '''{:^15}-{:^20}:{}'''.format(target_file,funcname,lmessage)
          self.ologger.msg_ = message
          self.ologger.logtype_ = level
          prev_force = getattr(self.ologger, "force_console_", False)
          self.ologger.force_console_ = force_console
          try:
             self.ohandler.handle(self.ologger)
          finally:
             self.ologger.force_console_ = prev_force

      def run_sqlplus(self,cmd,sql_cmd,dbenv):
          """
          This function execute the ran sqlplus or rman script and return the output
          """
          try:
            message="Received Command : {0}\n{1}".format(self.mask_str(cmd),self.mask_str(sql_cmd))
            self.log_info_message(message,self.file_name)
            sql_cmd=self.unmask_str(sql_cmd)
            cmd=self.unmask_str(cmd)
            p = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=self._get_exec_env(dbenv),
                shell=True,
                universal_newlines=True
            )
            p.stdin.write(sql_cmd)
            (stdout,stderr),retcode = p.communicate(),p.returncode
          except Exception:
            error_msg=sys.exc_info()
            self.log_error_message(error_msg,self.file_name)
            self.prog_exit(self)

          return stdout.replace("\n\n", "\n"),stderr,retcode

      def execute_cmd(self,cmd,dir,env):
          """
          Execute the OS command on host
          """
          try:
            message="Received Command : {0}".format(self.mask_str(cmd))
            self.log_info_message(message,self.file_name)
            cmd=self.unmask_str(cmd)
            out = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                env=self._get_exec_env(env),
                cwd=dir
            )
            (output,error),retcode = out.communicate(),out.returncode
          except Exception:
            error_msg=sys.exc_info()
            self.log_error_message(error_msg,self.file_name)
            self.prog_exit(self)

          return output,error,retcode

      def mask_str(self,mstr):
          """
           Function to mask sensitive placeholders.
          """
          newstr=None
          if self.oenv.encrypt_str__:
             newstr=mstr.replace('HIDDEN_STRING','********')
          if newstr:
             return newstr
          else:
             return mstr
          

      def unmask_str(self,mstr):
          """
          Function to restore masked placeholders.
          """
          newstr=None
          if self.oenv.encrypt_str__:
             newstr=mstr.replace('HIDDEN_STRING',self.oenv.original_str__.rstrip())
          if newstr:
             return newstr
          else:
             return mstr

      def set_mask_str(self,mstr):
          """
          Enable string masking for logs.
          """
          if mstr:
             self.oenv.encrypt_str__ = True
             self.oenv.original_str__ = mstr
          else:
             message = "Masked String is empty so no change required in encrypted String Flag and original string in singleton class"
             self.log_info_message(message,self.file_name)

      def unset_mask_str(self):
          """
          Disable string masking for logs.
          """
          self.oenv.encrypt_str__ = None
          self.oenv.original_str__ = None

      def prog_exit(self,message=None):
          """
          This function exit the program because of some error
          """
          sys.exit(127)

      def log_info_message(self,lmessage,fname=None):
          """
          Print the INFO message in the logger
          """
          self._log_message("INFO", lmessage, fname)

      def log_error_message(self,lmessage,fname=None):
          """
          Print the Error message in the logger
          """
          self._log_message("ERROR", lmessage, fname)

      def log_warn_message(self,lmessage,fname=None):
          """
          Print the Error message in the logger
          """
          self._log_message("WARN", lmessage, fname)

      def log_result_message(self, success, lmessage, fname=None):
          """
          Emit concise result summary that is always visible on console.
          """
          state = "SUCCESS" if success else "FAILURE"
          level = "INFO" if success else "ERROR"
          summary = "{0}: {1}".format(state, lmessage)
          self._log_message(level, summary, fname, force_console=True)

      def check_sql_err(self,output,err,retcode,status):
          """
          Check if there are any error in sql command output
          """
          match=None
          msg2='''Sql command  failed.Flag is set not to ignore this error.Please Check the logs,Exiting the Program!'''
          msg3='''Sql command  failed.Flag is set to ignore this error!'''
          self.log_info_message("output : " + str(output or "no Output"),self.file_name)
       #   self.log_info_message("Error  : " + str(err or  "no Error"),self.file_name)
       #   self.log_info_message("Sqlplus return code : " + str(retcode),self.file_name)
       #   self.log_info_message("Command Check Status Set to :" + str(status),self.file_name)

          if status:
             if (retcode!=0):
                self.log_info_message("Error  : " + str(err or  "no Error"),self.file_name)
                self.log_error_message("Sql Login Failed.Please Check the logs,Exiting the Program!",self.file_name)
                self.prog_exit(self)

          match=re.search("(?i)(?m)error",output)
          if status:
             if (match):
                self.log_error_message(msg2,self.file_name)
                self.prog_exit("error")
             else:
                self.log_info_message("Sql command completed successfully",self.file_name)
          else:
             if (match):
                self.log_warn_message("Sql command failed. Flag is set to ignore the error.",self.file_name)
             else:
                self.log_info_message("SQL command completed successfully.",self.file_name)

      def check_os_err(self,output,err,retcode,status):
          """
          Check if there are any error in OS command execution
          """
          msg1='''OS command returned code : {0} and returned output : {1}'''.format(str(retcode),str(output or "no Output"))
          msg2='''OS command returned code : {0}, returned error : {1}, and returned output : {2}'''.format(str(retcode),str(err or  "no returned error"),str(output or "no returned output"))
          msg3='''OS command  failed. Flag is set to ignore this error!'''

          if status:
            if (retcode != 0):
               self.log_error_message(msg2,self.file_name)
               self.prog_exit(self)
            else:
               self.log_info_message(msg1,self.file_name)
          else:
            if (retcode != 0):
               self.log_warn_message(msg2,self.file_name)
               self.log_warn_message(msg3,self.file_name)
            else:
               self.log_info_message(msg1,self.file_name)

      def _run_sqlplus_and_check(self, login_cmd, sql_cmd, status, cmd_type, env=None):
          """
          Execute SQL/GDS command, then run common SQL error validation.
          """
          output,error,retcode = self.run_sqlplus(login_cmd, sql_cmd, env)
          self.log_info_message(
              "Calling check_sql_err() to validate the {0} return status".format(cmd_type),
              self.file_name
          )
          self.check_sql_err(output,error,retcode,status)
          return output,error,retcode

      def _get_sysdba_sqlplus_login(self, env_dict):
          """
          Build sqlplus sysdba login command for the provided ORACLE_HOME.
          """
          return '''{0}/bin/sqlplus "/as sysdba"'''.format(env_dict["ORACLE_HOME"])

      def _run_sysdba_sql(self, env_dict, sql_cmd, log_message=None, status=True, check_errors=True):
          """
          Execute a SQL command as sysdba with optional SQL error validation.
          """
          login_cmd = self._get_sysdba_sqlplus_login(env_dict)
          if log_message:
             self.log_info_message(log_message + sql_cmd,self.file_name)
          if check_errors:
             return self._run_sqlplus_and_check(login_cmd,sql_cmd,status,"sql command")
          return self.run_sqlplus(login_cmd,sql_cmd,None)

      def _run_gsm_lifecycle(self, env_dict, action):
          """
          Run basic gdsctl lifecycle command such as start/stop gsm.
          """
          gsmctl='''{0}/bin/gdsctl'''.format(env_dict["ORACLE_HOME"])
          gsmcmd='''{0} gsm;'''.format(action)
          return self._run_sqlplus_and_check(gsmctl,gsmcmd,None,"gsm command")

      def _ensure_env_key(self, key, default_value, warn_template):
          """
          Ensure env key exists in `ora_env_dict`; set default and warn if absent.
          """
          if not self.check_key(key, self.ora_env_dict):
             self.ora_env_dict = self.add_key(key, default_value, self.ora_env_dict)
             self.log_warn_message(warn_template.format(self.ora_env_dict[key]), self.file_name)
          return self.ora_env_dict[key]

      def check_key(self,key,env_dict):
          """
            Check the key if it exist in dictionary.
            Attributes:
               key (string): String to check if key exist in dictionary
               env_dict (dict): Contains the env variable related to seup
          """
          if key in env_dict:
             return True
          else:
             return False

      def empty_key(self,key):
          """
             key is empty and print failure message.
            Attributes:
               key (string): String is empty
          """
          msg='''Variable {0} is not defined. Exiting!'''.format(key)
          self.log_error_message(msg,self.file_name)
          self.prog_exit(self)

      def add_key(self,key,value,env_dict):
          """
            Add the key in the dictionary.
            Attributes:
               key (string): key String to add in the dictionary
               value (String): value String to add in dictionary

            Return:
               dict
          """
          if self.check_key(key,env_dict):
             msg='''Variable {0} already exist in the env variables'''.format(key)
             self.log_info_message(msg,self.file_name)
          else:
             if value:
                env_dict[key] = value
                self.oenv.update_env_vars(env_dict)
             else:
                msg='''Variable {0} value is not defined to add in the env variables. Exiting!'''.format(value)
                self.log_error_message(msg,self.file_name)
                self.prog_exit(self)

          return env_dict

      def update_key(self,key,value,env_dict):
          """
            update the key in the dictionary.
            Attributes:
               key (string): key String to update in the dictionary
               value (String): value String to update in dictionary

            Return:
               dict
          """
          if self.check_key(key,env_dict):
             if value:
                env_dict[key] = value
                self.oenv.update_env_vars(env_dict)
             else:
                msg='''Variable {0} value is not defined to update in the env variables!'''.format(key)
                self.log_warn_message(msg,self.file_name)
          else:
             msg='''Variable {0} already exist in the env variables'''.format(key)
             self.log_info_message(msg,self.file_name)

          return env_dict

      def check_file(self,file,local,remote,user):
          """
            check locally or remotely
            Attributes:
               file (string): file to be created
               local (boolean): file check on local node
               remote (boolean): file check on remote node
               node (string): remote node name on which file to be checked
               user (string): remote user to be connected
          """
          self.log_info_message("Inside check_file()",self.file_name)
          if local:
             if os.path.isfile(file):
                  return True
             else:
                  return False
               

      def read_file(self,fname):
          """
            Read the contents of a file and returns the contents to end user
            Attributes:
               fname (string): file to be read

            Return:
               file data (string)
          """
          with open(fname, 'r') as f1:
             fdata = f1.read()
          return fdata

      def write_file(self,fname,fdata):
          """
            write the contents to a file
            Attributes:
               fname (string): file to be written
               fdata (string): Contents to be written

            Return:
               file data (string)
          """
          with open(fname, 'w') as f1:
             f1.write(fdata)

      def append_file(self,fname,fdata):
          """
            append the contents to a file
            Attributes:
               fname (string): file to be appended
               fdata (string): Contents to be appended

            Return:
               file data (string)
          """
          with open(fname, 'a') as f1:
             f1.write(fdata)

      def create_dir(self,dir,local,remote,user):
          """
            Create dir locally or remotely
            Attributes:
               dir (string): dir to be created
               local (boolean): dir to be created locally
               remote (boolean): dir to be created remotely
               node (string): remote node name on which dir to be created
               user (string): remote user to be connected
          """
          self.log_info_message("Inside create_dir()",self.file_name)
          if local:
             if not os.path.isdir(dir):
                 cmd='''mkdir -p {0}'''.format(dir)
                 output,error,retcode=self.execute_cmd(cmd,None,None)
                 self.check_os_err(output,error,retcode,True)
             else:
                 msg='''Dir {0} already exist'''.format(dir)
                 self.log_info_message(msg,self.file_name)

          if remote:
             pass

      def create_file(self,file,local,remote,user):
          """
            Create file locally or remotely
            Attributes:
               file (string): file to be created
               local (boolean): file to be created locally
               remote (boolean): file to be created remotely
               node (string): remote node name on which file to be created
               user (string): remote user to be connected
          """
          self.log_info_message("Inside create_file()",self.file_name)
          if local:
             if not os.path.isfile(file):
                 cmd='''touch  {0}'''.format(file)
                 output,error,retcode=self.execute_cmd(cmd,None,None)
                 self.check_os_err(output,error,retcode,True)

          if remote:
             pass

      def shutdown_db(self,env_dict):
           """
           Shutdown the database
           """
           file="/home/oracle/shutDown.sh"
           if not os.path.isfile(file): 
              self.log_info_message("Inside shutdown_db()",self.file_name)
              sqlcmd='''
                shutdown immediate;
              '''
              output,error,retcode = self._run_sysdba_sql(
                 env_dict,
                 sqlcmd,
                 "Running the sqlplus command to shutdown the database: ",
                 True,
                 True
              )
           else:
              cmd='''sh {0} immediate'''.format(file)
              output,error,retcode=self.execute_cmd(cmd,None,None)
              self.check_os_err(output,error,retcode,True)
   
      def pre_standby_setup(self,env_dict):
           """
           Set the pre requirements of DG broker
           """
           sqlcmd='''
                alter system set dg_broker_start=true scope=both sid='*';
              '''
           output,error,retcode=self._run_sysdba_sql(
              env_dict,
              sqlcmd,
              "Running the sqlplus command to set the DG broker parameters: ",
              None,
              False
           )
           self.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
              
      def mount_db(self,env_dict):
           """
           Mount the database
           """
           self.log_info_message("Inside mount_db()",self.file_name)
           sqlcmd='''
                  startup mount;
           '''
           output,error,retcode = self._run_sysdba_sql(
              env_dict,
              sqlcmd,
              "Running the sqlplus command to mount the database: ",
              True,
              True
           )

      def start_db(self,env_dict):
           """
           startup the database
           """
           file="/home/oracle/startUp.sh"
           if not os.path.isfile(file):
              self.log_info_message("Inside start_db()",self.file_name)
              sqlcmd='''
                  startup;
              '''
              output,error,retcode = self._run_sysdba_sql(
                 env_dict,
                 sqlcmd,
                 "Running the sqlplus command to start the database: ",
                 True,
                 True
              )
           else:
              cmd='''sh {0}'''.format(file)
              output,error,retcode=self.execute_cmd(cmd,None,None)
              self.check_os_err(output,error,retcode,True)

      def nomount_db(self,env_dict):
           """
           Start the database in nomount mode.
           """
           self.log_info_message("Inside nomount_db()",self.file_name)
           sqlcmd='''
                 startup nomount;
           '''
           output,error,retcode = self._run_sysdba_sql(
              env_dict,
              sqlcmd,
              "Running the sqlplus command to start the database: ",
              True,
              True
           )

######### RAC DB Stop ########
      def stop_rac_db(self,dbuser,dbhome,dbuname,hostname):
         """
         stop the Database
         """
         path='''/usr/bin:/bin:/sbin:/usr/local/sbin:{0}/bin'''.format(dbhome)
         ldpath='''{0}/lib:/lib:/usr/lib'''.format(dbhome)
         cmd='''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl stop database -d {3}'''.format(dbhome,path,ldpath,dbuname)
         output,error,retcode=self.execute_cmd(cmd,None,None)
         self.check_os_err(output,error,retcode,True)

######### RAC DB Start ########
      def start_rac_db(self,dbuser,dbhome,dbuname,node=None,startoption=None):
         """
         Start the Database
         """
         path='''/usr/bin:/bin:/sbin:/usr/local/sbin:{0}/bin'''.format(dbhome)
         ldpath='''{0}/lib:/lib:/usr/lib'''.format(dbhome)

         if startoption is None:
            startflag=""
         else:
            startflag=''' -o {0}'''.format(startoption)

         cmd='''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl start database -d {3} {4}'''.format(dbhome,path,ldpath,dbuname,startflag)
         output,error,retcode=self.execute_cmd(cmd,None,None)
         self.check_os_err(output,error,retcode,True)


      def stop_gsm(self,env_dict):
           """
           Stop the GSM
           """
           self.log_info_message("Inside stop_gsm()",self.file_name)
           output,error,retcode = self._run_gsm_lifecycle(env_dict,"stop")

      def set_events(self,source):
         """
         Setting events at DB level
         """
         self.log_info_message("Inside set_events()",self.file_name)
         scope=''
         accepted_scope = ['spfile', 'memory', 'both']
 
         if self.check_key("DB_EVENTS",self.ora_env_dict):
            events=str(self.ora_env_dict["DB_EVENTS"]).split(";")

            for event in events:
              msg='''Setting up event {0}'''.format(event)
              self.log_info_message(msg,self.file_name)
              scope=''
              ohome=self.ora_env_dict["ORACLE_HOME"]
              inst_sid=self.ora_env_dict["ORACLE_SID"]
              sqlpluslogincmd=self.get_sqlplus_str(ohome,inst_sid,"sys",None,None,None,None,None,None,None)
              self.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
              source=event.split(":")
              if len(source) > 1:
                 if source[1].split("=")[0] == "scope":
                    scope=source[1].split("=")[1]
                     
              if scope not in accepted_scope:
                 sqlcmd="""
                    alter system set events='{0}';""".format(source[0])
              else:
                 sqlcmd="""
                    alter system set event='{0}' scope={1};""".format(source[0],scope)
              output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")
              
      def start_gsm(self,env_dict):
           """
           Start the GSM
           """
           self.log_info_message("Inside start_gsm()",self.file_name)
           output,error,retcode = self._run_gsm_lifecycle(env_dict,"start")

      def exec_gsm_cmd(self,gsmcmd,flag,env_dict):
           """
           Execute a GSM command and return output.
           """
           self.log_info_message("Inside exec_gsm_cmd()",self.file_name)
           gsmctl='''{0}/bin/gdsctl'''.format(env_dict["ORACLE_HOME"])
           if gsmcmd:
              output,error,retcode = self._run_sqlplus_and_check(gsmctl,gsmcmd,flag,"gsm command")
           else:
              self.log_info_message("GSM command is empty. Skipping execution and returning empty output.",self.file_name) 
              output=None
              error=None
              retcode=0

           return output,error,retcode         


      def check_substr_match(self,source_str,sub_str):
           """
            Check if substring exists
           """
           self.log_info_message("Inside check_substr_match()",self.file_name)
           if (source_str.find(sub_str) != -1):
              return True
           else:
              return False

      def find_str_in_string(self,source_str,delimeter,search_str):
         """Find case-insensitive token match after splitting by supported delimiter.

         Args:
             source_str ([string]): [string where you need to search]
             delimeter ([character]): [string delimeter]
             search_str ([string]): [string to be searched]
         """
         if delimeter == 'comma':
            new_str=source_str.split(',')
            for str in new_str:
               if str.lower() == search_str.lower():
                  return True
            return False
         
         return False
      
      def check_status_value(self,match):
           """
             return completed or not completed
           """
           self.log_info_message("Inside check_status_value()",self.file_name)
           if match:
              return 'completed'
           else:
              return 'notcompleted'

      def remove_file(self,fname):
           """
             Remove if file exist
           """
           self.log_info_message("Inside remove_file()",self.file_name)
           if os.path.exists(fname):
              os.remove(fname)

      def get_sid_desc(self,gdbname,ohome,sid,sflag):
           """
             get the SID_LISTENER_DESCRIPTION
           """
           self.log_info_message("Inside get_sid_desc()",self.file_name)
           sid_desc = ""
           if sflag == 'SID_DESC1':
              sid_desc = '''    )
                (SID_DESC =
                (GLOBAL_DBNAME = {0})
                (ORACLE_HOME = {1})
                (SID_NAME = {2})
                )
              )
              '''.format(gdbname,ohome,sid)
           elif sflag == 'SID_DESC':
               sid_desc = '''(SID_LIST =
                 (SID_DESC =
                 (GLOBAL_DBNAME = {0})
                 (ORACLE_HOME = {1})
                 (SID_NAME = {2})
                )
               )
              '''.format(gdbname,ohome,sid)
           else: 
              pass

           return sid_desc

      def get_lisora(self,port):
           """
             return listener.ora listener settings
           """
           self.log_info_message("Inside get_lisora()",self.file_name)
           listener='''LISTENER =
             (DESCRIPTION_LIST =
              (DESCRIPTION =
              (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = {0}))
              (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC{0}))
              )
             )
           '''.format(port)
           return listener

      def get_domain(self,ohost):
           """
           get the domain name from hostname
           """
           return ohost.partition('.')[2]
        
######### Get the Domain ########
      def get_host_domain(self):
         """
         Return Public Hostname
         """
         domain=None
         fqdn = socket.getfqdn()
         if '.' in fqdn:
           domain = fqdn.split('.', 1)[1]
         else:
           domain = None

         if domain is None:
            domain="example.info"

         return domain
   
######### Get the Public IP ########
      def get_ip(self,hostname,domain):
         """
         Return the Ip based on hostname
         """
         if not domain:
           domain=self.get_host_domain()
 
         return socket.gethostbyname(hostname)

      def get_global_dbdomain(self,ohost,gdbname):
           """
           get the global dbname 
           """
           domain = self.get_domain(ohost) 
           if domain:
             global_dbname = gdbname + domain
           else:
             global_dbname = gdbname 
              
           return gdbname

######### Sqlplus connect string  ###########
      def get_sqlplus_str(self,home,osid,dbuser,password,hostname,port,svc,osep,role,wallet):
         """
         return the sqlplus connect string
         """
         path='''/usr/bin:/bin:/sbin:/usr/local/sbin:{0}/bin'''.format(home)
         ldpath='''{0}/lib:/lib:/usr/lib'''.format(home)
         export_cmd='''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2};export ORACLE_SID={3}'''.format(home,path,ldpath,osid)
         if dbuser == 'sys' and password and hostname and port and svc:
            return '''{5};{6}/bin/sqlplus {0}/{1}@//{2}:{3}/{4} as sysdba'''.format(dbuser,password,hostname,port,svc,export_cmd,home)
         elif dbuser != 'sys' and password and hostname and svc:
            return '''{5};{6}/bin/sqlplus {0}/{1}@//{2}:{3}/{4}'''.format(dbuser,password,hostname,"1521",svc,export_cmd,home)
         elif dbuser and osep:
            return dbuser
         elif dbuser == 'sys' and not password:
            return '''{1};{0}/bin/sqlplus "/ as sysdba"'''.format(home,export_cmd)
         elif dbuser == 'sys' and  password:
            return '''{1};{0}/bin/sqlplus {2}/{3} as sysdba'''.format(home,export_cmd,dbuser,password)
         elif dbuser != 'sys' and password:
            return '''{1};{0}/bin/sqlplus {2}/{3}'''.format(home,export_cmd,dbuser,password)
         else:
            self.log_info_message("At least specify DB user and password for DB connectivity. Exiting...",self.file_name)
            self.prog_exit("127")

######### Sqlplus   ###########
      def get_inst_sid(self,dbuser,dbhome,osid,hostname):
         """
         return the sid
         """
         path='''/usr/bin:/bin:/sbin:/usr/local/sbin:{0}/bin'''.format(dbhome)
         ldpath='''{0}/lib:/lib:/usr/lib'''.format(dbhome)
         cmd='''export ORACLE_HOME={0};export PATH={1};export LD_LIBRARY_PATH={2}; {0}/bin/srvctl status database -d {3} | grep {4}'''.format(dbhome,path,ldpath,osid,hostname)
         output,error,retcode=self.execute_cmd(cmd,None,None)
         self.check_os_err(output,error,retcode,None)
         if len(output.split(" ")) > 1:
            inst_sid=output.split(" ")[1]
            return inst_sid
         else:
            return None


######## Get the DB Image  ###############
      def get_db_params(self):
          """
          This function return the DB home
          """
          dbhome=self.ora_env_dict["DB_HOME"]
          dbbase=self.ora_env_dict["DB_BASE"]
          dbuser=self.ora_env_dict["DB_USER"]
          oinv=self.ora_env_dict["INVENTORY"]

          return dbuser,dbhome,dbbase,oinv



######  Get SID, dbname,dbuname
      def getdbnameinfo(self):
         """
         this function returns the sid,dbname,dbuname
         """
         dbname=self.ora_env_dict["DB_NAME"] if self.check_key("DB_NAME",self.ora_env_dict) else "ORCLCDB"
         osid=dbname
         dbuname=self.ora_env_dict["DB_UNIQUE_NAME"] if self.check_key("DB_UNIQUE_NAME",self.ora_env_dict) else dbname

         return dbname,osid,dbuname


      def _get_default_password(self):
         """
         Resolve the default password source used by legacy getters.
         """
         return self.get_password(None)

######### Get Password ##############
      def get_os_password(self):
         """
         get the OS password
         """
         return self._get_default_password()

      def get_asm_passwd(self):
         """
         get the ASM password
         """
         return self._get_default_password()

      def get_db_passwd(self):
         """
         get the DB password
         """
         return self._get_default_password()

      def get_sys_passwd(self):
         """
         get the sys user password
         """
         return self._get_default_password()

      def _build_pkeyopt_flags(self, env_key, default_opts):
          """
          Build openssl pkeyutl -pkeyopt flags from env var. Expected format: a:b;c:d
          """
          pkeyopt_raw = ""
          if self.check_key(env_key, self.ora_env_dict):
             pkeyopt_raw = str(self.ora_env_dict[env_key]).strip()
          if not pkeyopt_raw:
             pkeyopt_raw = default_opts

          opts = []
          for item in pkeyopt_raw.split(';'):
             token = item.strip()
             if token:
                token = token.replace('"', '\"')
                opts.append('-pkeyopt "{0}"'.format(token))

          if len(opts) == 0:
             return ""
          return " " + " ".join(opts)

      def _resolve_pwd_volume(self):
          if self.check_key("PWD_VOLUME", self.ora_env_dict):
             return self.ora_env_dict["PWD_VOLUME"]
          return "/var/tmp"

      def _decrypt_pkeyutl_file(self, encrypted_file, output_file, key_file, pkeyopt_env_key, default_opts):
          pkeyopt_flags = self._build_pkeyopt_flags(pkeyopt_env_key, default_opts)
          cmd = "openssl pkeyutl -decrypt{3} -in \"{0}\" -out \"{1}\" -inkey \"{2}\"".format(
              encrypted_file,
              output_file,
              key_file,
              pkeyopt_flags,
          )
          output,error,retcode = self.execute_cmd(cmd,None,None)
          self.check_os_err(output,error,retcode,True)

      def _read_plain_secret_file(self, source_file):
          """
          Read mounted Kubernetes secret file content as plain text.
          """
          return self.read_file(source_file).strip()

      def _resolve_secret_mounts(self):
          self._ensure_env_key("SECRET_VOLUME", "/run/secrets", "SECRET_VOLUME not passed as an env variable. Setting default to {0}")
          self._ensure_env_key("KEY_SECRET_VOLUME", self.ora_env_dict["SECRET_VOLUME"], "KEY_SECRET_VOLUME not passed as an env variable. Setting default to {0}")
          return self.ora_env_dict["SECRET_VOLUME"], self.ora_env_dict["KEY_SECRET_VOLUME"], self._resolve_pwd_volume()

      def _read_secret_password(self, label, encrypted_file, key_file, password_file, decrypt_tmp_file, pkeyopt_env_key, default_pkeyopt, require_key_file=False):
          if require_key_file and (not key_file or not os.path.isfile(key_file)):
             msg = "{0} key file {1} does not exist. Exiting!".format(label, key_file)
             self.log_error_message(msg, self.file_name)
             self.prog_exit(self)

          if key_file and os.path.isfile(encrypted_file) and os.path.isfile(key_file):
             msg = "{0} password file {1} and key file {2} exist. OpenSSL decrypt flow selected.".format(label, encrypted_file, key_file)
             self.log_info_message(msg, self.file_name)
             self._decrypt_pkeyutl_file(encrypted_file, decrypt_tmp_file, key_file, pkeyopt_env_key, default_pkeyopt)
             return self._read_and_remove_temp_file(decrypt_tmp_file)

          if os.path.isfile(password_file):
             msg = "{0} password file {1} exists. Plain-text mounted secret flow selected.".format(label, password_file)
             self.log_info_message(msg, self.file_name)
             return self._read_plain_secret_file(password_file)

          return None

      def _read_and_remove_temp_file(self, fname):
          fdata = self.read_file(fname)
          self.remove_file(fname)
          return fdata.strip()

      def _resolve_tde_wallet_password(self):
          if self.check_key("TDE_PWD_FILE", self.ora_env_dict):
             return self.get_tde_passwd()
          return self.ora_env_dict["ORACLE_PWD"]

      def _read_latest_key_id(self, spool_file):
          cmd = "/bin/cat {0} | tail -n 3 | head -n +1 | xargs".format(spool_file)
          output,error,retcode = self.execute_cmd(cmd,None,None)
          self.check_os_err(output,error,retcode,None)
          return output.strip()

      def get_password(self,key):
            """
            get the password
            """
            default_pkeyopt = "rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256"

            if self.check_key("ORACLE_PWD", self.ora_env_dict):
               if len(str(self.ora_env_dict["ORACLE_PWD"]).strip()) > 0:
                  self.log_info_message("ORACLE_PWD is passed as an env variable. Check Passed!", self.file_name)
                  return self.ora_env_dict["ORACLE_PWD"]

            self._ensure_env_key("COMMON_OS_PWD_FILE", "common_os_pwdfile.enc", "COMMON_OS_PWD_FILE not passed as an env variable. Setting default to {0}")
            self._ensure_env_key("PWD_KEY", "pwd.key", "PWD_KEY not passed as an env variable. Setting default to {0}")
            self._ensure_env_key("PASSWORD_FILE", "oracle_pwd", "PASSWORD_FILE not passed as an env variable. Setting default to {0}")

            secret_volume, key_secret_volume, pwd_volume = self._resolve_secret_mounts()
            common_os_pwd_file = self.ora_env_dict["COMMON_OS_PWD_FILE"]
            pwd_key = self.ora_env_dict["PWD_KEY"]
            password_file_key = self.ora_env_dict["PASSWORD_FILE"]

            encrypted_pwd_file = "{0}/{1}".format(secret_volume, common_os_pwd_file)
            base_pwd_file = "{0}/{1}".format(secret_volume, password_file_key)
            private_key_file = "{0}/{1}".format(key_secret_volume, pwd_key)
            decrypted_tmp_file = "{0}/{1}".format(pwd_volume, common_os_pwd_file)

            self.log_info_message("Encrypted password file set to : " + encrypted_pwd_file, self.file_name)
            self.log_info_message("Private key file set to : " + private_key_file, self.file_name)
            self.log_info_message("Password file set to : " + base_pwd_file, self.file_name)
            self.log_info_message("pwd volume set : " + pwd_volume, self.file_name)

            password = self._read_secret_password(
                "DB admin",
                encrypted_pwd_file,
                private_key_file,
                base_pwd_file,
                decrypted_tmp_file,
                "PKEYOPT",
                default_pkeyopt,
                False,
            )

            if password is None:
               characters1 = string.ascii_letters + string.digits + "_-%#"
               str1 = ''.join(random.choice(string.ascii_uppercase) for i in range(4))
               str2 = ''.join(random.choice(characters1) for i in range(8))
               password = str1 + str2
               self.log_warn_message("No password file found. Generated random password.", self.file_name)

            if self.check_key("ORACLE_PWD", self.ora_env_dict):
               self.ora_env_dict = self.update_key("ORACLE_PWD", password, self.ora_env_dict)
            else:
               self.ora_env_dict = self.add_key("ORACLE_PWD", password, self.ora_env_dict)
            self.log_info_message("ORACLE_PWD set using password retrieval flow", self.file_name)
            return password

######### Get oraversion ##############
      def get_oraversion(self,home):
         """
         get the software version
         """
         cmd='''{0}/bin/oraversion -majorVersion'''.format(home)
         output,error,retcode=self.execute_cmd(cmd,None,None)
         self.check_os_err(output,error,retcode,True)

         return output 
      
####### Get DB lock file location #######
      def get_db_lock_location(self):
         """
         get the db location
         """
         if self.check_key("DB_LOCK_FILE_LOCATION",self.ora_env_dict):
            return self.ora_env_dict["DB_LOCK_FILE_LOCATION"]
         else:
            ### Please note that you should not change following path as SIDB team is maintaining lock files under following location
            return self.ora_env_dict["TMP_DIR"] + "/."

      def getTdeWalletMountLoc(self):
         tde_wallet_mount_loc = "/tdewallet/"
         if self.check_key("TDE_WALLET_MOUNT_LOC",self.ora_env_dict):
            tde_wallet_mount_loc = self.ora_env_dict["TDE_WALLET_MOUNT_LOC"]

         return tde_wallet_mount_loc

      def get_tde_passwd(self):
          default_pkeyopt = "rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256"

          if not self.check_key("TDE_PWD_FILE", self.ora_env_dict):
             msg = "TDE_PWD_FILE is not set. Exiting!"
             self.log_error_message(msg, self.file_name)
             self.prog_exit(self)

          secret_volume, key_secret_volume, pwd_volume = self._resolve_secret_mounts()
          tde_pwd_file = self.ora_env_dict["TDE_PWD_FILE"]
          tde_passwd_file = "{0}/{1}".format(secret_volume, tde_pwd_file)
          tde_tmp_file = "{0}/{1}".format(pwd_volume, tde_pwd_file)

          tde_key_file = None
          require_key_file = False
          if self.check_key("TDE_PWD_KEY", self.ora_env_dict):
             tde_pwd_key = self.ora_env_dict["TDE_PWD_KEY"]
             tde_key_file = "{0}/{1}".format(key_secret_volume, tde_pwd_key)
             require_key_file = True

          password = self._read_secret_password(
              "TDE",
              tde_passwd_file,
              tde_key_file,
              tde_passwd_file,
              tde_tmp_file,
              "TDE_PKEYOPT",
              default_pkeyopt,
              require_key_file,
          )
          if password is None:
             msg = "TDE password file {0} is not available. Exiting!".format(tde_passwd_file)
             self.log_error_message(msg, self.file_name)
             self.prog_exit(self)

          return password

####### Get the TDE Key ###############
      def export_tde_key(self,filename):
         """
         This function export the tde.
         """
         self.log_info_message("Inside export_tde_key()",self.file_name)
         tde_wallet_pwd = self._resolve_tde_wallet_password()

         pdbname = self.ora_env_dict["ORACLE_PDB"]

         tde_wallet_loc = self.getTdeWalletMountLoc() + "/catalog_latest_key.imp"
         tde_wallet_loc_root = self.getTdeWalletMountLoc() + "/catalog_latest_key_root.imp"
         tde_keys_export_file = self.getTdeWalletMountLoc() + "/keysExportFile"
         tmp_dir = self.ora_env_dict["TMP_DIR"]
         enckeyidroot = tmp_dir + "/enckeyidroot.out"
         enckeyid = tmp_dir + "/enckeyid.out"

         cmd="/bin/rm -f {0} {1} {2} {3} {4}".format(enckeyidroot,enckeyid,tde_wallet_loc,tde_wallet_loc_root,tde_keys_export_file)
         output,error,retcode=self.execute_cmd(cmd,None,None)

         sqlpluslogincmd="{0}/bin/sqlplus \"/as sysdba\"".format(self.ora_env_dict["ORACLE_HOME"])
         self.set_mask_str(tde_wallet_pwd)

         try:
            sqlcmd="""
         alter system set tde_configuration="keystore_configuration=file" scope=both;
         administer key management create keystore identified by {0};
         administer key management create auto_login keystore from keystore identified by {0};
         administer key management set key force keystore identified by {0} with backup;
         select con_id, wallet_type, status from v$encryption_wallet where con_id=1;
         """.format('HIDDEN_STRING')
            self.log_info_message("Running the sqlplus command to create tde key: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            sqlcmd="""
         variable latest_mkid_root varchar2(100)
         spool {2}
         select trim(key_id) from v$encryption_keys where (activation_time = (select max(activation_time) from v$encryption_keys where activating_pdbname like 'CDB$ROOT'));
         spool off
         alter session set container={1};
         administer key management set key force keystore identified by "{0}" with backup;
         spool {3}
         select trim(key_id) from v$encryption_keys where (activation_time = (select max(activation_time) from v$encryption_keys where activating_pdbname='{1}'));
         spool off
         """.format('HIDDEN_STRING',pdbname,enckeyidroot,enckeyid)
            self.log_info_message("Running the sqlplus command to export the tde root keyid: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            latest_mkid_root = self._read_latest_key_id(enckeyidroot)
            latest_mkid = self._read_latest_key_id(enckeyid)

            sqlcmd="""
           administer key management export encryption keys with secret {0} to '{1}' force keystore identified by  {0} with identifier in '{5}';
           administer key management export encryption keys with secret {0} to '{2}' force keystore identified by  {0} with identifier in '{4}';
         """.format('HIDDEN_STRING',tde_wallet_loc_root,tde_wallet_loc,pdbname,latest_mkid,latest_mkid_root)
            self.log_info_message("Running the sqlplus command to export the tde: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            sqlcmd="""
         select con_id, wallet_type, status from v$encryption_wallet where con_id=1;
         alter system set tablespace_encryption='AUTO_ENABLE' scope=SPFILE;
         alter pluggable database {0} save state;
         shutdown immediate;
         startup;
         show parameter tablespace_encryption;
         """.format(pdbname)
            self.log_info_message("Running the sqlplus command to restart the db: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")
            cmd="/bin/touch {0}".format(tde_keys_export_file)
            output,error,retcode=self.execute_cmd(cmd,None,None)
         finally:
            self.unset_mask_str()

####### Get the TDE Key ###############
      def import_tde_key(self,filename):
         """
         This function import the TDE key.
         """
         self.log_info_message("Inside import_tde_key()",self.file_name)
         tde_wallet_pwd = self._resolve_tde_wallet_password()

         pdbname = self.ora_env_dict["ORACLE_PDB"]
         catpdbname = "CATALOGPDB"
         tde_wallet_loc = self.getTdeWalletMountLoc() + "/catalog_latest_key.imp"
         tde_wallet_loc_root = self.getTdeWalletMountLoc() + "/catalog_latest_key_root.imp"
         tmp_dir = self.ora_env_dict["TMP_DIR"]
         enckeyidroot = tmp_dir + "/enckeyidroot.out"
         enckeyid = tmp_dir + "/enckeyid.out"

         cmd="/bin/rm -f {0} {1}".format(enckeyidroot,enckeyid)
         output,error,retcode=self.execute_cmd(cmd,None,None)

         sqlpluslogincmd="{0}/bin/sqlplus \"/as sysdba\"".format(self.ora_env_dict["ORACLE_HOME"])
         self.set_mask_str(tde_wallet_pwd)

         try:
            sqlcmd="""
         alter system set tde_configuration="keystore_configuration=file" scope=both;
         administer key management create keystore identified by {0};
         administer key management create auto_login keystore from keystore identified by {0};
         select con_id, wallet_type, status from v$encryption_wallet where con_id=1;
         """.format('HIDDEN_STRING')
            self.log_info_message("Running the sqlplus command to create tde key: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            sqlcmd="""
         ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET {0} FROM '{1}' FORCE KEYSTORE IDENTIFIED BY {0} WITH BACKUP ;
         ADMINISTER KEY MANAGEMENT IMPORT ENCRYPTION KEYS WITH SECRET {0} FROM '{2}' FORCE KEYSTORE IDENTIFIED BY {0} WITH BACKUP ;
         """.format('HIDDEN_STRING',tde_wallet_loc_root,tde_wallet_loc)
            self.log_info_message("Running the sqlplus command to import the tde key: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            sqlcmd="""
         variable latest_mkid_root varchar2(100)
         spool {1}
         select trim(key_id) from v$encryption_keys where (activation_time = (select max(activation_time) from v$encryption_keys where creator_pdbname like 'CDB$ROOT')) ;
         spool off
         spool {2}
         select trim(key_id) from v$encryption_keys where (activation_time = (select max(activation_time) from v$encryption_keys where creator_pdbname like '{0}')) ;
         spool off
         """.format(catpdbname,enckeyidroot,enckeyid)
            self.log_info_message("Running the sqlplus command to get the tde root keyid: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            latest_mkid_root = self._read_latest_key_id(enckeyidroot)
            latest_mkid = self._read_latest_key_id(enckeyid)

            sqlcmd="""
         administer key management use encryption key '{1}' force keystore identified by {0} with backup ;
         alter session set container={3};
         administer key management use encryption key '{2}' force keystore identified by {0} with backup ;
         """.format('HIDDEN_STRING',latest_mkid_root,latest_mkid,pdbname)
            self.log_info_message("Running the sqlplus command to use the tde key: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")

            sqlcmd="""
         alter session set container=cdb$root;
         select con_id, wallet_type, status from v$encryption_wallet;
         alter system set tablespace_encryption='AUTO_ENABLE' scope=SPFILE;
         alter pluggable database {0} save state;
         shutdown immediate;
         startup;
         show parameter tablespace_encryption;
         """.format(pdbname)
            self.log_info_message("Running the sqlplus command to restart the db: " + sqlcmd,self.file_name)
            output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,True,"sql command")
         finally:
            self.unset_mask_str()

####### Check PDB if it exist ###############
      def check_pdb(self,pdbname):
         """
         This function check the PDB.
         """
         self.log_info_message("Inside check_pdb()",self.file_name)
         sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(self.ora_env_dict["ORACLE_HOME"])
         self.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
         sqlcmd='''
         set heading off
         set feedback off
         select NAME from gv$pdbs;
         '''
         output,error,retcode = self._run_sqlplus_and_check(sqlpluslogincmd,sqlcmd,None,"sql command")
         pdblist=output.splitlines()
         self.log_info_message("Checking pdb " + pdbname, self.file_name)
         if pdbname in pdblist:
            return True
         else:
            return False

####### Create PDB if it does not exist ###############
      def create_pdb(self,ohome,opdb,inst_sid):
         """
         This function create the PDB.
         """
         self.log_info_message("Inside create_pdb()",self.file_name)
         self.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
         cmd='''{0}/bin/dbca -silent -createPluggableDatabase -pdbName {1}  -sourceDB {2} <<< HIDDEN_STRING'''.format(ohome,opdb,inst_sid)
         output,error,retcode=self.execute_cmd(cmd,None,None)
         self.unset_mask_str()
         self.check_os_err(output,error,retcode,True)



####### Create PDB tnsnames.ora entry ###############
      def create_pdb_tns_entry(self,ohome,opdb):
         """
         This function create the PDB tnsnames.ora entry.
         """
         self.log_info_message("Inside create_pdb_tns_entry()",self.file_name)
         tns_entry_string="""
{0} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = {0})
    )
  )

""".format(opdb)

         tns_file='''{0}/network/admin/tnsnames.ora'''.format(ohome)
         self.append_file(tns_file,tns_entry_string)
      
####### Create PDB tnsnames.ora entry for RAC DB###############
      def create_pdb_tns_entry_racdb(self,ohome,opdb,node):
         """
         This function create the PDB tnsnames.ora entry in the specified node
         """
         self.log_info_message("Inside create_pdb_tns_entry_racdb()",self.file_name)
         tns_entry_string="""
{0} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = {0})
    )
  )

""".format(opdb)
         try:
             tns_file='''{0}/network/admin/tnsnames.ora'''.format(ohome)
             cmd = """ssh {0} 'echo \"{1}\" >> {2}'""".format(node, tns_entry_string, tns_file)
             subprocess.run(cmd, shell=True, check=True)
             self.log_info_message("Successfully added tns entry on {0}".format(node),self.file_name)
         except subprocess.CalledProcessError as e:
             msg='''Failed to add  tns entry on {0}'''.format(node)
             self.log_error_message(msg,self.file_name)
             self.prog_exit(e)

######## Reset the DB Password in database ########
      def reset_passwd(self):
         """
         This function reset the password.
         """ 
         password_script='''{0}/{1}'''.format(self.ora_env_dict["HOME"],"setPassword.sh")
         self.log_info_message("Executing password reset", self.file_name)
         if self.check_key("ORACLE_PWD",self.ora_env_dict) and self.check_key("HOME",self.ora_env_dict) and os.path.isfile(password_script):
            cmd='''{0} {1} '''.format(password_script,'HIDDEN_STRING')
            self.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
            output,error,retcode=self.execute_cmd(cmd,None,None)
            self.check_os_err(output,error,retcode,True)
            self.unset_mask_str()
         else:
            msg='''Error Occurred! Either HOME DIR {0} does not exist, ORACLE_PWD {1} is not set or PASSWORD SCRIPT {2} does not exist'''.format(self.ora_env_dict["HOME"],self.ora_env_dict["ORACLE_PWD"],password_script)  
            self.log_error_message(msg,self.file_name)
            self.prog_exit()


######## Reset the DB Password in RAC database ########
      def reset_passwd_rac(self,ohome,opdb,inst_sid):
         """
         This function reset the password.
         """
         password_script='''{0}/{1}'''.format(self.ora_env_dict["HOME"],"setPasswordRac.sh")
         self.log_info_message("Executing password reset", self.file_name)
         if self.check_key("ORACLE_PWD",self.ora_env_dict) and self.check_key("HOME",self.ora_env_dict) and os.path.isfile(password_script):
            cmd='''{0} {1} {2} {3} {4}'''.format(password_script,'HIDDEN_STRING',inst_sid,opdb,ohome)
            self.set_mask_str(self.ora_env_dict["ORACLE_PWD"])
            output,error,retcode=self.execute_cmd(cmd,None,None)
            self.check_os_err(output,error,retcode,True)
            self.unset_mask_str()
         else:
            msg='''Error Occurred! Either HOME DIR {0} does not exist, ORACLE_PWD {1} is not set or PASSWORD SCRIPT {2} does not exist'''.format(self.ora_env_dict["HOME"],self.ora_env_dict["ORACLE_PWD"],password_script)
            self.log_error_message(msg,self.file_name)
            self.prog_exit()


######### Return All Cluster Nodes Using olsnodes ########
      def get_all_cls_nodes(self):
         """
         Checking all Cluster nodes using clsnodes
         """
         giuser,gihome,gibase,oinv=self.get_gi_params()
         cluster_nodes=None
         cmd = '''sudo su - {0} -c "{1}/bin/olsnodes"'''.format(giuser,gihome)
         output,error,retcode=self.execute_cmd(cmd,None,None)
         self.check_os_err(output,error,retcode,True)
         crs_nodes=""

         crs_node_list=output.split("\n")
         for node in crs_node_list:
               crs_nodes= crs_nodes + "," + node

         return crs_nodes.strip(",")



######## Get the GI Params  ###############
      def get_gi_params(self):
          """
          This function return the GI home
          """
          gihome=self.ora_env_dict["GRID_HOME"]
          gibase=self.ora_env_dict["GRID_BASE"]
          giuser=self.ora_env_dict["GRID_USER"]
          oinv=self.ora_env_dict["INVENTORY"]

          return giuser,gihome,gibase,oinv
