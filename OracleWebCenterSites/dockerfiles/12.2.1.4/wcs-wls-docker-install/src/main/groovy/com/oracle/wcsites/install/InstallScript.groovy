/**
 * Copyright (c) 2019, 2020 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.wcsites.install

import groovy.transform.Field;

@Field def config = null

println "Install Automation -> Starting automation script"

// Check if the folder containing property files has been passed as an argument
// if not, use current working directory to locate property files
def resourcesFolder = ""
if(args.length == 0)
	resourcesFolder = System.getProperty("user.dir")
else
	resourcesFolder = args[0] // TODO: Use named arguments so that order becomes irrelevant

config = Utils.loadConfiguration(resourcesFolder)
Utils.validateInputs(config)

def appServer = getAppServer(config)

// Determines what operations to run
def cmd = config.script.command.trim()

// Performs silent installation
if(isOperationRequested(Utils.CMD_INSTALL, cmd))
	appServer.install()

// Summary message
if(isOperationRequested(Utils.CMD_INSTALL, cmd)) {
	Utils.echo("Oracle WebCenter Sites Installation complete. You can connect to the WebCenter Sites instance at ${config.oracle.wcsites.connect.string}")
}
else
	Utils.echo("Completed executing command(s): " + cmd)

/**
 * Factory method to return Application Server specific class
 */
def AppServer getAppServer(def config) {
	
	def appServerType = config.script.oracle.wcsites.appserver.type.trim()
	
	if(appServerType == null)
		return null;
	else if(appServerType.equalsIgnoreCase(Utils.WEBLOGIC))
		return new Weblogic(config)
   
   return null;
}

/**
 * Determines if the specified command includes running this operation 
 * Always returns true if specified command is 'all'
 * 
 * @param op the operation that we need to determine if it should be run
 * @param specifiedCmd the specified command
 * @return true if the operation should be run, false otherwise
 */
private def isOperationRequested(def op, def specifiedCmd) {
	def performOp = false
	
	if(specifiedCmd.equals(Utils.CMD_ALL))
		performOp = true
	else {
		specifiedCmd.split(",").each { aCommand ->
			if(aCommand.equals(op))
				performOp = true
			else if(aCommand.equals(Utils.CMD_INSTALL) )
				performOp = true
		}
	}
	performOp
}
