#!/usr/bin/python
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# Script to make simple EDQ 12.1.x install
# ----------------------------------------

# Attempt to find main domain.py in same directory as this file

import inspect

scriptdir = os.path.dirname(inspect.getfile(inspect.currentframe()))
domainpy  = os.path.join(scriptdir, "domain.py")

execfile("/u01/oracle/container-scripts/domain.py")

# Create domain, return location
#-------------------------------

def edqdomain(name,                     # Domain name
              wlshome,                  # WebLogic home
              dbhost,                   # DB host name
              dbport,                   # DB port
              dbservice,                # DB service
              dbprefix,                 # RCU prefix
              dbpw,                     # Password for STB schema
              weblogicpw,    # weblogic password: default weblog1c
              edqforfa=false,           # Use EDQ FA template
              addowsm=true,             # Use EDQ + OWSM template
              addem=true,               # Include EM template
              edqheap=2048,             # EDQ server heap size: default 2048
              edqprops=None,            # Additional runtime properties for EDQ managed servers
              adminport=7001,           # WebLogic admin port: default 7001
              listenaddress=None,       # Admin server listen address
              domainloc=None,           # Domain directory, defaults to wlshome/user_projects/domains/domain
              apploc=None,              # Applications directory, defaults to wlshome/user_projects/applications/domain
              edqport=8001,             # Port for first EDQ server: default 8001
              nmport=5556,              # Node manager port: default 5556
              debugport=0,              # Base port for debug
              servers=1,                # Number of EDQ servers required: default 1
              cluster=None,             # Cluster name: default edq_cluster if more than one server is created
              cloud=false,              # If true, select EDQ cloud template and do not select EM or OWSM
              idcsinfo=None,            # Map object containing IDCS configuration, required if cloud=true
              cohport=0,                # First coherence port: default edqport+100; ignored if no cluster
              wka=None,                 # Coherence well-known address list
              ldapinfo=None,            # LDAP configuration
              secure=None):             # Configure Java Security Manager (deprecared and ignored)

    # Verify LDAP setup

    if ldapinfo != None and not "name" in ldapinfo:
        print "name missing from ldap configuration"
        exit(exitcode = 1)
            
    # Secure flag now ignored

    if secure != None:
        print "###############################################################"
        print "| secure parameter function is deprecated and will be ignored |"
        print "###############################################################"
            
    # Sanity checks

    idcscert = None

    if cloud:
        if idcsinfo == None:
            print "cloud = true but idcsinfo not provided"
            exit(exitcode=1)

        if ldapinfo != None:
            print "ldapinfo not allowed with cloudy configuration"
            exit(exitcode=1)

        if idcsinfo != None:
            if not "cert" in idcsinfo or not "host" in idcsinfo or not "port" in idcsinfo or not "clienttenant" in idcsinfo or not "clientid" in idcsinfo or not "clientsecret" in idcsinfo:
                print "idcsinfo configuration is incomplete"
                exit(exitcode=1)

            if "cert" in idcsinfo:
                idcscert = idcsinfo["cert"]

    loc = makedomain(name, wlshome, dbhost, dbport, dbservice, dbprefix, dbpw, 
                     weblogicpw=weblogicpw, adminport=adminport, listenaddress=listenaddress,
                     domainloc=domainloc, apploc=apploc, edqforfa=edqforfa, addedq=true, addowsm=addowsm and not cloud, addem=addem and not cloud, cloud=cloud, 
                     idcscert=idcscert, nmport=nmport, edqport=edqport, secure=None)

    # Heap, debug and SSL option for cloudiness

    eprops = edqprops

    if cloud:
        if eprops == None:
            eprops = {}
        else:
            eprops = eprops.copy();

        eprops["weblogic.security.SSL.hostnameVerifier"] = "weblogic.security.utils.SSLWLSWildcardHostnameVerifier";

    # For < 12.2.1.3.0, fixup wsm-pm in managed server, also need to reset startup group

    if not v122130 and not cloud:
        if addowsm:
            setServerGroups("edq_server1", ["WSMPM-MAN-SVR"] + getServerGroups("edq_server1"))

        setStartupGroup("edq_server1", "EDQ-MGD-SVRS")

    # Create additional servers and cluster if required

    if servers > 1 or cluster != None:
        import socket

        hostname      = socket.gethostname()
        serveraddress = listenaddress

        if serveraddress == None:
            serveraddress = hostname

        if cluster == None:
            cluster = "edq_cluster"
        
        if cohport == 0:
            cohport = edqport + 100

        cl = createcluster(cluster, hostname, wka=wka)

        # Fixup initial server
       
        cd("/Servers/edq_server1")
        cmo.setCluster(cl)
        cmo.setListenAddress(serveraddress)
        servercoherence("edq_server1", cohport, "localhost")

        # Create additional servers - check for machine first

        cd('/')
        machname = None
        machines = get("Machines")

        if len(machines) == 1:
            machname = machines[0].getName()

        sgrps = getServerGroups("edq_server1")

        for snum in range(1, servers):
            srvr = createserver("edq_server" + str(snum+1), edqport + snum, servergroups=sgrps, startgroup='EDQ-MGD-SVRS', 
                                listenaddress=serveraddress, machine=machname, cluster=cluster, cohport=cohport + snum, cohhost="localhost")

    # Save 

    writeDomain(loc)
    closeTemplate()

    # Read and update to fix up startup settings

    readDomain(loc)

    # Apply server startup group modifications here once paths are correct

    modifystartupgroup('EDQ-MGD-SVRS', heap=edqheap, debugport=debugport, properties=eprops)
    updateDomain()
    closeDomain()

    # Server startup

    fixstart(loc, servers, weblogicpw)

# Server startup fix

def fixstart(loc, servers, weblogicpw):

    # Server startup

    for s in range(1, servers+1):
        dir = loc + "/servers/edq_server" + str(s) + "/security"

        # Directory may already exist

        try:
            os.makedirs(dir)
        except:
            pass

        fd = open(dir + "/boot.properties", "w")
        fd.writelines(["username = weblogic\n", "password = " + weblogicpw + "\n"])
        fd.close()
