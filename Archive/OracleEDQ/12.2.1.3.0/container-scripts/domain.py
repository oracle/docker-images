#!/usr/bin/python
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Create domain, return location
# ==============================

def makedomain(name,                        # Domain name
               wlshome,                     # WebLogic install location
               dbhost,                      # Database host name
               dbport,                      # Database Port
               dbservice,                   # Database service name
               dbprefix,                    # RCU prefix
               dbpw,                        # Database password
               weblogicpw,       # weblogic password
               adminport=7001,              # Admin server port
               domainloc=None,              # Domain directory, defaults to wlshome/user_projects/domains/domain
               apploc=None,                 # Applications directory, defaults to wlshome/user_projects/applications/domain
               addedq=true,                 # Add EDQ template
               edqforfa=false,              # Use EDQ for FA template 
               addowsm=false,                # Add OWSM
               addem=false,                  # Add EM
               addedqem=false,              # Add EDQ EM plugin(!)
               addums=false,                # Add UMS
               addjrf=false,                # Add JRF if not already selected implicitly
               cloud=false,                 # Use JRF cloud template (implies addjrf)
               idcscert=None,               # Absolute path to IDCS server certificate (requited if cloud = true)
               umsport=None,                # Port for UMS managed server
               listenaddress=None,          # Admin server listen address
               edqport=8001,                # Port for EDQ managed server
               nmport=5556,                 # Node manager port
               secure=None,                 # If true, configure Java Security Manager, if false disable security manager
               policyfile=None              # Java security policy file location, defaults to version in EDQ
               ):

    # If UMS is added, a specific port must be specified

    if addums:
        if umsport == None:
            print "UMS port not specified"
            exit(exitcode=1)
    
    if domainloc == None:
        loc = wlshome + "/user_projects/domains/" + name;
    else:
        loc = os.path.join(domainloc, name);

    # Sanity check

    if cloud:
        if addem or addums or addowsm:
            print "EM and OWSM cannot be used with cloudy JRF"
            exit(exitcode=1)

        if not v122:
            print "Cloudy JRF not supported before 12.2.x.y.z"
            exit(exitcode=1)

        addjrf = true

        # Find jcs.json in same directory

        import inspect

        thisdir  = os.path.dirname(inspect.getfile(inspect.currentframe()))
        jcsjson  = os.path.join(scriptdir, "jcs.json")

        if not os.path.isfile(jcsjson):
            jcsjson = "/opt/shared/tools/wls/12/jcs.json"

        System.setProperty("oracle.jps.cie.extended.json", jcsjson)

    # New template APIs

    if v122:
        selectTemplate('Basic WebLogic Server Domain')

        if addowsm and (not addedq or not v122130):
            selectTemplate('Oracle WSM Policy Manager')

        if addem:
            selectTemplate('Oracle Enterprise Manager')

        if addums:
            selectTemplate('Oracle User Messaging Service Basic')

        if addedqem:
           selectTemplate('Oracle Enterprise Manager Plugin for EDQ')

        # EDQ also if required

        if addedq:
            if edqforfa:
                selectTemplate('Oracle Enterprise Data Quality for Fusion Applications')
            elif cloud:
                selectTemplate('Oracle Enterprise Data Quality Cloud')
            elif addowsm and v122130:
                selectTemplate('Oracle Enterprise Data Quality with OWSM')
            else:
                selectTemplate('Oracle Enterprise Data Quality')

        # JRF if not already seleted

        if addjrf and not (addedq or addums or addowsm or addem):
            if cloud:
                selectTemplate('Oracle JRF Cloud')
                selectTemplate("Oracle EDQ Cloud Artifacts")
            else:
                selectTemplate('Oracle JRF')

        loadTemplates()

    else:
        em   = latest(wlshome, "em/common/templates/wls/oracle.em_wls_template_12.1.3.jar")
        owsm = latest(wlshome, "oracle_common/common/templates/wls/oracle.wsmpm_template_12.1.3.jar")
        ums  = latest(wlshome, "oracle_common/common/templates/wls/oracle.ums.basic_template_12.1.3.jar")
        edq  = latest(wlshome, "edq/common/templates/wls/oracle.edq_template_12.1.3.jar")
        jrf  = latest(wlshome, "oracle_common/common/templates/wls/oracle.jrf_template_12.1.3.jar")

        readTemplate(wlshome + '/wlserver/common/templates/wls/wls.jar')

    # Initial setup
    
    cd('/Security/base_domain/User/weblogic')
    cmo.setPassword(weblogicpw);

    cd('/Servers/AdminServer')
    cmo.setWeblogicPluginEnabled(true)
    cmo.setIgnoreSessionsDuringShutdown(true)

    if listenaddress != None:
        cmo.setListenAddress(listenaddress)

    if adminport != 7001:
        cmo.setListenPort(int(adminport))

    cd("/")

    # Not sure if we ever need this

    if v122:
        setOption("OverwriteDomain", "true")

    # Applications location, domain name is appended

    if apploc != None:
        setOption("AppDir", os.path.join(apploc, name))

    # Before 12.2 need to add templates by file name

    if not v122:

        if addowsm:
            addTemplate(owsm)

        if addem:
            addTemplate(em)

        if addums:
            addTemplate(ums)

        # EDQ also if required

        if addedq:
            addTemplate(edq)

        # JRF is not already seleted

        if addjrf and not (addedq or addums or addowsm or addem):
            addTemplate(jrf)

    # Setup STB data source

    if dbhost.find(":") < 0:
        dbhost = dbhost + ":" + dbport

    cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
    cd('JDBCDriverParams/NO_NAME_0')
    set('DriverName','oracle.jdbc.OracleDriver')
    set('URL','jdbc:oracle:thin:@' + dbhost + '/' + dbservice)
    set('PasswordEncrypted', dbpw)
    cd('Properties/NO_NAME_0')
    cd('Property/user')
    cmo.setValue(dbprefix.upper() + "_STB")

    # This command gets the schema user information from the ShadowTable and sets the schema user information to the respective datasources including ServiceTable.

    getDatabaseDefaults()
    cd('/')

    # Adjust ports for EDQ if necessary

    if addedq:

        if edqport != 8001:
            cd("/Servers/edq_server1")
            cmo.setListenPort(int(edqport))

        # 12.2.1 does not create a machine by default

        if v122:
            createmachine("localhost", port=nmport)
            setmachine("edq_server1", "localhost")
        else:
            if nmport != 5556:
                cd("/Machines/LocalMachine/NodeManager/LocalMachine")
                cmo.setListenPort(nmport)

        cd('/')

    # IDCS trust

    if cloud:
        if idcscert != None:
            cd("/Keystore/TargetStore/system/TargetKey/trust/TrustCertificate/idcs_server_cert")
            set("Location", idcscert)

        # Set wildcard host verifier property for admin server

        cd("/StartupGroupConfig/AdminServerStartupGroup")
        adminxp = cmo.getSystemProperties()
        adminxp["weblogic.security.SSL.hostnameVerifier"] = "weblogic.security.utils.SSLWLSWildcardHostnameVerifier" 
        cmo.setSystemProperties(adminxp)
        
    # Set port for UMS

    if addums:

        cd("/Servers/ums_server1")
        cmo.setListenPort(umsport)
        cd('/')

    return loc;

# Find latest template version
#
# Update as new versions become available!

def latest(wls, template):
    versions = ["12.1.4"]

    for v in versions:
        temp = wls + "/" + template.replace("12.1.3", v)

        if os.path.exists(temp):
            return temp
    
    # Nothing found: old default

    return wls + "/" + template

def deployedq(path, target):
    return deployear("edq", path, target)

def deployear(name, path, target):
    cd("/")
    create(name, "AppDeployment")
    cd("/AppDeployments/" + name)
    cmo.setSourcePath(path)
    cmo.setModuleType("ear")
    cmo.setStagingMode("nostage")
    cmo.setSecurityDDModel("DDOnly")

    if type(target) is list:
        cmo.setTargets(target)
    else:
        cmo.setTargets([target])

    result = cmo;
    cd("/")

    return result

# Create data source
#
# If host is list. create AGL source

def createds(name, dbhost, dbport, service, username, pw, target, max=200, jndiname=None):
    cd('/')
    agl = type(dbhost) is list

    # Construct URL appropriately

    if agl:
        url = "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(LOAD_BALANCE=on)"
        for h in dbhost:
            port = dbport
            px = h.find(":")

            if px > 0:
                port = h[px+1:]
                h    = h[0:px]

            url = url + "(ADDRESS=(PROTOCOL=TCP)(HOST=" + h + ")(PORT=" + port + "))"

        url = url + ")(CONNECT_DATA=(SERVICE_NAME=" + service + ")))"

    else:
        # Add default host if required

        if dbhost.find(":") < 0:
            dbhost = dbhost + ":" + dbport

        url = "jdbc:oracle:thin:@" + dbhost + "/" + service

    # Create bean and subbeans

    create(name, 'JDBCSystemResource')
    cd('/JDBCSystemResource/' + name);

    result = cmo;

    if type(target) is list:
        cmo.setTargets(target)
    else:
        cmo.setTargets([target])

    cd('JdbcResource/' + name)

    if agl:
        cmo.setDatasourceType("AGL")

    create(name, 'JDBCConnectionPoolParams')
    create(name, 'JDBCDataSourceParams')
    create(name, 'JDBCDriverParams')

    if agl:
        create(name, "JDBCOracleParams")

    # Connection pool setup

    cd('JDBCConnectionPoolParams/NO_NAME_0')
    cmo.setMaxCapacity(max)
    cmo.setTestTableName('SQL ISVALID') 
    cmo.setTestConnectionsOnReserve(true)
    cmo.setStatementCacheSize(0)

    # Data source information

    cd('../../JDBCDataSourceParams/NO_NAME_0')

    if jndiname == None:
        cmo.setJNDINames(['jdbc/' + name])
    else:
        cmo.setJNDINames([jndiname])

    cmo.setGlobalTransactionsProtocol('None')

    # Gridlink stuff

    if agl:
        cd('../../JDBCOracleParams/NO_NAME_0')
        cmo.setActiveGridlink(true)
        cmo.setFanEnabled(true)

    # Driver information

    cd('../../JDBCDriverParams/NO_NAME_0')
    cmo.setDriverName("oracle.jdbc.OracleDriver")
    cmo.setUrl(url)
    cmo.setPasswordEncrypted(pw)

    # Create properties object and set the username property

    create(name, 'Properties')
    cd('Properties/NO_NAME_0')
    create('user', 'Property')
    cd('Property/user')
    cmo.setValue(username)
    cd('/')

    return result;

def createmailsession(name, properties, target=None, username=None, password=None, jndiname=None):

    cd('/')

    # Create bean and subbeans

    create(name, 'MailSession')
    cd('/MailSession/' + name);

    result = cmo;

    if jndiname == None:
        cmo.setJNDIName('mail/' + name)
    else:
        cmo.setJNDIName(jndiname)

    # Convert to correct properties type

    props = Properties()

    for x in properties:
        props[x] = properties[x]

    cmo.setProperties(props)

    # Authentication

    if username != None and password != None:
        cmo.setSessionUsername(username)
        cmo.setSessionPasswordEncrypted(password)

    # Targets

    if target != None:
        if type(target) is list:
            cmo.setTargets(target)
        else:
            cmo.setTargets([target])

    cd('/')
    return result;

def createcluster(name, address, domaindir=None, cohport=0, wka=None):
    cd('/')
    create(name, 'Cluster')

    cd('Clusters/' + name)
    cluster = cmo
    cmo.setClusterMessagingMode('unicast')
    cmo.setClusterAddress(address)

    # Retarget coherence

    cd('/Servers/AdminServer')
    cmo.setCoherenceClusterSystemResource(None)

    cd('/CoherenceClusterSystemResources/defaultCoherenceCluster')
    cmo.setTargets([cluster])

    cd('/CoherenceClusterSystemResources/defaultCoherenceCluster/CoherenceResource/defaultCoherenceCluster/CoherenceClusterParams/NO_NAME_0')

    if cohport != 0:
        cmo.setClusterListenPort(cohport)

    if wka != None:
        create('wka_config', 'CoherenceClusterWellKnownAddresses')
        cd('CoherenceClusterWellKnownAddresses/NO_NAME_0')

        port = None

        for w in wka:
            if type(w) is str:
                name = w
                addr = w
            else:
                name = w["name"];
                addr = w["addr"];

                if "port" in w:
                    port = w["port"];

            create(name, 'CoherenceClusterWellKnownAddress')
            cd("CoherenceClusterWellKnownAddress/" + name)

            cmo.setListenAddress(addr)
            
            if port != None:
                cmo.setListenPort(port)

            cd("../..")

    cd('/')
    return cluster

# Create managed server
# =====================
#
# Note: startgroup name always required now

def createserver(name, port, listenaddress=None, machine=None, cluster=None, cohport=0, cohhost=None, servergroups=None, startgroup=None, withedq=false, withowsm=false):
    cd('/')
    create(name, "Server")

    if cluster != None:
        cd('/Clusters/' + cluster)
        clusbean = cmo

    if machine != None:
        cd("/Machines/" + machine)
        machbean = cmo

    cd('/Servers/' + name)

    result = cmo

    if listenaddress != None:
        cmo.setListenAddress(listenaddress)
    else:
        if cohhost != None:
            cmo.setListenAddress(cohhost)
        else:
            cmo.setListenAddress('')

    cmo.setListenPort(port)
    cmo.setIgnoreSessionsDuringShutdown(true)
    cmo.setWeblogicPluginEnabled(true)
    cmo.setStagingMode("nostage")

    # Cluster and Coherence configuration

    if cluster != None:
        cmo.setCluster(clusbean)
        servercoherence(name, cohport, cohhost)

    cd('/Servers/' + name)

    if machine != None:
        cmo.setMachine(machbean)

    # Server groups: can be specified externally or defaulted here

    sgrps = servergroups

    if sgrps == None:

        # EDQ references OWSM in 12.2.1.3.0+

        if withedq:
            if v122130:
                sgrps = ["EDQ-MGD-SVRS"]
            else:
                sgrps = ["EDQ-MGD-SVRS", "WSMPM-MAN-SVR"]

        elif withowsm:

            # OWSM template in 12.1.3 does not include JRF apps

            if v122:
                sgrps = ["WSMPM-MAN-SVR"]
            else:
                sgrps = ["WSMPM-MAN-SVR", "JRF-MAN-SVR"]
        else:
            sgrps = ["JRF-MAN-SVR"]

    setServerGroups(name, sgrps)

    # Startup

    setStartupGroup(name, startgroup)
    return result

# Set Coherence port and address on managed server
# ================================================

def servercoherence(name, cohport=0, cohhost=None):

    if cohport != 0:
        cd('/Servers/' + name)
        create(name, "CoherenceMemberConfig")
        cd('CoherenceMemberConfig/' + name)

        cmo.setUnicastListenPort(cohport)

        if cohhost != None:
            cmo.setUnicastListenAddress(cohhost)

    cd('/')

# Create machine
# ==============

def createmachine(name, address='localhost', port=5556):
    cd('/')

    create(name, 'Machine')
    cd('Machines/' + name)
    result = cmo

    create(name, 'NodeManager')
    cd('NodeManager/' + name)

    cmo.setListenAddress(address)
    cmo.setListenPort(port)
    cd('/')

    return result

# Set machine on server
# =====================

def setmachine(server, machine):
    cd("/Machines/" + machine)
    machbean = cmo

    cd("/Servers/" + server)
    cmo.setMachine(machbean)    
    cd("/")

# Create startup group
# ====================

def createstartupgroup(name, base, heap=0, debugport=0, properties=None, environ=None, javaopts=None):
    cd('/')
    addStartupGroup(name, base)
    return modifystartupgroup(name, heap=heap, debugport=debugport, properties=properties, environ=environ, javaopts=javaopts)

# Modify startup group
# ====================

def modifystartupgroup(name, heap=0, debugport=0, properties=None, environ=None, javaopts=None):

    cd('/StartupGroupConfig')
    cd(name)
    result = cmo
    
    if heap != 0:
        set('MaxHeapSize', str(heap))
        
        # Safety check in case heap is being reduced

        if heap < int(get("InitialHeapSize")):
            set("InitialHeapSize", str(heap))

    env     = get("EnvVars")
    setenv = false

    if debugport != 0:
        addjavaopts(env, "-agentlib:jdwp=transport=dt_socket,address=" + str(debugport) + ",server=y,suspend=n")
        setenv = true

    if javaopts != None:
        addjavaopts(env, javaopts)
        setenv = true

    if environ != None:
        for x in environ:
            env[x] = environ[x]
        setenv = true

    if setenv:
        set("EnvVars", fixconfig(env))

    if properties != None:
        props = get('SystemProperties')

        for x in properties:
            props[x] = properties[x]
        
        set("SystemProperties", props)

    cd('/')
    return result

def addjavaopts(env, opts):
    if "JAVA_OPTIONS" in env:
        opts = env["JAVA_OPTIONS"] + " " + opts

    if not "%JAVA_OPTIONS%" in opts:
        opts = "%JAVA_OPTIONS%" + " " + opts

    env["JAVA_OPTIONS"] = opts

# Add shared library
# ==================

def addlibrary(path,  target):
    cd("/")

    # Read manifest to get stuff

    jar  = java.util.jar.JarFile(path)
    attrs = jar.getManifest().getMainAttributes()
    jar.close()

    name  = attrs.getValue("Extension-Name")
    spec  = attrs.getValue("Specification-Version")
    impl  = attrs.getValue("Implementation-Version")

    if impl == None:
        impl = spec

    version = spec + "@" + impl
    vname   = name + "#" + version

    create(vname, "Library")
    
    cd("/Library/" + vname)
    result = cmo

    cmo.setModuleType(path[-3:])
    cmo.setSourcePath(os.path.abspath(path))
    cmo.setStagingMode("nostage")

    if type(target) is list:
        cmo.setTargets(target)
    else:
        cmo.setTargets([target])
    
    cd('/')
    return result

# Add security manager options to domain
# ======================================

def enablesecurity(policyfile, wlshome=None, domainloc=None):

    # Write policy file if it does not exist already

    if not os.path.exists(policyfile):
        print "Creating " + policyfile

        fd = open(policyfile, "w")
        fd.writelines(["grant {\n", "  permission java.security.AllPermission;\n", "};\n"])
        fd.close()

    # Update startup groups which define EDQ_CONFIG_PATH

    servers = get("Servers")
    changes = false

    for x in servers:
        grp = getStartupGroup(x.getName())
        cd("StartupGroupConfig")
        cd(grp)

        env = cmo.getEnvVars()

        if "EDQ_CONFIG_PATH" in env:

            # Set WLS_POLICY_FILE if not present or does not match the policy file

            polfile = ""

            if "WLS_POLICY_FILE" in env:
                polfile = env["WLS_POLICY_FILE"]

            if polfile != "=" + policyfile:
                env["WLS_POLICY_FILE"] = "=" + policyfile
                cmo.set("EnvVars", fixconfig(env))
                changes = true

            props = cmo.getSystemProperties()

            if not "java.security.manager" in props:
                props["java.security.manager"] = ""
                cmo.setSystemProperties(props)
                changes = true

        cd("/")

    return changes

# Remove security manager options from domain
# ============================================

def disablesecurity():
    # Not sure how to do this yet
    return false

# Fix up loss of separators in EDQ_CONFIG_PATH (Unix only)

def fixconfig(env):

    if "EDQ_CONFIG_PATH" in env:
        e = env["EDQ_CONFIG_PATH"]

        if not ":" in e:

            # No longer support use during domain creation so ensure no variables with @

            if '@' in e:
                print "Strartup group fix config called during domain creation.  This is no longer supported"
                exit(exitcode = 1)

            arr   = e.split("/")
            npath = ""
            file  = ""

            # Iterate backwards looking for paths which exist

            for i in range(len(arr)-1, -1, -1):
                if len(arr[i]) > 0:                  
                  file = "/" + arr[i] + file;

                  if os.path.exists("/" + arr[i]):
                      if len(npath) == 0:
                          npath = file
                      else:
                          npath = file + ":" + npath

                      file = ""

            env["EDQ_CONFIG_PATH"] = npath

            # Delete incorrect PATH setting

            del env["PATH"]
    return env


# Stop admin server and node manager
# ==================================

def stopadmin():

    disconnect()
    nmKill('AdminServer')
    stopNodeManager()

# Simple interface to configureldap
# =================================

def setldap(ldapinfo):

    if "type" in ldapinfo:
        type = ldapinfo["type"]
    else:
        type = None

    if "gate" in ldapinfo:
        gate = ldapinfo["gate"]
    else:
        gate = None

    if "ssl" in ldapinfo:
        ssl = ldapinfo["ssl"]
    else:
        ssl = false

    configureldap(ldapinfo["name"], type = type, gate = gate, ssl = ssl)

# Create LDAP authenticator + optional OAM, move to top
# =====================================================

def configureldap(name, type = None, gate = None, ssl = false):

    # Type defaults to name in lower case

    if type == None:
        type = name

    type = type.lower()

    if type == 'titania':
        titania(name, ssl = ssl)
    elif type == 'oberon':
        oberon(name, ssl = ssl)
    elif type == 'ariel':
        ariel(name, ssl = ssl)
    elif type == 'sycorax':
        sycorax(name, ssl = ssl)
    else:
        print "Unknown LDAP type " + type
        exit(exitcode = 1)

    # Reorder to get new one on top

    cd('/')
    base  = '/SecurityConfiguration/' + cmo.getName() + '/Realms/myrealm'
    realm = cmo.getSecurityConfiguration().getDefaultRealm()

    provs = realm.getAuthenticationProviders()
    provs.insert(0, provs.pop(len(provs)-1))
    realm.setAuthenticationProviders(provs)

    # Update control flag of default authenticator

    cd(base + '/AuthenticationProviders/DefaultAuthenticator')
    cmo.setControlFlag('SUFFICIENT')
    cd('/')

    # Set up OAM also if required

    if gate != None:

        # titania. ariel and sycorax have default gates

        if gate == 'default':
            if type == 'titania':
                gate = 'edq'
            elif type == 'ariel':
                gate = 'edqslapd'
            elif type == 'sycorax':
                gate = 'edqad'
            else:
                print "No default webgate for LDAP type " + type
                exit(exitcode = 1)

        cd(base)
        create('OAM', 'oracle.security.wls.oam.providers.asserter.OAMIdentityAsserter', 'AuthenticationProvider')

        cd('AuthenticationProviders/OAM')
        cmo.setControlFlag('REQUIRED')
        cmo.setAccessGateName(gate)
        cmo.setPrimaryAccessServer('hostname:port')

        # Reorder to have OAM at top

        cd("/")
        provs = realm.getAuthenticationProviders()
        provs.insert(0, provs.pop(len(provs)-1))
        realm.setAuthenticationProviders(provs)
    
# Configure LDAP for titania.com
# ------------------------------

def titania(name = 'titania', ssl = false):
    cd('/')
    base = '/SecurityConfiguration/' + cmo.getName() + '/Realms/myrealm'

    cd(base)
    create(name, 'weblogic.security.providers.authentication.OracleInternetDirectoryAuthenticator', 'AuthenticationProvider')

    cd('AuthenticationProviders/' + name)
    cmo.setControlFlag('SUFFICIENT')
    cmo.setPrincipal('cn=netuser,cn=users,dc=titania,dc=com')
    cmo.setHost('hostname')
    cmo.setCredentialEncrypted('test1')
    cmo.setUserBaseDN('dc=titania,dc=com')
    cmo.setGroupBaseDN('dc=titania,dc=com')

    if ssl:
        cmo.setPort(3131)
        cmo.setSLEnabled(true)
    else:
        cmo.setPort(3060)

    cd('/')

# Configure LDAP for oberon.com
# -----------------------------

def oberon(name = 'oberon', ssl = false):
    cd('/')
    base = '/SecurityConfiguration/' + cmo.getName() + '/Realms/myrealm'

    cd(base)
    create(name, 'weblogic.security.providers.authentication.OracleInternetDirectoryAuthenticator', 'AuthenticationProvider')

    cd('AuthenticationProviders/' + name)
    cmo.setControlFlag('SUFFICIENT')
    cmo.setPrincipal('cn=netuser,cn=users,dc=oberon,dc=com')
    cmo.setHost('hostname')
    cmo.setCredentialEncrypted('test1')
    cmo.setUserBaseDN('dc=oberon,dc=com')
    cmo.setGroupBaseDN('dc=oberon,dc=com')

    if ssl:
        cmo.setPort(3131)
        cmo.setSLEnabled(true)
    else:
        cmo.setPort(3060)

    cd('/')

# Configure LDAP for ariel.com
# ----------------------------

def ariel(name = 'ariel', ssl = false):
    cd('/')
    base = '/SecurityConfiguration/' + cmo.getName() + '/Realms/myrealm'

    cd(base)
    create(name, 'weblogic.security.providers.authentication.OpenLDAPAuthenticator', 'AuthenticationProvider')

    cd('AuthenticationProviders/' + name)
    cmo.setControlFlag('SUFFICIENT')
    cmo.setPrincipal('cn=netuser,ou=people,dc=ariel,dc=com')
    cmo.setHost('hostname')
    cmo.setCredentialEncrypted('test')
    cmo.setUserBaseDN('dc=ariel,dc=com')
    cmo.setGroupBaseDN('dc=ariel,dc=com')

    if ssl:
        cmo.setPort(636)
        cmo.setSLEnabled(true)
    else:
        cmo.setPort(389)

    cd('/')

# Configure LDAP for sycorax.com
# ------------------------------

def sycorax(name = 'sycorax', ssl = false):
    cd('/')
    base = '/SecurityConfiguration/' + cmo.getName() + '/Realms/myrealm'

    cd(base)
    create(name, 'weblogic.security.providers.authentication.ActiveDirectoryAuthenticator', 'AuthenticationProvider')

    cd('AuthenticationProviders/' + name)
    cmo.setControlFlag('SUFFICIENT')
    cmo.setPrincipal('netuser@domain.com')
    cmo.setHost('hostname')
    cmo.setCredentialEncrypted('test')
    cmo.setUserBaseDN('dc=sycorax,dc=com')
    cmo.setUserNameAttribute("sAMAccountName")
    cmo.setUserFromNameFilter("(&(sAMAccountName=%u)(objectclass=user))")
    cmo.setGroupBaseDN('dc=sycorax,dc=com')

    if ssl:
        cmo.setPort(636)
        cmo.setSLEnabled(true)
    else:
        cmo.setPort(389)

    cd('/')

# Short cut to set LDAP pool size
# -------------------------------

def setldappoolsize(name, poolsize, activate = false):
    modifyLDAPAdapter(adapterName=name, attribute="MaxPoolSize", value=poolsize)

    # If restarting, no need to activate

    if activate:
        activateLibOVDConfigChanges()

# Create AQ JMS resources
# -----------------------

def createaq(target):
    cd('/')
    create("EDQFusionJMS", "JMSSystemResource")

    cd("JMSSystemResource/EDQFusionJMS")

    if type(target) is list:
        cmo.setTargets(target)
    else:
        cmo.setTargets([target])

    cd("JmsResource/NO_NAME_0")
    create("EDQFusionJMS", "ForeignServer")

    cd("ForeignServer/EDQFusionJMS")
    cmo.setInitialContextFactory("oracle.jms.AQjmsInitialContextFactory")
    cmo.setDefaultTargetingEnabled(true)

    create("datasource", "JNDIProperty")
    cd("JNDIProperty/NO_NAME_0")

    cmo.setKey("datasource")
    cmo.setValue("jdbc/edqstaging")
    cd('../..')

    create("EDQFusionConnectionFactory", "ForeignConnectionFactory")
    cd("ForeignConnectionFactory/EDQFusionConnectionFactory")
    cmo.setLocalJNDIName("jms/EDQFusionConnectionFactory")
    cmo.setRemoteJNDIName("ConnectionFactory")
    cd('../..')

    createaqdest("EDQFusionQueue", "Queues/EDQ_QUEUE")
    createaqdest("EDQFusionTopic", "Topics/EDQ_TOPIC")
    cd('/')

def createaqdest(name, remote):
    cd("/JMSSystemResource/EDQFusionJMS/JmsResource/NO_NAME_0/ForeignServers/EDQFusionJMS")

    create(name, "ForeignDestination")
    cd("ForeignDestination/" + name) 
    cmo.setLocalJNDIName("jms/" + name)
    cmo.setRemoteJNDIName(remote)
    cd('/')

# EDQ logging cusomization
# ------------------------

def edqlogging(server, domainloc=None):
    setlogging(server, "edq", domainloc)

def setlogging(server, app, domainloc=None):
    logger  = "oracle." + app
    handler = app + "-console-handler"

    setLogLevel(target=server, logger=logger, addLogger=1, level="NOTIFICATION:1", runtime=0)

    # EDQ console logger - needs formatter set

    configureLogHandler(target=server, 
                    name=handler, 
                    addHandler=true,
                    handlerType="oracle.core.ojdl.logging.ConsoleHandler", 
                    level="NOTIFICATION:1", 
                    addToLogger=logger, useParentHandlers=false)

    configureLogHandler(target=server, name="odl-handler", addToLogger=logger, useParentHandlers=false)
    configureLogHandler(target=server, name="wls-domain", addToLogger=logger, useParentHandlers=false)

    # Update edq-console-handler with formatter 

    if domainloc != None:
        logfile = domainloc + "/config/fmwconfig/servers/" + server + "/logging.xml"

        try:
            file  = open(logfile)
            lines = file.readlines()

            for idx in range(0, len(lines)):
                if lines[idx].find("<log_handler name='" + handler + "'") >= 0:
                    lines[idx] = lines[idx].replace("/>", " formatter='oracle.core.ojdl.weblogic.ConsoleFormatter'/>")

            file.close()

            file = open(logfile, "w")
            file.writelines(lines)
            file.close()
        except IOError, exc:
            print "Error updating logging.xml: " + str(exc)

# Create credential entry

def createcredential(map, key, user, password, desc=None):
    try:
        deleteCred(map, key)
    except:
        pass

    createCred(map, key, user, password, desc)

# Poor man's version of currentTree()
#
# Assumes pwd() returns /domain/location

def currentloc():
    p = pwd()
    x = p.find('/', 1)

    if x < 0:
        return '/'
    else:
        return p[x:]

# Get a target object

def gettarget(name):
    curr = currentloc()

    if name.find('/') > 0:
        name = '/' + name

    cd(name)
    target = cmo
    cd(curr)
    return target

# Permission granting utilities
#
# Note: file: is added to codebase here

def grantcredentialpermission(codebase, map, key="*", actions="read"):
    grantPermission(codeBaseURL="file:" + codebase,
                    permClass="oracle.security.jps.service.credstore.CredentialAccessPermission", 
                    permTarget="context=SYSTEM,mapName=" + map + ",keyName=" + key, 
                    permActions=actions)

def grantkeystorepermission(codebase, stripe="edq", keystore="*", alias="*", actions="*"):
    grantPermission(codeBaseURL="file:" + codebase,
                    permClass="oracle.security.jps.service.keystore.KeyStoreAccessPermission", 
                    permTarget="stripeName=" + stripe + ",keystoreName=" + keystore + ",alias=" + alias,
                    permActions=actions)

def grantauditpermission(codebase, component="edq", actions="read,write"):
    grantPermission(codeBaseURL="file:" + codebase,
                    permClass="oracle.security.jps.service.audit.AuditStoreAccessPermission",
                    permTarget=component,
                    permActions=actions)

# Export kfile to JCEKS key store

def exportkfile(path, password="password"):
    svc = getOpssService("KeyStoreService") 
    svc.exportKeyStore("edq", "default", password, aliases="kfile", keypasswords=password, type="JCEKS", filepath=path) 

# Import kfile from JCEKS key store

def importkfile(path, password="password"):
    svc = getOpssService("KeyStoreService") 
    svc.importKeyStore("edq", "default", password, aliases="kfile", keypasswords=password, type="JCEKS", permission=true, filepath=path)

# Setup IDCS integration
# ----------------------
#
# Must be called online with edit active
#
# host            Host name (without tenant prefix)
# port            Port number
# ssl             SSL flag
# clienttenant    Tenant name
# clientid        Client ID
# clientsecret    Client secret
#
# All parameters are required

def idcs(host, port, ssl, clienttenant, clientid, clientsecret):
    
    realm = cmo.getSecurityConfiguration().getDefaultRealm()
    atn   = realm.createAuthenticationProvider('IDCSIntegrator','weblogic.security.providers.authentication.OracleIdentityCloudIntegrator')

    # Setup the IDCS provider configuration

    atn.setHost(host)
    atn.setPort(port)

    if ssl:
        atn.setSSLEnabled(true)

    atn.setTenant(clienttenant)
    atn.setClientTenant(clienttenant)
    atn.setClientId(clientid)
    atn.setClientSecret(clientsecret)
    atn.setControlFlag('SUFFICIENT')

    # Ensure default authenticator has SUFFICIENT flag

    defauth = realm.lookupAuthenticationProvider('DefaultAuthenticator')

    if defauth != None:
        defauth.setControlFlag('SUFFICIENT')

    # Reorder to get new one on top

    provs = realm.getAuthenticationProviders()
    provs.insert(0, provs.pop(len(provs)-1))
    realm.setAuthenticationProviders(provs)

# Write boot.properties for a set of servers
# ==========================================

def fixboot(domainloc, prefix, num, weblogicpw):
    base = domainloc + "/servers/" + prefix

    for s in range(1, num+1):
        dir = base + str(s) + "/security"
        os.makedirs(dir)

        fd = open(dir + "/boot.properties", "w")
        fd.writelines(["username = weblogic\n", "password = " + weblogicpw + "\n"])
        fd.close()

# Version number functions
# ========================

# Is current version earlier than v

def before(v):
    
    import re
    return compver(re.search("[0-9.]+", version).group(), v) < 0
    
# Compare versions as strings
#
# Pad shorter with '0'; elements so that 12.1.3 matches 12.1.3.0.0 for example

def compver(v1, v2):
    s1 = v1.split(".")
    s2 = v2.split(".")
    l1 = len(s1)
    l2 = len(s2)

    for i in range(0, max(l1, l2)):

        if i >= l1:
            n1 = 0
        else:
            n1 = int(s1[i])

        if i >= l2:
            n2 = 0
        else:
            n2 = int(s2[i])

        if n1 < n2:
            return -1
        elif n1 > n2:
            return +1

    return 0

# ======================
# Global version flags |
# ======================

v122    = not before("12.2.1.0.0")
v122130 = not before("12.2.1.3.0")

