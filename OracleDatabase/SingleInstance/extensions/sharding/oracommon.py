#!/usr/bin/python

#############################
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

from oralogger import *
from oraenv import *
import subprocess
import sys
import time
import datetime
import os
import commands
import getopt
import shlex
import json
import logging
import socket
import re
import os.path
import socket

class OraCommon:
      def __init__(self,oralogger,orahandler,oraenv):
        self.ologger = oralogger
        self.ohandler = orahandler
        self.oenv  = oraenv.get_instance()
        self.file_name  = os.path.basename(__file__)

      def run_sqlplus(self,cmd,sql_cmd,dbenv):
          """
          This function execute the ran sqlplus or rman script and return the output
          """
          try:
            message="Received Command : {0}\n{1}".format(self.mask_str(cmd),self.mask_str(sql_cmd))
            self.log_info_message(message,self.file_name)
            sql_cmd=self.unmask_str(sql_cmd)
            cmd=self.unmask_str(cmd)
#            message="Received Command : {0}\n{1}".format(cmd,sql_cmd)
#            self.log_info_message(message,self.file_name)
            p = subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=dbenv,shell=True)
            p.stdin.write(sql_cmd)
            # (stdout,stderr), retcode = p.communicate(sqlplus_script.encode('utf-8')), p.returncode
            (stdout,stderr),retcode = p.communicate(),p.returncode
            #    stdout_lines = stdout.decode('utf-8').split("\n")
          except:
            error_msg=sys.exc_info()
            self.log_error_message(error_msg,self.file_name)
            self.prog_exit(self)

          return stdout,stderr,retcode

      def execute_cmd(self,cmd,env,dir):
          """
          Execute the OS command on host
          """
          try:
            message="Received Command : {0}".format(self.mask_str(cmd))
            self.log_info_message(message,self.file_name)
            cmd=self.unmask_str(cmd)
            out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            (output,error),retcode = out.communicate(),out.returncode
          except:
            error_msg=sys.exc_info()
            self.log_error_message(error_msg,self.file_name)
            self.prog_exit(self)

          return output,error,retcode

      def mask_str(self,mstr):
          """
           Function to mask the string.
          """
          newstr=None
          if self.oenv.encrypt_str__:
             newstr=mstr.replace('HIDDEN_STRING','********')
 #            self.log_info_message(newstr,self.file_name)
          if newstr:
     #        message = "Masked the string as encryption flag is set in the singleton class"
     #        self.log_info_message(message,self.file_name)
             return newstr
          else:
             return mstr
          

      def unmask_str(self,mstr):
          """
          Function to unmask the string.
          """
          newstr=None
          if self.oenv.encrypt_str__:
             newstr=mstr.replace('HIDDEN_STRING',self.oenv.original_str__.rstrip())
      #       self.log_info_message(newstr,self.file_name)
          if newstr:
      #       message = "Unmasked the encrypted string and returning original string from singleton class"
      #       self.log_info_message(message,self.file_name)
             return newstr
          else:
             return mstr

      def set_mask_str(self,mstr):
          """
          Function to unmask the string.
          """
          if mstr:
     #        message = "Setting encrypted String flag to True and original string in singleton class"
     #        self.log_info_message(message,self.file_name)
             self.oenv.encrypt_str__ = True
             self.oenv.original_str__ = mstr
          else:
             message = "Masked String is empty so no change required in encrypted String Flag and original string in singleton class"
             self.log_info_message(message,self.file_name)

      def unset_mask_str(self):
          """
          Function to unmask the string.
          """
    #      message = "Un-setting encrypted String flag and original string to None in Singleton class"
    #      self.log_info_message(message,self.file_name)
          self.oenv.encrypt_str__ = None
          self.oenv.original_str__ = None

      def prog_exit(self,message):
          """
          This function exit the program because of some error
          """
          sys.exit(127)

      def log_info_message(self,lmessage,fname):
          """
          Print the INFO message in the logger
          """
          funcname = sys._getframe(1).f_code.co_name
          message = '''{:^15}-{:^20}:{}'''.format(fname,funcname,lmessage)
          self.ologger.msg_ = message
          self.ologger.logtype_ = "INFO"
          self.ohandler.handle(self.ologger)

      def log_error_message(self,lmessage,fname):
          """
          Print the Error message in the logger
          """
          funcname=sys._getframe(1).f_code.co_name
          message='''{:^15}-{:^20}:{}'''.format(fname,funcname,lmessage)
          self.ologger.msg_=message
          self.ologger.logtype_="ERROR"
          self.ohandler.handle(self.ologger)

      def log_warn_message(self,lmessage,fname):
          """
          Print the Error message in the logger
          """
          funcname=sys._getframe(1).f_code.co_name
          message='''{:^15}-{:^20}:{}'''.format(fname,funcname,lmessage)
          self.ologger.msg_=message
          self.ologger.logtype_="WARN"
          self.ohandler.handle(self.ologger)

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
                self.log_info_message("Sql command completed sucessfully.",self.file_name)

      def check_os_err(self,output,err,retcode,status):
          """
          Check if there are any error in OS command execution
          """
          msg1='''OS command returned code : {0} and returned output : {1}'''.format(str(retcode),str(output or "no Output"))
          msg2='''OS command returned code : {0}, returned error : {1} and returned output : {2}'''.format(str(retcode),str(err or  "no returned error"),str(output or "no retruned output"))
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
          msg='''Variable {0} is not defilned. Exiting!'''.format(key)
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
                msg='''Variable {0} value is not defilned to add in the env variables. Exiting!'''.format(value)
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
                msg='''Variable {0} value is not defilned to update in the env variables!'''.format(key)
                self.log_warn_message(msg,self.file_name)
          else:
             msg='''Variable {0} already exist in the env variables'''.format(key)
             self.log_info_message(msg,self.file_name)

          return env_dict

      def read_file(self,fname):
          """
            Read the contents of a file and returns the contents to end user
            Attributes:
               fname (string): file to be read

            Return:
               file data (string)
          """
          f1 = open(fname, 'r')
          fdata = f1.read()
          f1.close
          return fdata

      def write_file(self,fname,fdata):
          """
            write the contents to a file
            Attributes:
               fname (string): file to be written
               fdata (string): COnetents to be written

            Return:
               file data (string)
          """
          f1 = open(fname, 'w')
          f1.write(fdata)
          f1.close

      def create_dir(self,dir,local,remote,user):
          """
            Create dir locally or remotely
            Attributes:
               dir (string): dir to be created
               local (boolean): dir to craetes locally
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

          if remote and node:
             pass

      def create_file(self,file,local,remote,user):
          """
            Create dir locally or remotely
            Attributes:
               file (string): file to be created
               local (boolean): dir to craetes locally
               remote (boolean): dir to be created remotely
               node (string): remote node name on which dir to be created
               user (string): remote user to be connected
          """
          self.log_info_message("Inside create_file()",self.file_name)
          if local:
             if not os.path.isfile(file):
                 cmd='''touch  {0}'''.format(file)
                 output,error,retcode=self.execute_cmd(cmd,None,None)
                 self.check_os_err(output,error,retcode,True)

          if remote and node:
             pass

      def shutdown_db(self,env_dict):
           """
           Shutdown the database
           """
           self.log_info_message("Inside shutdown_db()",self.file_name)
           sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(env_dict["ORACLE_HOME"])
           sqlcmd='''
                  shutdown immediate;
           '''
           self.log_info_message("Running the sqlplus command to shutdown the database: " + sqlcmd,self.file_name)
           output,error,retcode=self.run_sqlplus(sqlpluslogincmd,sqlcmd,None)
           self.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
           self.check_sql_err(output,error,retcode,True)

      def mount_db(self,env_dict):
           """
           Mount the database
           """
           self.log_info_message("Inside mount_db()",self.file_name)
           sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(env_dict["ORACLE_HOME"])
           sqlcmd='''
                  startup mount;
           '''
           self.log_info_message("Running the sqlplus command to mount the database: " + sqlcmd,self.file_name)
           output,error,retcode=self.run_sqlplus(sqlpluslogincmd,sqlcmd,None)
           self.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
           self.check_sql_err(output,error,retcode,True)

      def start_db(self,env_dict):
           """
           startup the database
           """
           self.log_info_message("Inside start_db()",self.file_name)
           sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(env_dict["ORACLE_HOME"])
           sqlcmd='''
                  startup;
           '''
           self.log_info_message("Running the sqlplus command to start the database: " + sqlcmd,self.file_name)
           output,error,retcode=self.run_sqlplus(sqlpluslogincmd,sqlcmd,None)
           self.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
           self.check_sql_err(output,error,retcode,True)

      def nomount_db(self,env_dict):
           """
           No mount  the database
           """
           self.log_info_message("Inside start_db()",self.file_name)
           sqlpluslogincmd='''{0}/bin/sqlplus "/as sysdba"'''.format(env_dict["ORACLE_HOME"])
           sqlcmd='''
                 startup nomount;
           '''
           self.log_info_message("Running the sqlplus command to start the database: " + sqlcmd,self.file_name)
           output,error,retcode=self.run_sqlplus(sqlpluslogincmd,sqlcmd,None)
           self.log_info_message("Calling check_sql_err() to validate the sql command return status",self.file_name)
           self.check_sql_err(output,error,retcode,True)

      def stop_gsm(self,env_dict):
           """
           Stop the GSM
           """
           self.log_info_message("Inside stop_gsm()",self.file_name)
           gsmctl='''{0}/bin/gdsctl'''.format(env_dict["ORACLE_HOME"])
           gsmcmd='''
                  stop gsm;
           '''
           output,error,retcode=self.run_sqlplus(gsmctl,gsmcmd,None)
           self.log_info_message("Calling check_sql_err() to validate the gsm command return status",self.file_name)
           self.check_sql_err(output,error,retcode,None)

      def start_gsm(self,env_dict):
           """
           Start the GSM
           """
           self.log_info_message("Inside start_gsm()",self.file_name)
           gsmctl='''{0}/bin/gdsctl'''.format(env_dict["ORACLE_HOME"])
           gsmcmd='''
                  start gsm;
           '''
           output,error,retcode=self.run_sqlplus(gsmctl,gsmcmd,None)
           self.log_info_message("Calling check_sql_err() to validate the gsm command return status",self.file_name)
           self.check_sql_err(output,error,retcode,None)

      def exec_gsm_cmd(self,gsmcmd,flag,env_dict):
           """
           Get the GSM command output 
           """
           self.log_info_message("Inside exec_gsm_cmd()",self.file_name)
           gsmctl='''{0}/bin/gdsctl'''.format(env_dict["ORACLE_HOME"])
           if gsmcmd:
              output,error,retcode=self.run_sqlplus(gsmctl,gsmcmd,None)
              self.log_info_message("Calling check_sql_err() to validate the gsm command return status",self.file_name)
              self.check_sql_err(output,error,retcode,flag)
           else:
              self.log_info_message("GSM Command was set to empty. Executing nothing and setting output to None",self.file_name) 
              output=None

           return output,error,retcode         


      def check_substr_match(self,source_str,sub_str):
           """
            CHeck if substring exist 
           """
           self.log_info_message("Inside check_substr_match()",self.file_name)
           if (source_str.find(sub_str) != -1):
              return True
           else:
              return False

      def check_status_value(self,match):
           """
             return completed or notcompleted
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
