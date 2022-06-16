#!/bin/python3
## Copyright (c) 2021, Oracle and/or its affiliates.

##
##  d e p l o y m e n t - i n i t . p y
##  Initialize OGG Deployment
##

import os
import sys
import json
import subprocess
import time
import urllib.request
import requests
import psutil


default_ggschema     = 'ggadmin'
listen_on            = 'OGG_LISTEN_ON' in os.environ and os.environ['OGG_LISTEN_ON'] or '0.0.0.0'
service_address      = '127.0.0.1'
service_ports        = {
    'ServiceManager':  9011,
    'adminsrvr':       9012,
    'distsrvr':        9013,
    'recvsrvr':        9014,
    'pmsrvr':          9015
}
requests_session     = None
rest_call_headers    = {
    'ContentType':    'application/json',
    'Accept':         'application/json'
}


def get_deployment_directory(directories):
    """Returns an os.path object for either the main OGG Deployment or the ServiceManager deployment"""
    return os.path.join(os.environ['OGG_DEPLOYMENT_HOME'], *directories)


def get_admin_credentials():
    """Returns the administrator username and password for the OGG administrator"""
    return os.environ['OGG_ADMIN'], os.environ['OGG_ADMIN_PWD']


def wait_for_service(port):
    """Return once an SCA service is running, waiting up to two minutes"""
    url = 'http://' + service_address + ':' + str(port) + '/services/v2'
    for sequence in range(24):
        try:
            urllib.request.urlopen(url).read()
            return True
        except urllib.error.URLError:
            time.sleep(5)
    return False


def find_process(processName):
    """Locate a process running locally"""
    for process in psutil.process_iter(['name']):
        if process.info['name'] == processName:
            return process
    return None


def terminate_process(processName):
    """Terminate a process running locally"""
    process = find_process(processName)
    if process:
        process.terminate()
        for attempt in range(0, 10):
            time.sleep(1)
            if find_process(processName) == None:
                return
        process.kill()


def get_requests_session():
    """Create a session that retries REST API calls that fail"""
    global requests_session
    if not requests_session:
        retry_strategy = requests.packages.urllib3.util.retry.Retry(
            total=5,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            method_whitelist=["GET", "PUT", "DELETE", "POST", "PATCH"]
        )
        adapter = requests.adapters.HTTPAdapter(max_retries=retry_strategy)
        requests_session = requests.Session()
        requests_session.mount("https://", adapter)
        requests_session.mount("http://",  adapter)
    return requests_session


def get_network_config(serviceListeningPort):
    if (listen_on == '0.0.0.0'):
        networkConfig = {
            'serviceListeningPort': serviceListeningPort
        }
    else:
        networkConfig = {
            'serviceListeningPort': {
                'address': listen_on,
                'port':    serviceListeningPort
            },
            'ipACL': [
                {
                    'address':     listen_on,
                    'permission': 'allow'
                }
            ]
        }

    return networkConfig


def reset_servicemanager_configuration():
    """Reset the network configuration for the Service Manager to listen on and accept connections from the service host address only"""
    configFileName = os.path.join(get_deployment_directory(['ServiceManager', 'var', 'lib', 'conf']), 'ServiceManager-config.dat')
    with open(configFileName, 'r') as config:
        configData = json.load(config)

    if configData:
        configData['config']['network'] = get_network_config(service_ports['ServiceManager'])
        configContent = json.dumps(configData, sort_keys=True, indent=4)
        config = os.open(configFileName, os.O_WRONLY|os.O_TRUNC, 0o660)
        os.write(config, configContent.encode('utf-8'))
        os.close(config)


def get_digest_authentication():
    """Retrieve an authentication method for making a request"""
    userName, credential = get_admin_credentials()
    return requests.auth.HTTPDigestAuth(userName, credential)


def get_service_config(serviceName):
    """Retrieve the configuration of a service from Service Manager"""
    url = 'http://' + service_address + ':' + str(service_ports['ServiceManager']) + '/services/v2/deployments/' + os.environ['OGG_DEPLOYMENT'] + '/services/' + serviceName
    response = get_requests_session().get(url, headers=rest_call_headers, auth=get_digest_authentication())
    if response.status_code == 200:
        response_json = response.json()
        if 'response' in response_json and \
           'config' in response_json['response']:
            return response_json['response']['config']
    return None


def set_service_config(serviceName, config):
    """Sets the configuration of a service in Service Manager and restart the service"""
    url = 'http://' + service_address + ':' + str(service_ports['ServiceManager']) + '/services/v2/deployments/' + os.environ['OGG_DEPLOYMENT'] + '/services/' + serviceName
    body = {
        'config': config,
        'status': 'restart'
    }
    response = get_requests_session().patch(url, headers=rest_call_headers, auth=get_digest_authentication(), json=body)
    if response.status_code == 200:
        response_json = response.json()
        if 'response' in response_json:
            return response_json['response']
    return None


def reset_service_configuration(serviceName):
    """Reset the network configuration for a service to listen on and accept connections from the service host address only"""
    config = get_service_config(serviceName)
    config['network'] = get_network_config(service_ports[serviceName])
    set_service_config(serviceName, config)


def option(name, value = None):
    """Compose a command line option"""
    result = ' --' + name
    if value:
        result += '=' + str(value)
    return result


def establish_service_manager(hasServiceManager):
    """Ensure a Service Manager deployment exists"""
    deployment_directory = get_deployment_directory(['ServiceManager'])
    deployment_env = os.environ.copy()
    deployment_env['OGG_ETC_HOME'] = get_deployment_directory(['ServiceManager', 'etc'])
    deployment_env['OGG_VAR_HOME'] = get_deployment_directory(['ServiceManager', 'var'])
    if not hasServiceManager:
        for name in ['OGG_ETC_HOME', 'OGG_VAR_HOME']:
            directory_name = deployment_env[name]
            if not os.path.exists(directory_name):
                os.makedirs(directory_name)
        userName, credential = get_admin_credentials()
        shell_command = 'echo \'' + credential + '\' | ' + \
            'java -classpath ' + deployment_env['OGG_HOME'] + '/lib/utl/install/oggsca.jar ogg/OGGDeployment' + \
            option('serviceListeningHost',       service_address) + \
            option('serviceListeningPort',       service_ports['ServiceManager']) + \
            option('createNewServiceManager',   'Yes') + \
            option('action',                    'Create') + \
            option('oggHome',                    deployment_env['OGG_HOME']) + \
            option('oggDeployHome',              deployment_directory) + \
            option('deploymentName',            'ServiceManager') + \
            option('authUser',                   userName) + \
            option('authModes',                 'Digest-SHA-256,Digest,Basic') + \
            option('silent') + \
            option('nonsecure')
        subprocess.call(shell_command, shell=True, env=deployment_env)
        terminate_process('ServiceManager')
        reset_servicemanager_configuration()

    return subprocess.call(os.path.join(deployment_env['OGG_HOME'], 'bin', 'ServiceManager'), env=deployment_env)


def create_sqlnet_ora(directoryName):
    """Generate the 'sqlnet.ora' file used to configure SQL*Net for all DBMS connections"""
    with open(os.path.join(directoryName, 'sqlnet.ora'), 'w') as sqlnet_ora:
        sqlnet_ora.write('SQLNET.EXPIRE_TIME = 1\n')


def create_ogg_deployment():
    """Create OGG deployment"""
    deployment_env = os.environ.copy()
    deployment_env['OGG_ETC_HOME'] = get_deployment_directory(['Deployment', 'etc'])
    deployment_env['OGG_VAR_HOME'] = get_deployment_directory(['Deployment', 'var'])
    userName, credential = get_admin_credentials()
    shell_command = 'echo \'' + credential + '\' | ' + \
        'java -classpath ' + deployment_env['OGG_HOME'] + '/lib/utl/install/oggsca.jar ogg/OGGDeployment' + \
        option('serviceListeningHost',       service_address) + \
        option('serviceListeningPort',       service_ports['ServiceManager']) + \
        option('createNewServiceManager',   'No') + \
        option('action',                    'Create') + \
        option('oggHome',                    deployment_env['OGG_HOME']) + \
        option('oggEtcHome',                 deployment_env['OGG_ETC_HOME']) + \
        option('oggVarHome',                 deployment_env['OGG_VAR_HOME']) + \
        option('envTnsAdmin',                deployment_env['OGG_ETC_HOME']) + \
        option('ggSchema',                   default_ggschema) + \
        option('deploymentName',             os.environ['OGG_DEPLOYMENT']) + \
        option('authUser',                   userName) + \
        option('enablePmSrvr',              'Yes') + \
        option('criticalPmSrvr',            'Yes') + \
        option('pmSrvrDataStoreType',       'LMDB') +f \
        option('portAdminSrvr',              service_ports['adminsrvr']) + \
        option('portDistSrvr',               service_ports['distsrvr' ]) + \
        option('portRcvrSrvr',               service_ports['recvsrvr' ]) + \
        option('portPmSrvr',                 service_ports['pmsrvr'   ]) + \
        option('portPmSrvrUdp',              service_ports['pmsrvr'   ]) + \
        option('authModes',                 'Digest-SHA-256,Digest,Basic') + \
        option('silent') + \
        option('nonsecure')
    subprocess.call(shell_command, shell=True, env=deployment_env)

    for serviceName in ('adminsrvr', 'distsrvr', 'recvsrvr', 'pmsrvr'):
        wait_for_service(service_ports[serviceName])
        reset_service_configuration(serviceName)


def main():
    """Application entry point"""
    hasServiceManager = os.path.isdir(get_deployment_directory(['ServiceManager']))
    hasDeployment = os.path.isdir(get_deployment_directory(['Deployment', 'etc']))
    establish_service_manager(hasServiceManager)
    if not hasDeployment:
        create_ogg_deployment()
    create_sqlnet_ora(get_deployment_directory(['Deployment', 'etc']))
    return 0


sys.exit(main())
