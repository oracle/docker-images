#!/usr/bin/python
#!/usr/bin/env python

###########################################################################################################


# stig.py
#
# Copyright (c) 1982-2021, Oracle and/or its affiliates. All rights reserved.
#
# NAME
#      buildImage.py - <Build the Image>
#
# DESCRIPTION
#      <This  script will build the Image>
#
# NOTES


# Global Variables
Period                  = '.'


# Import standard python libraries
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


etchostfile="/etc/hosts"
racenvfile="/etc/rac_env_vars"
domain="none"

def Usage():
    pass

def Update_Envfile(common_params):
    global racenvfile
    global domain
    filedata1 = None
    f1 = open(racenvfile, 'r')
    filedata1 = f1.read()
    f1.close

    for keys in common_params.keys():
        if keys == 'domain':
           domain = common_params[keys]

        env_var_str = "export " + keys.upper() + "=" + common_params[keys]
        Redirect_To_File("Env vars for RAC Env set to " + env_var_str, "INFO")
        filedata1 = filedata1 + "\n" + env_var_str

    Write_To_File(filedata1,racenvfile)
    return "Env file updated sucesfully"


def Update_Hostfile(node_list):
    counter=0
    global etchostfile
    global domain
    filedata = None
    filedata1 = None
    f = open(etchostfile, 'r')
    filedata = f.read()
    f.close

    global racenvfile
    filedata1 = None
    f1 = open(racenvfile, 'r')
    filedata1 = f1.read()
    f1.close
    host_name=socket.gethostname()

    if domain == 'none':
       fqdn_hostname=socket.getfqdn()
       domain=fqdn_hostname.split(".")[1]
    if not host_name:
       Redirect_To_File("Unable to get the container host name! Exiting..", "INFO")
    else:
       Redirect_To_File("Container Hostname and Domain name : " + host_name + " " + domain, "INFO")

# Replace and add the target string
    for dict_list in node_list:
        print dict_list
        if "public_hostname" in dict_list.keys():
           pubhost = dict_list['public_hostname']
           if host_name == pubhost:
               Redirect_To_File("PUBLIC Hostname set to" + pubhost, "INFO")
               PUBLIC_HOSTNAME=pubhost
           if counter == 0:
              CRS_NODES = pubhost
              CRS_CONFIG_NODES = pubhost
              counter = counter + 1
           else:
              CRS_NODES = CRS_NODES + "," + pubhost
              CRS_CONFIG_NODES = CRS_CONFIG_NODES  + "," + pubhost
              counter = counter + 1
        else:
            return "Error: Did not find the key public_hostname"
        if "public_ip" in dict_list.keys():
           pubip = dict_list['public_ip']
           if host_name == pubhost:
              Redirect_To_File("PUBLIC IP set to" + pubip, "INFO")
              PUBLIC_IP=pubip
        else:
           return "Error: Did not find the key public_ip"
        if "private_ip" in dict_list.keys():
           privip = dict_list['private_ip']
           if host_name == pubhost:
              Redirect_To_File("Private IP set to" + privip, "INFO")
              PRIV_IP=privip
        else:
           return "Error: Did not find the key private_ip"
        if "private_hostname" in dict_list.keys():
           privhost = dict_list['private_hostname']
           if host_name == pubhost:
              Redirect_To_File("Private HOSTNAME set to" + privhost, "INFO")
              PRIV_HOSTNAME=privhost
        else:
           return "Error: Did not find the key private_hostname"
        if "vip_hostname" in dict_list.keys():
           viphost = dict_list['vip_hostname']
           CRS_CONFIG_NODES = CRS_CONFIG_NODES + ":" + viphost + ":" + "HUB"
           if host_name == pubhost:
              Redirect_To_File("VIP HOSTNAME set to" + viphost, "INFO")
              VIP_HOSTNAME=viphost
        else:
            return "Error: Did not find the key vip_hostname"
        if "vip_ip" in dict_list.keys():
           vipip = dict_list['vip_ip']
           if host_name == pubhost:
             Redirect_To_File("NODE VIP  set to" + vipip, "INFO")
             NODE_VIP=vipip
        else:
           return "Error: Did not find the key vip_ip"

        delete_entry = [pubhost, privhost, viphost, pubip, privip, vipip]
        for hostentry in delete_entry:
            print "Processing " + hostentry
            cmd=cmd= '""' + "sed  "  + "'" + "/" + hostentry + "/d" + "'" + " <<<" + '"' + filedata + '"' + '""'
            output,retcode=Execute_Single_Command(cmd,'None','')
            filedata=output
            print "New Contents of Host file " + filedata

            # Removing Empty Lines
            cmd=cmd= '""' + "sed  "  + "'" + "/^$/d"  + "'" + " <<<" + '"' + filedata + '"' + '""'
            output,retcode=Execute_Single_Command(cmd,'None','')
            filedata=output
            print "New Contents of Host file " + filedata

        delete_entry [:]

        if pubhost not in filedata:
            if pubip not in filedata:
               hoststring='%s    %s    %s' %(pubip, pubhost + "." + domain, pubhost)
               Redirect_To_File(hoststring, "INFO")
               filedata = filedata + '\n' + hoststring

        if privhost not in filedata:
            if privip not in filedata:
               hoststring='%s    %s    %s' %(privip, privhost + "." + domain, privhost)
               Redirect_To_File(hoststring, "INFO")
               filedata = filedata + '\n' + hoststring

        if viphost not in filedata:
            if vipip not in filedata:
               hoststring='%s    %s    %s' %(vipip, viphost + "." + domain, viphost)
               Redirect_To_File(hoststring, "INFO")
               filedata = filedata + '\n' + hoststring
               print filedata

    Write_To_File(filedata,etchostfile)
    if CRS_NODES:
       Redirect_To_File("Cluster Nodes set to " + CRS_NODES, "INFO")
       filedata1 = filedata1 + '\n' + 'export CRS_NODES=' +  CRS_NODES
    if CRS_CONFIG_NODES:
       Redirect_To_File("CRS CONFIG Variable set to " + CRS_CONFIG_NODES, "INFO")
       filedata1 = filedata1 + '\n' + 'export CRS_CONFIG_NODES=' +  CRS_CONFIG_NODES
    if NODE_VIP:
       filedata1 = filedata1 + '\n' + 'export NODE_VIP=' + NODE_VIP
    if PRIV_IP:
       filedata1 = filedata1 + '\n' + 'export PRIV_IP=' + PRIV_IP
    if PUBLIC_HOSTNAME:
       filedata1 = filedata1 + '\n' + 'export PUBLIC_HOSTNAME=' + PUBLIC_HOSTNAME
    if PUBLIC_IP:
       filedata1 = filedata1 + '\n' + 'export PUBLIC_IP=' + PUBLIC_IP
    if VIP_HOSTNAME:
       filedata1 = filedata1 + '\n' + 'export VIP_HOSTNAME=' + VIP_HOSTNAME
    if PRIV_HOSTNAME:
       filedata1 = filedata1 + '\n' + 'export PRIV_HOSTNAME=' + PRIV_HOSTNAME

    Write_To_File(filedata1,racenvfile)
    return "Host and Env file updated sucesfully"


def Write_To_File(text,filename):
    f = open(filename,'w')
    f.write(text)
    f.close()

def Setup_Operation(op_type):
    if op_type == 'installrac':
       cmd="sudo /opt/scripts/startup/runOracle.sh"

    if op_type == 'addnode':
       cmd="sudo /opt/scripts/startup/runOracle.sh"

    if op_type == 'delnode':
       cmd="sudo /opt/scripts/startup/DelNode.sh"

    output,retcode=Execute_Single_Command(cmd,'None','')
    if retcode != 0:
       return "Error occuurred in setting up env"
    else:
       return "setup operation completed sucessfully!"


def Execute_Single_Command(cmd,env,dir):
    try:
       if not dir:
          dir=os.getcwd()
       print shlex.split(cmd)
       out = subprocess.Popen(cmd, shell=True, cwd=dir, stdout=subprocess.PIPE)
       output, retcode = out.communicate()[0],out.returncode
       return output,retcode
    except:
       Redirect_To_File("Error Occurred in Execute_Single_Command block! Please Check", "ERROR")
       sys.exit(2)

def Redirect_To_File(text,level):
    original = sys.stdout
    sys.stdout = open('/proc/1/fd/1', 'w')
    root = logging.getLogger()
    if not root.handlers:
       root.setLevel(logging.INFO)
       ch = logging.StreamHandler(sys.stdout)
       ch.setLevel(logging.INFO)
       formatter = logging.Formatter('%(asctime)s :%(message)s', "%Y-%m-%d %T %Z")
       ch.setFormatter(formatter)
       root.addHandler(ch)
    message = os.path.basename(__file__) + " : " + text
    root.info(' %s ' % message )
    sys.stdout = original


#BEGIN : TO check whether valid arguments are passed for the container ceation or not
def main(argv):
    version= ''
    type= ''
    dir=''
    script=''
    Redirect_To_File("Passed Parameters " + str(sys.argv[1:]), "INFO")
    try:
      opts, args = getopt.getopt(sys.argv[1:], '', ['setuptype=','nodeparams=','comparams=','help'])

    except getopt.GetoptError:
       Usage()
       sys.exit(2)
    #Redirect_To_File("Option Arguments are :  " + opts , "INFO")
    for opt, arg in opts:
       if opt in ('--help'):
          Usage()
          sys.exit(2)
       elif opt in ('--nodeparams'):
          nodeparams = arg
       elif opt in ('--comparams'):
          comparams = arg
       elif opt in ('--setuptype'):
          setuptype = arg
       else:
          Usage()
          sys.exit(2)

    if setuptype == 'installrac':
        Redirect_To_File("setup type parameter is set to installrac", "INFO")
    elif setuptype == 'addnode':
        Redirect_To_File("setup type parameter is set to addnode", "INFO")
    elif setuptype == 'delnode':
        Redirect_To_File("setup type parameter is set to delnode", "INFO")
    else:
         setupUsage()
         sys.exit(2)
    if not nodeparams:
       Redirect_To_File("Node Parameters for the Cluster not specified", "Error")
       sys.exit(2)
    if not comparams:
       Redirect_To_File("Common Parameter for the Cluster not specified", "Error")
       sys.exit(2)


    Redirect_To_File("NodeParams set to" + nodeparams , "INFO" )
    Redirect_To_File("Comparams set to" + comparams , "INFO" )


    comparams = comparams.replace('\\"','"')
    Redirect_To_File("Comparams set to" + comparams , "INFO" )
    envfile_status=Update_Envfile(json.loads(comparams))
    if 'Error' in envfile_status:
        Redirect_To_File(envfile_status, "ERROR")
        return sys.exit(2)

    nodeparams = nodeparams.replace('\\"','"')
    Redirect_To_File("NodeParams set to" + nodeparams , "INFO" )
    hostfile_status=Update_Hostfile(json.loads(nodeparams))
    if 'Error' in hostfile_status:
        Redirect_To_File(hostfile_status, "ERROR")
        return sys.exit(2)

    Redirect_To_File("Executing operation" + setuptype, "INFO")
    setup_op=Setup_Operation(setuptype)
    if 'Error' in setup_op:
        Redirect_To_File(setup_op, "ERROR")
        return sys.exit(2)

    sys.exit(0)

if __name__ == '__main__':
     main(sys.argv)
