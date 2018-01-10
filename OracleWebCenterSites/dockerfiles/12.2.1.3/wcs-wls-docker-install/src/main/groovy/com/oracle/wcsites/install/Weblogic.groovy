/**
 * Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
 * Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 */
package com.oracle.wcsites.install

import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths

import java.util.concurrent.TimeUnit

/**
 * This class performs the necessary operations to install WebCenter Sites on Weblogic
 *
 */
class Weblogic implements AppServer {
	protected def config
	protected def antBuilder

	public Weblogic(def configuration) {
		super()
		this.config = configuration
		this.antBuilder = new AntBuilder()
	}
	
	/**
	 * Completes silent installation and restarts the server
	 *
	 * @return
	 */
	def install() {

		def installFile = new File(config.work + "/WCSites_Install.suc")

		if(!installFile.exists()) {
			Utils.echo("1st phase: WebCenter Sites installation started...")

			unPack()

			installFile.createNewFile()

			Utils.echo("1st phase: WebCenter Sites installation completed")
		}else{
			Utils.echo("WebCenter Sites installation has already completed. Hence skipping.")
		}

		def domainHome = getDomainHome()

		if(Boolean.valueOf(config.script.run.rcu)) {

			def rcuFile = new File(config.work + "/WCSites_RCU_" + config.script.rcu.prefix + ".suc")

			if(!rcuFile.exists()) {
				Utils.echo("2nd phase: WebCenter Sites RCU configuration started...")

				createSchema()

				rcuFile.createNewFile()

				Utils.echo("2nd phase: WebCenter Sites RCU configuration completed successfully.")
			}else{
				Utils.echo("WebCenter Sites RCU configuration has already completed. Hence skipping RCU setup. Prefix: " + config.script.rcu.prefix)
			}
		}

		if(Boolean.valueOf(config.script.run.configwizard)) {

			def configWizardFile = new File(config.work + "/WCSites_Domain_" + config.script.oracle.domain + ".suc")

			if(!configWizardFile.exists()) {
				Utils.echo("3rd phase: WebCenter Sites Config Wizard has started.")

				runConfigWizard()

				configWizardFile.createNewFile()

				Utils.echo("3rd phase: WebCenter Sites Config Wizard configuration completed successfully.")
			}else{
				Utils.echo("WebCenter Sites Config Wizard configuration has already completed. Hence skipping Config Wizard configuration. Domain: " + config.script.oracle.domain)
			}
		}

		if(Boolean.valueOf(config.script.run.sitesconfig)) {

			def sitesConfigSetupFile = new File(config.work + "/WCSites_Config_Setup.suc")

			if(!sitesConfigSetupFile.exists()) {
				Utils.echo("4th phase: WebCenter Sites Config Setup has started.")
				// Changes multi-cast ports for eh-cache and jboss-ticket-cache xmls
				Utils.changeMulticastPorts(config)

				copyDomainFiles()

				// Starts Admin Server
				startAdminServer(domainHome)

				// Starts Managed Server
				startManagedServer(domainHome)

				// Silent installation
				// Pauses before starting the silent installation
				Thread.sleep(10000)
				// Starts installation
				runSilentInstall()
				// Monitors sites.log for installation success/failure
				monitorSitesLog(domainHome + "/servers/" + config.script.server.name + "/logs/sites.log")
				// Pauses after installation completes
				Thread.sleep(10000)

				if(config.script.env.equalsIgnoreCase(Utils.ENV_DOCKER)){
					// Stops Managed Server
					Utils.echo("Stopping Managed Server: " + config.script.server.name)
					stopManagedServer(domainHome, config.script.server.name, true)
					Utils.echo("Stopped Managed Server Successfully: " + config.script.server.name)

					// Stops Admin Server
					Utils.echo("Stopping Admin Server.")
					stopAdminServer(domainHome, false)
					Utils.echo("Stopped Admin Server Successfully.")

				}else{
					// Restarts the application server
					restartManagedServer(domainHome, true)
				}

				sitesConfigSetupFile.createNewFile()

				Utils.echo("4th phase: WebCenter Sites Config Setup is completed successfully.")
			}else{
				Utils.echo("WebCenter Sites Config Setup has already completed. Hence skipping Config Setup.")
			}
		}
	}

	/**
	 * To create the schema we need to run a command like:
	 *
	 * rcu -silent -createRepository -databaseType SQLSERVER -connectString localhost:1433:databasename -dbUser dbusername -schemaPrefix WCS -selectDependentsForComponents true -component WCSITES -useSamePasswordForAllSchemaUsers true -f < C:\rcu_passwords.txt
	 *
	 * @return
	 */
	def createSchema() {
		Utils.echo("Installation -> Repository Creation Utility - creates schema")

		// Updates the response file with user specified values
		updateRCUResponseFile()

		StringBuilder buffer = new StringBuilder("-silent -responseFile " + config.work + "/rcu.rsp")

		// RCU prompts for schema password and does not take a command line argument for it
		// To make the drop repository silent, use the redirector command to pass schema password.
		def dbPassword = config.script.db.password

		def dbSchemaPassword = config.script.db.schema.password

		if (dbSchemaPassword.length() <= 0) {
			Utils.echo("Setting schema password to database password, as script.db.schema.password is not being set.")
			dbSchemaPassword = dbPassword
		}

		Path pwdFilePath = Files.createTempFile(Paths.get("${config.work}"), "rcuPasswords", ".txt")
		BufferedWriter bw = Files.newBufferedWriter(pwdFilePath)
		bw.writeLine(dbPassword)
		bw.writeLine(dbSchemaPassword)
		bw.writeLine(dbSchemaPassword)
		bw.writeLine(dbSchemaPassword)
		bw.writeLine(dbSchemaPassword)
		bw.writeLine(dbSchemaPassword)
		bw.writeLine(dbSchemaPassword)
		bw.writeLine(dbSchemaPassword)
		bw.close()
		buffer.append(" -f < " + pwdFilePath.toAbsolutePath())
		
		// Redirects the console output to a static file
		def rcuLog = "${config.work}/rcu_output.log"
		File rcuLogFile = new File(rcuLog)
		rcuLogFile.text = "RCU Output" + System.lineSeparator()
		buffer.append(" >${rcuLog}")

		def	args = buffer.toString()
		def rcu = "${config.script.oracle.home}/oracle_common/bin/rcu"
		Utils.echo("Create schema using command: ${rcu} ${args}")
		Utils.echo("RCU Create Schema -> " + Utils.PLEASE_WAIT)
		
		// On UNIX platforms, running antBuilder.exec with the required arguments is not working
		// as a workaround, create a script with the command and run it.
		def rcuTempDir = config.work + "/rcu"
		def rcuCreateFile = new File(config.work + "/rcuCreate.sh")
		rcuCreateFile.withWriter('utf-8') { writer ->
			writer.writeLine "#!/bin/sh"
			writer.writeLine ""
			writer.writeLine "export RCU_LOG_LOCATION="+rcuTempDir
			writer.writeLine rcu + " " + args
		}

		antBuilder.chmod(file: config.work + "/rcuCreate.sh", perm: "755")
		antBuilder.exec(executable : "./rcuCreate.sh",  dir : config.work, failifexecutionfails : false)

		// Reads RCU console output to determine success or failure
		String fileContents = rcuLogFile.text
		Utils.echo("${fileContents}")
		if(fileContents.contains(Utils.RCU_CREATE_SUCCESS))
			Utils.echo("Successfully created schemas")
		else if(fileContents.contains(Utils.RCU_FAILURE)) {
			Utils.echo("Unable to create schema successfully")
			System.exit(1)
		}
		else
			Utils.echo("Unable to identify if the create schema method ran successfully. Assuming success.")
	}

	/**
	 * Updates response file
	 *
	 * @return
	 */
	private updateRCUResponseFile() {
		def connectString = config.script.db.dbConnectString
		def dbUser = "${config.script.db.user}"
		
		def dbType = ""
		def dbRole = "Normal"
		if(config.script.oracle.wcsites.database.type.equalsIgnoreCase(Utils.ORACLE)) {
			dbType = "ORACLE"
			if(dbUser.equalsIgnoreCase( "SYS" ))
				dbRole = "SYSDBA"
		}
		else {
			Utils.echo("Unable to determine the database type. Confirm script.oracle.wcsites.database.type property is set correctly in bootstrap.properties.")
			System.exit(1)
		}

		Utils.echo("connectString-----------------: " + connectString)

		antBuilder.replace(file: config.work + "/rcu.rsp", token: "%CONNECT.STRING%", value: connectString, summary: true)
		antBuilder.replace(file: config.work + "/rcu.rsp", token: "%DATABASE.TYPE%", value: dbType, summary: true)
		antBuilder.replace(file: config.work + "/rcu.rsp", token: "%DB.USER%", value: dbUser, summary: true)
		antBuilder.replace(file: config.work + "/rcu.rsp", token: "%DB.ROLE%", value: dbRole, summary: true)
		antBuilder.replace(file: config.work + "/rcu.rsp", token: "%SCHEMA.PREFIX%", value: config.script.rcu.prefix, summary: true)
	}

	/**
	 * Copies response files and cleans up the database if required
	 *
	 * @return
	 */
	def unPack() {

		copyFiles()

		if(Boolean.valueOf(config.script.weblogic.rcu.clean.after.install)) {
			Utils.echo("Installation -> Running the RCU clean command as requested")
			cleanDB(false)
		}
	}

	/**
	 * Copies response files
	 *
	 * @return
	 */
	private copyFiles() {
		// Copies RCU response file
		def fileString	= new File(config.resources + "/" + "rcu.rsp")
		antBuilder.copy(todir:config.work, overwrite:true, verbose: true) {
			fileset(file:"${fileString}")
		}
	}
						
	/**
	 * Copies files to domain
	 *
	 * @return
	 */
	private copyDomainFiles() {
		// Copies over wcs_properties_bootstrap.ini for WebCenter Sites silent installation
		def sampleRspFile = "${config.script.oracle.home}/wcsites/webcentersites/sites-home/template/config/"+Utils.WCSITES_SILENT_INSTALL_RSP_FILE
		Utils.copyWCSSilentInstallResponseFile(sampleRspFile, config)
	}


	/**
	 * Runs config wizard and creates the domain, servers and datasources
	 *
	 * @return
	 */
	private runConfigWizard() {
		Utils.echo("Installation -> Weblogic Configuration Wizard")

		// Copies the Jython file to the work directory
		antBuilder.copy(todir:config.work, overwrite:true) {
			fileset(file:"${config.resources}/config.py")
		}

		def dbUrl = config.script.db.url + config.script.db.dbConnectString
		def domainHome = "${config.script.oracle.home}/user_projects/domains/${config.script.oracle.domain}"

		Utils.echo("Weblogic:runConfigWizard:dbUrl-----------------: " + dbUrl)

		// Replaces tokens in the Jython file
		def jythonConfigFile = config.work + "/" + Utils.CONFIG_SCRIPT
		antBuilder.replace(file:jythonConfigFile, token:"<DOMAIN_HOME>", value:"${domainHome}")
		antBuilder.replace(file:jythonConfigFile, token:"<WL_USERNAME>", value:"${config.script.admin.server.username}")
		antBuilder.replace(file:jythonConfigFile, token:"<WL_PASSWORD>", value:"${config.script.admin.server.password}")
		antBuilder.replace(file:jythonConfigFile, token:"<SERVER_HOST>", value:"${config.script.oracle.wcsites.hostname}")
		antBuilder.replace(file:jythonConfigFile, token:"<ADMIN_SERVER_PORT>", value:"${config.script.admin.server.port}")
		antBuilder.replace(file:jythonConfigFile, token:"<ADMIN_SERVER_SSL_PORT>", value:"${config.script.admin.server.ssl.port}")
		antBuilder.replace(file:jythonConfigFile, token:"<SITES_SERVER_NAME>", value:"${config.script.server.name}")
		antBuilder.replace(file:jythonConfigFile, token:"<SITES_SERVER_PORT>", value:"${config.script.oracle.wcsites.portnumber}")
		antBuilder.replace(file:jythonConfigFile, token:"<SITES_SERVER_SSL_PORT>", value:"${config.script.sites.server.ssl.port}")
		antBuilder.replace(file:jythonConfigFile, token:"<SITES_DATASOURCE>", value:"${config.script.oracle.wcsites.database.datasource}")
		antBuilder.replace(file:jythonConfigFile, token:"<RCU_SCHEMA_PREFIX>", value:"${config.script.rcu.prefix}")
		String dbType = config.script.oracle.wcsites.database.type
		antBuilder.replace(file:jythonConfigFile, token:"<DATABASE>", value:dbType.toUpperCase())
		antBuilder.replace(file:jythonConfigFile, token:"<DB_URL>", value:"${dbUrl}")
		antBuilder.replace(file:jythonConfigFile, token:"<DB_HOST>", value:"${config.script.db.host}")
		antBuilder.replace(file:jythonConfigFile, token:"<DB_PORT>", value:"${config.script.db.port}")
		antBuilder.replace(file:jythonConfigFile, token:"<DB_SID>", value:"${config.script.db.instance}")
		antBuilder.replace(file:jythonConfigFile, token:"<DB_DRIVER>", value:"${config.script.db.driver}")
		antBuilder.replace(file:jythonConfigFile, token:"<RCU_SCHEMA_PASSWORD>", value:"${config.script.db.schema.password}")
		
		//Determines if the domain is vanilla or with samples
		if(config.script.wcsites.binaries.install.with.examples)
			antBuilder.replace(file:jythonConfigFile, token:"<WCSITES_TEMPLATE_TYPE>", value:"Oracle WebCenter Sites with Examples")
		else
			antBuilder.replace(file:jythonConfigFile, token:"<WCSITES_TEMPLATE_TYPE>", value:"Oracle WebCenter Sites")
		
		def configWizardLog = config.work + "/fmw_config.log"
		
		// Creates domain, servers, data-sources and appllies JRF
		Utils.echo("Weblogic Configuration Wizard -> " + Utils.PLEASE_WAIT)

		// On UNIX, creates a shell script with the command and runs it, so that a Java tmp directory can be specified
		File configWizardLogFile = new File(configWizardLog)
		configWizardLogFile.text = "Weblogic Configuration Wizard Output" + System.lineSeparator()

		def runConfigWizard = new File(config.work + "/runConfigWizard.sh")
		runConfigWizard.withWriter('utf-8') { writer ->
			writer.writeLine "#!/bin/sh"
			writer.writeLine ""
			writer.writeLine ". " + config.script.oracle.home + "/wlserver/server/bin/setWLSEnv.sh"
			writer.writeLine "mkdir -p tmp"
			writer.writeLine config.script.java.path + " -Djava.io.tmpdir=" + config.work + "/tmp weblogic.WLST " + jythonConfigFile + " >${configWizardLog}"
		}

		Utils.echo("Weblogic Configuration Wizard -> command: " + config.work + "/runConfigWizard.sh")

		antBuilder.chmod(file: config.work + "/runConfigWizard.sh", perm: "755")
		antBuilder.exec(executable : "./runConfigWizard.sh",  dir : config.work, failifexecutionfails : false)

		// Reads config wizard output to determine success or failure
		String fileContents = (new File(configWizardLog)).text
		Utils.echo("${fileContents}")
		if(fileContents.contains(Utils.CONFIG_EXCEPTION) || fileContents.contains(Utils.CONFIG_WLSTEXCEPTION) || fileContents.contains(Utils.CONFIG_ERROR)) {
			Utils.echo("Error -> Failed to run Weblogic Configuration Wizard successfully")
			System.exit(1)
		}
		else
			Utils.echo("Weblogic Configuration Wizard -> Successfully created domain, servers, and datasources")
	}

	/**
	 * Starts Admin Server
	 *
	 * @param domainHome
	 * @return
	 */
	private startAdminServer(def domainHome) {
		def successMsg = Utils.WL_STARTUP_SUCCESS
		def adminServerLog = domainHome + "/servers/AdminServer/logs/" + config.script.oracle.domain + ".log"

		// Cleans up logs
		def dirsToClean = [domainHome + "/servers/AdminServer/logs"]
		dirsToClean.each { directory -> antBuilder.delete(dir:directory, includeEmptyDirs:true)	}

		adminServerLog = generateAdminServerStartScript(domainHome)
		setTempDirInDomainEnv(domainHome)

		runAdminServerStartScript(domainHome)
		monitorServerLog(adminServerLog, successMsg, true)
	}

	/**
	 * For UNIX, creates a shell script that redirects the output of startWebLogic.sh to a log file
	 * 
	 * @param domainHome
	 * @return
	 */
	private def generateAdminServerStartScript(def domainHome) {		
		def startAdminServerLog = config.work + "/wls_admin_server.log"
		def startAdminServerLogFile = new File(startAdminServerLog)
		startAdminServerLogFile.text = "Weblogic Admin Server Output" + System.lineSeparator()

		def startScript = domainHome + "/startWebLogic" + Utils.SH
		def runAdminServerScript = config.work + "/startAdminServer" + Utils.SH
		def runAdminServerScriptFile = new File(runAdminServerScript)
		runAdminServerScriptFile.withWriter('utf-8') { writer ->
			writer.writeLine "#!/bin/sh"
			writer.writeLine ""
			writer.writeLine ". " + startScript + " > " + startAdminServerLog + " 2>&1 &"
		}

		Utils.echo("Start Admin Server -> Script to start admin server is created : " + runAdminServerScript)

		antBuilder.chmod(file: runAdminServerScript, perm: "755")
		
		startAdminServerLog
	}
	
	/**
	 * Sets Java tmp directory for Weblogic by setting it in setDomainEnv.sh
	 * 
	 * @param domainHome
	 * @return
	 */
	private setTempDirInDomainEnv(def domainHome) {
		def domainEnvScript = domainHome + "/bin/setDomainEnv" + Utils.SH
		def newTmpDirStr = "EXTRA_JAVA_PROPERTIES=\"-Djava.io.tmpdir=" + config.work + "/tmp \${EXTRA_JAVA_PROPERTIES}\"" + System.lineSeparator() + "export EXTRA_JAVA_PROPERTIES" 
		antBuilder.replace(file: domainEnvScript, token: "export EXTRA_JAVA_PROPERTIES", value: newTmpDirStr, summary: true)
	}

	/**
	 * Calls the Start Admin Server startup script
	 *
	 * @param domainHome
	 * @return
	 */
	private runAdminServerStartScript(def domainHome) {
		def startScript = config.work + "/startAdminServer" + Utils.SH
		Utils.echo("Start Admin Server -> script: " + startScript)
		antBuilder.exec(executable : "./startAdminServer.sh",  dir : config.work, failifexecutionfails : false)
	}

	/**
	 * Starts Managed Server after cleaning up logs & creating password file
	 *
	 * @param domainHome
	 * @return
	 */
	private startManagedServer(def domainHome) {
		// Cleans up logs
		def dirsToClean = [domainHome + "/servers/" + config.script.server.name + "/logs", domainHome + "/servers/" + config.script.server.name + "/security"]
		dirsToClean.each { directory -> antBuilder.delete(dir:directory, includeEmptyDirs:true)	}
		// Creates password file
		createPwdFile(domainHome, config.script.server.name)
		// Starts server
		runManagedServerStartScript(domainHome, config.script.server.name)
		// Monitors server log for startup message
		monitorServerLog(domainHome + "/servers/" + config.script.server.name + "/logs/" + config.script.server.name + ".log", Utils.WL_STARTUP_SUCCESS, true)
	}

	/**
	 * The password file is needed for Weblogic Managed Server to start without prompting for user-name/password
	 *
	 * @param domainHome, serverName
	 * @return
	 */
	protected createPwdFile(def domainHome, def serverName) {
		def securityFolderPath = domainHome + "/servers/" + serverName + "/security"
		def securityFolder = new File( securityFolderPath )
		
		// If it doesn't exist
		if( !securityFolder.exists() )
		  securityFolder.mkdirs()

		// Write user-name/password to file
		File file = new File( securityFolder, "boot.properties" )
		Utils.echo("Create Password File -> " + file.getPath())
		file.text = "username=" + config.script.admin.server.username + System.lineSeparator() + "password=" + config.script.admin.server.password
	}

	/**
	 * Start Managed Server
	 *
	 * @param domainHome, serverName
	 * @return
	 */
	protected runManagedServerStartScript(def domainHome, def serverName) {
		def startScript = domainHome + "/bin/startManagedWebLogic" + Utils.SH
		def adminServerURL = "http://" + config.script.oracle.wcsites.hostname + ":" + config.script.admin.server.port

		Utils.echo("Start Managed Server -> " + startScript + " " + serverName + " " + adminServerURL)
		
		antBuilder.exec(executable:startScript, spawn:true) {
			arg(value: serverName)
			arg(value: adminServerURL)
		}
	}
	
	/**
	 * Restart Managed Server
	 *
	 * @param domainHome, exitOnFail
	 * @return
	 */
	private restartManagedServer(def domainHome, boolean exitOnFail) {
		// Stops managed server
		stopManagedServer(domainHome, config.script.server.name, exitOnFail)
		// pauses between stop & start
		Thread.sleep(15000)
		// Starts managed server
		runManagedServerStartScript(domainHome, config.script.server.name)
		// Pauses before you start monitoring the server log
		Thread.sleep(30000)
		// Monitors server log for startup message
		monitorServerLog(domainHome + "/servers/" + config.script.server.name + "/logs/" + config.script.server.name + ".log", Utils.WL_STARTUP_SUCCESS, exitOnFail)
	}

	/**
	 * Stops Managed Server
	 *
	 * @param domainHome, serverName, exitOnFail
	 * @return
	 */
	protected stopManagedServer(def domainHome, def serverName, boolean exitOnFail) {
		def stopScript = ""
		def stopLog = ""
		def stopManagedServerMsg = ""
		
		def adminServerURL = "t3://" + config.script.oracle.wcsites.hostname + ":" + config.script.admin.server.port

		stopLog = generateManagedServerStopScript(domainHome)
		stopScript = config.work + "/stopManagedServer" + Utils.SH
		stopManagedServerMsg = Utils.WL_ADMIN_SHUTDOWN_SUCCESS

		Utils.echo("Stop Managed Server -> script: " + stopScript + "  server name: " + serverName + "  admin-server-url: " + adminServerURL)

		if(!new File(stopScript).exists()) {
			Utils.echo("Error -> Stop Managed Server -- Could not locate the script to stop managed server: " + stopScript)
			if(exitOnFail)
				System.exit(1)
			else
				return
		}

		antBuilder.exec(executable:stopScript, dir : config.work, failifexecutionfails : false) {
			arg(value: serverName)
			arg(value: adminServerURL)
			arg(value: config.script.admin.server.username)
			arg(value: config.script.admin.server.password)
		}

		// Pauses before you start monitoring the server log
		Thread.sleep(30000)

		// Monitors server log file for shutdown message
		monitorServerLog(stopLog, stopManagedServerMsg, exitOnFail)
	}

	/**
	 * For UNIX, creates a shell script that redirects the output of stopManagedWebLogic.sh to a log file
	 *
	 * @param domainHome
	 * @return
	 */
	private def generateManagedServerStopScript(def domainHome) {
		def stopManagedServerLog = config.work + "/wls_managed_server_stop.log"
		def stopManagedServerLogFile = new File(stopManagedServerLog)
		stopManagedServerLogFile.text = "Weblogic Managed Server Shutdown Output" + System.lineSeparator()

		def stopScript = domainHome + "/bin/stopManagedWebLogic" + Utils.SH
		def stopManagedServerScript = config.work + "/stopManagedServer" + Utils.SH
		def stopManagedServerScriptFile = new File(stopManagedServerScript)
		stopManagedServerScriptFile.withWriter('utf-8') { writer ->
			writer.writeLine "#!/bin/sh"
			writer.writeLine ""
			writer.writeLine ". " + stopScript + " \$1 \$2 \$3 \$4 > " + stopManagedServerLog + " 2>&1 &"
		}

		Utils.echo("Stop Managed Server -> Script to stop managed server is created: " + stopManagedServerScript)

		antBuilder.chmod(file: stopManagedServerScript, perm: "755")

		stopManagedServerLog
	}

	/**
	 * Calls the script to Stop Managed Server
	 * @param domainHome, exitOnFail
	 * @return
	 */
	private stopAdminServer(def domainHome, boolean exitOnFail) {
		def stopScript = domainHome + "/bin/stopWebLogic" + Utils.SH
		def stopAdminServerLog = config.work + "/stopAdminServer.log"
		Utils.echo("Stop Admin Server -> script: " + stopScript)

		if(!new File(stopScript).exists()) {
			Utils.echo("Error -> Stop Admin Server -- Could not locate the script to stop admin server: " + stopScript)
			if(exitOnFail)
				System.exit(1)
			else
				return
		}

		antBuilder.exec(executable: stopScript, output : stopAdminServerLog)

		// Pauses before you start monitoring the server log
		Thread.sleep(30000)
		
		// Monitors the server log file for shutdown message
		monitorServerLog(config.work + "/stopAdminServer.log", Utils.WL_ADMIN_SHUTDOWN_SUCCESS, exitOnFail)
	}

	/**
	 * Reads the application server log file at 10 second intervals for messages that indicate successful/failed startup.
	 * 
	 * @param logFilePath location of the application server log file
	 * @return
	 */
	protected monitorServerLog(def logFilePath, def successMsg, boolean exitOnFail) {
		Utils.echo("Monitor Log -> Server log file: " + logFilePath)
		
		if(!isServerLogFileThere(logFilePath)) {
			Utils.echo("Error -> Weblogic server error. Despite waiting for 5 minutes, server did not generate the log file - " + logFilePath)

			if(exitOnFail)
				System.exit(1)
			else
				return
		}
		
		def serverSuccess = false
		def count = 0

		// Monitors the server log to determine successful/failed startup/stopped. Timeout after 8 minutes.
		while(!serverSuccess) {
			String fileContents = new File(logFilePath).getText('UTF-8')
			serverSuccess = fileContents.contains(successMsg)
			if(count<=90) {
				Utils.echo("Waiting for server " + (count*10) + " seconds")
				TimeUnit.SECONDS.sleep(10)
			}
			else {
				Utils.echo("Error -> Weblogic server did not start/stop after 15 minutes. Please check logs for errors")
				Utils.echo("count=" + count + " serverStarted="+serverSuccess.toString())
				if(exitOnFail)
					System.exit(count)
				else
					return
			}			
			count++
		}

		if(serverSuccess)
			Utils.echo("Server started/stopped successfully")
	}

	/**
	 * Checks if the log file is created.
	 *
	 * @param logFilePath
	 * @return
	 */
	private def isServerLogFileThere(def logFilePath) {
		Utils.echo("Monitor Log -> Check for server log file: " + logFilePath)

		def count = 0
		def serverLogFound = false		
		def serverLogFile = new File(logFilePath)

		// Wait up to 5 minutes for file to be generated, then timeout
		while(count < 15) {
			if (serverLogFile.exists()) {
				serverLogFound = true
				break
			}

			count++
			TimeUnit.SECONDS.sleep(20)
		}

		serverLogFound
	}

	/**
	 * Runs WebCenter Sites Configuration silently
	 *
	 * @return
	 */
	private runSilentInstall() {
		// Silent Configuration of WebCenter Sites
		def url = new URL("${config.oracle.wcsites.connect.string}sitesconfig")
		
		Utils.echo("WebCenter Sites Silent Configuration -> URL: " + url)
		
		HttpURLConnection connection = (HttpURLConnection)url.openConnection()
		connection.setRequestMethod("GET")
		connection.setConnectTimeout(10000)
		connection.connect()
		
		def responseCode = connection.getResponseCode()
		Utils.echo("Silent Install -> response code: " + responseCode)  // Parses the response and looks for the error string
		if(responseCode != 200) {
			Utils.echo("Failed to start WebCenter Sites Configuration. Please check application server logs for errors.")
			System.exit(1)
		}
	}
	
	/**
	 * Reads the sites.log file at 10 second intervals for WebCenter Sites configuration success or failure messages
	 *
	 * @param logFilePath
	 * @return
	 */
	private monitorSitesLog(def logFilePath) {
		Utils.echo("Monitor Log -> WebCenter Sites log file: " + logFilePath)
		
		// Assumes the standard location
		File sitesLogFile = new File(logFilePath)

		// Ensures the log file has been created
		def count = 0 // prevent an infinite loop
		while(!sitesLogFile.exists() && count < 12) {
			count++
			Thread.sleep(10000)
		}

		if(!sitesLogFile.exists()) {
			Utils.echo("Unable to locate WebCenter Sites log file after " + (count*10) + " seconds. Please check application server logs for any errors.")
			System.exit(1)
		}
		
		def installSuccess = false
		def installFailed = false

		// Monitors the WebCenter Sites log for - max of 40 minutes - or - till WebCenter Sites installation has completed successfully/failed.
		count = 0
		def maxCount =  40*60
		while(!installSuccess && !installFailed) {
			String fileContents = sitesLogFile.getText('UTF-8')
			installSuccess = fileContents.contains(Utils.SITES_SUCCESS)
			installFailed = fileContents.contains(Utils.SITES_FAILURE1) || fileContents.contains(Utils.SITES_FAILURE2)
			if(count<=maxCount) {
				Utils.echo("Waiting for WebCenter Sites Configuration to complete. "+(count*10)+" seconds")
				Thread.sleep(10000)
			}
			else {
				Utils.echo("WebCenter Sites Configuration did not complete within "+(maxCount/60)+" mins. Please check logs for errors.")
				Utils.echo(""+(count*10)+ "seconds installSuccess="+installSuccess.toString() +" installFailed="+ installFailed.toString())
				System.exit(count)
			}
			count++
		}

		if (installSuccess)
			Utils.echo("WebCenter Sites configuration completed successfully.")
		else if (installFailed) {
			Utils.echo("WebCenter Sites configuration failed. Please check logs for errors.")
			System.exit(count)
		}
	}

	/**
	 * To drop the schema run a command like:
	 * 
	 * rcu -silent -dropRepository -databaseType SQLSERVER -connectString localhost:1433:databasename -dbUser dbusername -schemaPrefix WCS -component STB -component IAU_VIEWER -component IAU -component OPSS -component WCSITES -component IAU_APPEND -f < C:\rcu_passwords.txt
	 *
	 * @param exitOnFail
	 * @return
	 */
	private cleanDB(boolean exitOnFail) {		
		Utils.echo("Clean -> Repository Creation Utility - drop schema")

		def rcu = "${config.script.oracle.home}/oracle_common/bin/rcu"
		if(!new File(rcu).exists()) {
			Utils.echo("Error -> Repository Creation Utility - drop schema. Utility not found! -- " + rcu)
			return
		}

		def connectString = "${config.script.db.dbConnectString}"
		def dbUser = "${config.script.db.user}"
		def dbPassword = "${config.script.db.password}"
		def dbSchemaPassword = "${config.script.db.schema.password}"

		if (dbSchemaPassword.length() <= 0) {
			Utils.echo("Setting schema password to database password as script.db.schema.password is not being set.")
			dbSchemaPassword = dbPassword
		}

		def dbType = ""
		def dbRole = ""
		dbType = "ORACLE"
		if(dbUser.equalsIgnoreCase( "SYS" ))
			dbRole = "-dbRole SYSDBA "

		else {
			Utils.echo("Unable to identify the database type. Make sure the oracle.wcsites.database.type property is set correctly in wcs_properties_bootstrap.ini")
			System.exit(1)
		}

		StringBuilder buffer = new StringBuilder("-silent -dropRepository -databaseType ${dbType} -connectString ${connectString} -dbUser ${dbUser} ${dbRole}-schemaPrefix ${config.script.rcu.prefix}")
		def components = ["STB", "IAU", "IAU_VIEWER", "IAU_APPEND", "OPSS", "WCSITES", "WLS"]
		components.each { 
			name -> buffer.append(" -component ${name}") 
		}
		
		// RCU prompts for schema password and does not take a command line argument for it 
		// To make the drop repository operation silent, use redirector command to pass the schema password
		Path pwdFilePath = Files.createTempFile(Paths.get("${config.work}"), "rcuPasswords", ".txt")
		BufferedWriter bw = Files.newBufferedWriter(pwdFilePath)
		bw.writeLine("${dbPassword}")
		components.each {
			bw.writeLine("${dbSchemaPassword}")
		}
		bw.close()
		buffer.append(" -f < " + pwdFilePath.toAbsolutePath())
		
		// Redirects the console output to a static file
		def rcuLog = "${config.work}/rcu_output.log"
		File rcuLogFile = new File(rcuLog)
		rcuLogFile.text = "RCU Output" + System.lineSeparator()
		buffer.append(" >${rcuLog}")
		
		def	args = buffer.toString()
		Utils.echo("Drop schema using command: ${rcu} ${args}")
		Utils.echo("RCU Drop schema -> " + Utils.PLEASE_WAIT)
		

		// On UNIX platforms, running antBuilder.exec with the required arguments is not working.
		// As a workaround, create a script with the command and run it.
		def rcuTempDir = config.work + "/rcu"
		def rcuDropFile = new File(config.work + "/rcuDrop.sh")
		rcuDropFile.withWriter('utf-8') { writer ->
			writer.writeLine "#!/bin/sh"
			writer.writeLine ""
			writer.writeLine "export RCU_LOG_LOCATION="+rcuTempDir
			writer.writeLine rcu + " " + args
		}

		antBuilder.chmod(file: config.work + "/rcuDrop.sh", perm: "755")
		antBuilder.exec(executable : "./rcuDrop.sh",  dir : config.work, failifexecutionfails : false)

		// Reads the RCU console output to determine success or failure
		String fileContents = rcuLogFile.text
		Utils.echo("${fileContents}")
		if(fileContents.contains(Utils.RCU_DROP_SUCCESS))
			Utils.echo("Successfully dropped schemas")
		else if(fileContents.contains(Utils.RCU_FAILURE)) {
			Utils.echo("Unable to drop schema successfully")
			if(exitOnFail)
				System.exit(1)
		}
		else
			Utils.echo("Unable to identify if drop schema ran successfully. Assuming success.")
	}

	/**
	 * Builds the domain home string variable
	 *
	 * @return
	 */
	protected def getDomainHome() {
		config.script.oracle.home + "/user_projects/domains/" + config.script.oracle.domain
	}
}