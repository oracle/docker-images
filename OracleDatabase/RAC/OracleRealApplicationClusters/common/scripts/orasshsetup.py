#!/usr/bin/python3

#############################
# Copyright 2021, Oracle Corporation and/or affiliates.  All rights reserved.
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
from orasetupenv import *
from orasshsetup import *
from oracvu import *

import os
import sys

class OraSetupSSH:
    """
    This class setup the env before setting up the rac env
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
        This function setup ssh between computes
        """
        self.ocommon.log_info_message("Start setup()",self.file_name)
        ct = datetime.datetime.now()
        bts = ct.timestamp()
        if self.ocommon.check_key("SKIP_SSH_SETUP",self.ora_env_dict):
            self.ocommon.log_info_message("Skipping SSH setup as SKIP_SSH_SETUP flag is set",self.file_name)
        else:
          SSH_USERS=[self.ora_env_dict["GRID_USER"] + ":" + self.ora_env_dict["GRID_HOME"],self.ora_env_dict["DB_USER"] + ":" + self.ora_env_dict["DB_HOME"]]
          if (self.ocommon.check_key("SSH_PRIVATE_KEY",self.ora_env_dict)) and (self.ocommon.check_key("SSH_PUBLIC_KEY",self.ora_env_dict)):
            if self.ocommon.check_file(self.ora_env_dict["SSH_PRIVATE_KEY"],True,None,None) and self.ocommon.check_file(self.ora_env_dict["SSH_PUBLIC_KEY"],True,None,None):
              for sshi in SSH_USERS:
                uohome=sshi.split(":")          
                self.setupsshusekey(uohome[0],uohome[1],None)
                self.verifyssh(uohome[0],None)
          else:
            for sshi in SSH_USERS:
               uohome=sshi.split(":")
               exiting_cls_node=self.ocommon.get_existing_clu_nodes(False)
               if exiting_cls_node:
                  self.setupssh(uohome[0],uohome[1],"ADDNODE")
               else:
                  self.setupssh(uohome[0],uohome[1],"INSTALL")

               self.verifyssh(uohome[0],None)

        ct = datetime.datetime.now()
        ets = ct.timestamp()
        totaltime=ets - bts
        self.ocommon.log_info_message("Total time for setup() = [ " + str(round(totaltime,3)) + " ] seconds",self.file_name)

    def setupssh(self,user,ohome,ctype):
        """
        This function setup the ssh between user as SKIP_SSH_SETUP flag is not set
        """
        self.ocommon.reset_os_password(user)
        password=self.ocommon.get_os_password()
        expect=self.ora_env_dict["EXPECT"] if self.ocommon.check_key("EXPECT",self.ora_env_dict) else "/bin/expect"
        script_dir=self.ora_env_dict["SSHSCR_DIR"] if self.ocommon.check_key("SSHSCR_DIR",self.ora_env_dict) else "/opt/scripts/startup/scripts"
        sshscr=self.ora_env_dict["SSHSCR"] if self.ocommon.check_key("SSHSCR",self.ora_env_dict) else "setupSSH.expect"
        cluster_nodes=""
        if ctype == 'INSTALL':
          cluster_nodes=self.ocommon.get_cluster_nodes()
          self.ocommon.set_mask_str(password)
          cmd='''su - {0} -c "{1} {2}/{3} {0} \"{4}/oui/prov/resources/scripts\"  '{5}' '{6}'"'''.format(user,expect,script_dir,sshscr,ohome,cluster_nodes,'HIDDEN_STRING')
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,True)
          self.ocommon.unset_mask_str()
        elif ctype == 'ADDNODE':
             x = datetime.datetime.now()
             tmpdir=self.ora_env_dict["TMPDIR"] if self.ocommon.check_key("TMPDIR",self.ora_env_dict) else "/var/tmp"
             expfile='''{1}/expfile_{0}'''.format(x.strftime("%f"),tmpdir)
             expdata='''#!/usr/bin/expect
             set cmd [lrange $argv 1 end]
             set password [lindex $argv 0]
             eval spawn "$cmd"
             expect "*?assword:*"
             send "$password\\r";
             expect eof'''
            
             self.ocommon.write_file(expfile,expdata.strip())
 
             new_nodes=self.ocommon.get_cluster_nodes()
             exiting_cls_node=self.ocommon.get_existing_clu_nodes(True).replace(","," ")
             node=exiting_cls_node.split(" ")[0] 
             password=self.ocommon.get_os_password().strip("\n")
             ### Adding known Hosts
             cmd='''su - {0} -c "mkdir -p ~/.ssh; touch ~/.ssh/known_hosts;chmod 700 ~/.ssh;ssh-keygen -R {1};ssh-keyscan -H {1}  >> ~/.ssh/known_hosts"'''.format(user,node)
             output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
             self.ocommon.check_os_err(output,error,retcode,True)
 
             cluster_nodes= exiting_cls_node + " " +  new_nodes
             cmd=''' #!/bin/bash
             ssh -o StrictHostKeyChecking=no {0}@{7} /bin/sh -c \\"{1} {2}/{3} {0} '\\"{4}/oui/prov/resources/scripts\\"' '\\"{5}\\"' '\\"{6}\\"'\\"'''.format(user,expect,script_dir,sshscr,ohome,cluster_nodes,password,node,expfile)
             cmdfile='''{1}/cmdfile_{0}.sh'''.format(x.strftime("%f"),tmpdir)
             self.ocommon.write_file(cmdfile,cmd.strip())
             ### CHanging file permission
             cmd='''chmod 775 {0}'''.format(cmdfile)
             output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
             self.ocommon.check_os_err(output,error,retcode,True)
            
             ## Execuing expect file 
             self.ocommon.set_mask_str(password)
             ## cmd='''su - {0} -c "{1} {8} '{6}' 'ssh -o StrictHostKeyChecking=no {0}@{7} /bin/sh -c \\"{1} {2}/{3} {0} '\\"{4}/oui/prov/resources/scripts\\"'  '\\"{5}\\"' '\\"{6}\\"'\\"\\"'"'''.format(user,expect,script_dir,sshscr,ohome,cluster_nodes,'HIDDEN_STRING',node,expfile,cmdfile)
             cmd='''su - {0} -c "{1} {8} '{6}' '{9}'"'''.format(user,expect,script_dir,sshscr,ohome,cluster_nodes,'HIDDEN_STRING',node,expfile,cmdfile)
             output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
             self.ocommon.check_os_err(output,error,retcode,True)
             self.ocommon.unset_mask_str()

             ###### Delete the files
            # cmd='''rm -f {0};rm -f {1}'''.format(expfile,cmdfile)
            # output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
            # self.ocommon.check_os_err(output,error,retcode,True)             
 
        else:
             cluster_nodes=self.ocommon.get_cluster_nodes()     
  
    def verifyssh(self,user,ctype):
           """
           This function setup the ssh between user as SKIP_SSH_SETUP flag is not set
           """
           timeout=300
           verifyFlag=False
           timeout_start=time.time()
           count=0
           while time.time() < timeout_start + timeout:
              count=count +1 
              cluster_nodes=""
              if ctype == 'INSTALL':
                cluster_nodes=self.ocommon.get_cluster_nodes()
              elif ctype == 'ADDNODE':
                new_nodes=self.ocommon.get_cluster_nodes()
                exiting_cls_node=self.ocommon.get_existing_clu_nodes(True).replace(","," ")
                cluster_nodes= exiting_cls_node + " " +  new_nodes
              else:
                cluster_nodes=self.ocommon.get_cluster_nodes()
                            
              for node in cluster_nodes.split(" "):
                  cmd='''su - {0} -c "ssh -o BatchMode=yes -o ConnectTimeout=5 {0}@{1} echo ok 2>&1"'''.format(user,node)
                  output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                  self.ocommon.check_os_err(output,error,retcode,None)
                  if output.strip() == 'ok':
                      self.ocommon.log_info_message('''SSH setup passed for {0}@{1}'''.format(user,node),self.file_name)
                      verifyFlag=True                   
              if verifyFlag:
                 break
              else:
                 self.ocommon.log_info_message('''Trying count number {2} - ssh verification failed for {0}@{1}. Sleeping for 30 seconds and will try ssh again'''.format(user,node,count),self.file_name)
                 time.sleep(30)
            
           if not verifyFlag:
                self.ocommon.log_error_message('''SSH setup failed for {0}@{1}'''.format(user,node),self.file_name)
                self.ocommon.prog_exit("None")

    def setupsshusekey(self,user,ohome,ctype):
        """
        This function setup the ssh between user as SKIP_SSH_SETUP flag is not set
        This will be using existing key to setup the ssh
        """
        # Populate Known Host file
        i=1

        cluster_nodes=""
        new_nodes=self.ocommon.get_cluster_nodes()
        existing_cls_node=self.ocommon.get_existing_clu_nodes(None)
        # node=exiting_cls_node.split(" ")[0]
        if existing_cls_node is not None:
          cluster_nodes= existing_cls_node.replace(","," ") + " " +  new_nodes
        else:
          cluster_nodes=new_nodes

        for node1 in cluster_nodes.split(" "):
            for node in cluster_nodes.split(" "):
                i=1
                #cmd='''su - {0} -c "ssh-keyscan -H {1} >> /home/{0}/.ssh/known_hosts"'''.format(user,node,ohome)
                cmd='''su - {0} -c "ssh -o  StrictHostKeyChecking=no -x -l {0} {3} \\"ssh-keygen -R {1};ssh -o  StrictHostKeyChecking=no -x -l {0} {1} \\\"/bin/sh -c true\\\"\\""''' .format(user,node,ohome,node1)
                output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                self.ocommon.check_os_err(output,error,retcode,None)
                if int(retcode) != 0:
                   while (i < 5):
                     self.ocommon.log_info_message('''SSH setup failed for the cmd {0}. Trying again and count is {1}'''.format(cmd,i),self.file_name)
                     output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
                     self.ocommon.check_os_err(output,error,retcode,None)
                     if (retcode == 0):
                        break
                     else:
                        time.sleep(5)
                        i=i+1

    def setupsshdirs(self,user,ohome,ctype):
        """
        This function setup the ssh directories
        """
        sshdir='''/home/{0}/.ssh'''.format(user)
        privkey=self.ora_env_dict["SSH_PRIVATE_KEY"]
        pubkey=self.ora_env_dict["SSH_PUBLIC_KEY"]
        group="oinstall"
        cmd1='''mkdir -p {0}'''.format(sshdir)
        cmd2='''chmod 700 {0}'''.format(sshdir)
        cmd3='''cat {0} > {1}/id_rsa'''.format(privkey,sshdir)
        cmd4='''cat {0} > {1}/id_rsa.pub'''.format(pubkey,sshdir)
        cmd5='''chmod 400 {0}/id_rsa'''.format(sshdir)
        cmd6='''chmod 644 {0}/id_rsa.pub'''.format(sshdir)
        cmd7='''chown -R {0}:{1} {2}'''.format(user,group,sshdir)
        cmd8='''cat {0} > {1}/authorized_keys'''.format(pubkey,sshdir)
        cmd9='''chmod 600 {0}/authorized_keys'''.format(sshdir)
        cmd10='''chown -R {0}:{1} {2}/authorized_keys'''.format(user,group,sshdir)
        for cmd in cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7,cmd8,cmd9,cmd10:
          output,error,retcode=self.ocommon.execute_cmd(cmd,None,None)
          self.ocommon.check_os_err(output,error,retcode,False)
