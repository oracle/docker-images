/**
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
 * Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 */
package com.oracle.wcsites.install

import groovy.sql.*

import java.sql.SQLException
import java.text.SimpleDateFormat

class Utils {
	public static def WL_STARTUP_SUCCESS = "Server state changed to RUNNING"
	public static def WL_ADMIN_PRODUCTION_STARTUP_SUCESS = "Started the WebLogic Server Administration Server"
	public static def WL_SHUTDOWN_SUCCESS = "Shutdown has completed"
	public static def WL_ADMIN_SHUTDOWN_SUCCESS = "Derby server stopped"
	public static def SITES_SUCCESS = "Sites Configuration finished successfully"
	public static def SITES_FAILURE1 = "Sites Configuration failed"
	public static def SITES_FAILURE2 = "Install failed"
	public static def RCU_DROP_SUCCESS = "Repository Creation Utility - Drop : Operation Completed"
	public static def RCU_CREATE_SUCCESS = "Repository Creation Utility - Create : Operation Completed"	
	public static def RCU_FAILURE = "ERROR - RCU-"
	public static def FMW_SUCCESS = "*Oracle Fusion Middleware 1* Infrastructure 1* completed successfully*"
	public static def WCSITES_BINARIES_SUCCESS = "*WebCenterSites 1* completed successfully*"
	public static def CONFIG_RUN_SUCCESS = ""
	public static def CONFIG_ERROR = "Error"
	public static def CONFIG_EXCEPTION = "Exception"
	public static def CONFIG_WLSTEXCEPTION = "WLSTException"
	public static def ORACLE = "Oracle"
	public static def ORACLE_DRIVER = "oracle.jdbc.OracleDriver"
	public static def ORACLE_URL = "jdbc:oracle:thin:@"
	public static def WLS92 = "wls92"
	public static def WEBLOGIC = "weblogic"
	public static def SH = ".sh"
	public static def WEBLOGIC_PORT = 7002
	public static def DATA_SOURCE = "wcsitesDS"
	public static def HTTP = "http"
	public static def PLEASE_WAIT = "Please wait ... may take several minutes"
	// List of possible commands
	public static def CMD_CLEAN = "clean"
	public static def CMD_RCU = "rcu"
	public static def CMD_DOWNLOAD = "download"
	public static def CMD_UNPACK = "unpack"
	public static def CMD_DEPLOY = "deploy"
	public static def CMD_INSTALL = "install"
	public static def CMD_ALL = "all"

	private def static antBuilder = new AntBuilder()

	// List of configuration files to load properties from
	public static def PRIMARY_CONFIGURATION_FILE = "bootstrap.properties"
	public static def WCSITES_SILENT_INSTALL_RSP_FILE = "wcs_properties_bootstrap.ini"
	public static def CONFIG_SCRIPT = "config.py"

	public static def ENV_GENERIC = "generic"
	public static def ENV_DOCKER = "docker"

	/**
	 * Echoes messages to system.out which is helpful in debugging
	 *
	 * @param message the message to be echoed
	 */
	def static echo(def message) {
		def sdf = new SimpleDateFormat()
		
		message = "[" + sdf.format(new Date()) + "] " + message
		antBuilder.echo(message: message)
	}
	
	/**
	 * Loads all configuration properties. Sets default values for optional properties. 
	 * Generates the WebCenter Sites silent response file.
	 *  
	 * @param folder - folder where configuration files are located
	 * @return
	 */
	def static loadConfiguration(def folder) {
		// Declarations
		def fis		
		def merged = new Properties()
		Properties properties

		// Loads properties specified in the primary configuration file
		fis = new FileInputStream(folder + "/" + PRIMARY_CONFIGURATION_FILE)
		properties = new Properties()
		if (fis != null)
			properties.load(fis)

		// Sets default values for optional properties
		properties = setOptionalProperties(properties)
		merged.putAll(properties)
		
		def config = new ConfigSlurper().parse(merged)

		// Adds the resources folder location to config object
		config.resources = folder

		// Sets any derived/additional properties used by this script
		setAdditionalProperties(config)
		
		config		
	}
	
	/**
	 * User might have left the values blank. To address blank values, use appropriate defaults.
	 * 
	 * @param config
	 * @return
	 */
	private static setOptionalProperties(Properties properties) {
		def config = new ConfigSlurper().parse(properties)

		// WebCenter Sites protocol
		if (!config.script.oracle.wcsites.protocol?.trim()) {
			config.script.oracle.sites.config=HTTP
			
			properties.setProperty("script.oracle.wcsites.protocol", config.script.oracle.sites.config)
		}
			
		// WebCenter Sites port
		String port = config.script.oracle.wcsites.portnumber
		if (!config.script.oracle.wcsites.portnumber?.trim()) {
			if(config.script.oracle.wcsites.appserver.type == WEBLOGIC)
				config.script.oracle.wcsites.portnumber = WEBLOGIC_PORT
				
			port = config.script.oracle.wcsites.portnumber
			properties.setProperty("script.oracle.wcsites.portnumber", port)
		}
		
		// WebCenter Sites data source name
		if (!config.script.oracle.wcsites.database.datasource?.trim()) {
			config.script.oracle.wcsites.database.datasource = DATA_SOURCE
				
			properties.setProperty("script.oracle.wcsites.database.datasource", config.script.oracle.wcsites.database.datasource)
		}
		
		// WebCenter Sites shared directory
		if (!config.script.oracle.wcsites.shared?.trim()) {
				config.script.oracle.wcsites.shared = config.script.oracle.home + "/sites-shared"
				properties.setProperty("script.oracle.wcsites.shared", config.script.oracle.wcsites.shared)
		}
		
		// WebCenter Sites config directory
		if (!config.script.sites.config?.trim()) {
			if(config.script.oracle.wcsites.appserver.type == WEBLOGIC)
				config.script.sites.config="${config.script.oracle.home}/user_projects/domains/${config.script.oracle.domain}/wcsites/wcsites/config"
			else {
				echo("Unable to identify the application server type!")
				System.exit(1)
			}
			
			properties.setProperty("script.sites.config", config.script.sites.config)
		}
		
		// WebCenter Sites protocol
		if (!config.script.oracle.wcsites.contextpath?.trim()) {
			config.script.oracle.wcsites.contextpath="/sites/"
			
			properties.setProperty("script.oracle.wcsites.contextpath", config.script.oracle.wcsites.contextpath)
		}
		
		// Weblogic specific properties
		if(config.script.oracle.wcsites.appserver.type == WEBLOGIC) {
			config.script.sites.home = config.script.oracle.home +"/wcsites/webcentersites/sites-home"
			properties.setProperty("script.sites.home", config.script.sites.home)
		}

		// Sets the empty values to false
		if (!config.script.oracle.wcsites.examples.fsii?.trim()) {
			config.script.oracle.wcsites.examples.fsii = "false"

			properties.setProperty("script.oracle.wcsites.examples.fsii", config.script.oracle.wcsites.examples.fsii)
		}

		if (!config.script.oracle.wcsites.examples.avisports?.trim()) {
			config.script.oracle.wcsites.examples.avisports = "false"
			properties.setProperty("script.oracle.wcsites.examples.avisports", config.script.oracle.wcsites.examples.avisports)
		}

		if (!config.script.oracle.wcsites.examples.Samples?.trim()) {
			config.script.oracle.wcsites.examples.Samples = "false"
			properties.setProperty("script.oracle.wcsites.examples.Samples", config.script.oracle.wcsites.examples.Samples)
		}


		if (!config.script.oracle.wcsites.examples.blogs?.trim()) {
			config.script.oracle.wcsites.examples.blogs = "false"
			properties.setProperty("script.oracle.wcsites.examples.blogs", config.script.oracle.wcsites.examples.blogs)
		}

		if(config.script.oracle.wcsites.examples.fsii || config.script.oracle.wcsites.examples.avisports ||
		config.script.oracle.wcsites.examples.Samples || config.script.oracle.wcsites.examples.blogs ) {
			properties.setProperty("script.oracle.wcsites.examples.examples", "true")
		}
		else
			properties.setProperty("script.oracle.wcsites.examples.examples", "false")
		 
		properties
	}
	
	/**
	 * Sets derived/additional properties
	 * 
	 * @param config
	 * @return
	 */
	private static setAdditionalProperties(def config) {
		config.oracle.wcsites.connect.string = "${config.script.oracle.wcsites.protocol}://${config.script.oracle.wcsites.hostname}:${config.script.oracle.wcsites.portnumber}${config.script.oracle.wcsites.contextpath}"

		// Gets the directory in which the program is runnning
		def currentDir = System.getProperty("user.dir")
		if (!(currentDir.endsWith(File.separator) || currentDir.endsWith("\\") || currentDir.endsWith("/")))
			currentDir += File.separator

		// Sets the work directory
		if (config.script.work.dir?.trim())
			config.work = config.script.work.dir	// User specified work directory
		else
			config.work = new File(currentDir + "work/tmp" ).getCanonicalPath()
		
		// Validates the work directory
		createAndValidateDir("${config.work}", "script.work.dir")
		echo("Work Directory=${config.work}")
		
		// Sets JAVA tmp dir
		System.setProperty("java.io.tmpdir", "${config.work}");

		// Sets the database properties
		config.script.db.type = config.script.oracle.wcsites.database.type
		if("${config.script.oracle.wcsites.database.type}".equalsIgnoreCase(ORACLE)) {
			config.script.db.url = ORACLE_URL
			config.script.db.driver = ORACLE_DRIVER
		}else {
			println "Error -> Unable to identify database type. Please check the property - script.oracle.wcsites.database.type"
			System.exit(1)
		}
		echo("DB URL: " + config.script.db.url)

		setDBConnectStringPropertey(config);

		// A few properties are hardcoded.
		config.script.wl.install.with.examples = false
		config.script.wcsites.binaries.install.with.examples = true
		config.script.oracle.wcsites.examples.burlingtonfinancial = false
		config.script.oracle.wcsites.examples.helloassetworld = false
		config.script.oracle.wcsites.examples.gelighting = false
	}

	/**
	 * Sets dbConnectString property
	 *
	 * @param config
	 * @return
	 */
	private static setDBConnectStringPropertey(def config) {
		def dbType = config.script.oracle.wcsites.database.type
		def dbUrlSeperator = ":"

		if (!config.script.db.connectstring?.trim()) {
			echo("Info -> The script.db.connectstring has not been set. Building it using the instance name.")
			config.script.db.dbConnectString = config.script.db.host + ":" + config.script.db.port + dbUrlSeperator+ config.script.db.instance
		}else{
			echo("Info -> The script.db.connectstring has been set.")
			config.script.db.dbConnectString = config.script.db.connectstring
		}
		echo("Info.setDBConnectStringPropertey -> setting " + config.script.db.dbConnectString)
	}

	def static validateInputs(def config) {
		// Ensures the command is specified
		if (!config.script.command?.trim()) {
			echo("Error -> The script command has not been set. Check the script.command property in bootstrap.properties")
			System.exit(1)
		}

		// Java validations
		if(!isCorrectJavaVersion()) {
			echo("Error -> Please use Java 8 or greater to execute this utility")
			System.exit(1)
		}

		// Validates username and password
		if (!config.script.admin.server.username?.trim()) {
			echo("Error -> The Weblogic Admin Server User Name has not been set")
			System.exit(1)
		}
		else if (!config.script.admin.server.password?.trim()) {
			echo("Error -> The Weblogic Admin Server Password has not been set")
			System.exit(1)
		}

		// Validates java
		echo("Validation -> Checking if full path to JAVA executable is correctly specified")
		antBuilder.exec(executable : config.script.java.path, failifexecutionfails: true) {
			arg(value: "-version")
		}
		
		// Validates the database connection
		echo("Validation -> Checking database connection")
		testDBConnection(config)
	}

	/**
	 * Creates and validates directory
	 *
	 * @param dirToCheck
	 * @param propertyToModify
	 * @return
	 */
	private static createAndValidateDir(def dirToCheck, def propertyToModify) {
		try {
			antBuilder.mkdir(dir : dirToCheck)

			def folder = new File(dirToCheck)
			if( !folder.exists() )
				generateDirError(dirToCheck, propertyToModify)
		} catch(Exception ex) {
			generateDirError(dirToCheck, propertyToModify)
		}
	}

	/**
	 * Generates directory error
	 *
	 * @param checkedDir
	 * @param propertyToModify
	 * @return
	 */
	private static generateDirError(def checkedDir, def propertyToModify) {
		println "Error -> Could not write to directory - " + checkedDir + " - Please specify " + propertyToModify + " to use an alternate location."
		System.exit(1)
	}

	/**
	 * Validates java version
	 *
	 * @return true or false
	 */
	private static def isCorrectJavaVersion() {
		def correctVersion = false
		Double version = Double.parseDouble(System.getProperty("java.specification.version"));

		if (version > 1.7)
			correctVersion = true

		correctVersion
	}

	/**
	 * Tests and validates database connection
	 *
	 * @param config
	 * @return
	 */
	private static testDBConnection(def config) {
		if("${config.script.oracle.wcsites.database.type}".trim().equalsIgnoreCase(ORACLE)) {
			Properties dbProperties = new Properties()
			dbProperties.put("user", config.script.db.user)
			dbProperties.put("password", config.script.db.password)
			if(config.script.db.user.equalsIgnoreCase("SYS"))
				dbProperties.put("internal_logon", "sysdba")

			def dbUrl = config.script.db.url + config.script.db.dbConnectString

			Utils.echo("dbUrl-----------------: " + dbUrl)
			
			// Checks if database credentials are correct
			try {
				Sql.withInstance(dbUrl, dbProperties, config.script.db.driver) { sql ->
					sql.eachRow ('select 1 from dual') { row -> assert row[0]==1 }
				}

				echo("Database Connection --> Success!")
			} catch(SQLException e) {
				echo("Please check the database parameters in the configuration file. --> " + e)
				e.printStackTrace()
				System.exit(1)
			} catch(Exception e) {
				echo("Please check the database parameters in the configuration file. --> " + e)
				e.printStackTrace()
				System.exit(1)
			}
		}  else {
			echo("Error -> Unable to identify the database type")
			System.exit(1)
		}
	}

	/**
	 * Changes the multi-cast port in relevant files if a multi-cast port value is specified.
	 *
	 * @param config
	 */
	def static changeMulticastPorts(def config) {
		def port =  config.script.cache.multicastport

		if(port?.trim()) {
			port = port.toInteger()
			antBuilder.replaceregexp(file:"${config.script.sites.config}/jbossTicketCacheReplicationConfig.xml", 
				match:"mcast_port=\"\\d*\"", replace:"mcast_port=\"${port}\"", byline:true)
				
			antBuilder.replaceregexp(file:"${config.script.sites.config}/cs-cache.xml",
				match:"multicastGroupPort=\\d*", replace:"multicastGroupPort=${++port}", byline:true)
				
			antBuilder.replaceregexp(file:"${config.script.sites.config}/cas-cache.xml",
				match:"multicastGroupPort=\\d*", replace:"multicastGroupPort=${++port}", byline:true)
				
			antBuilder.replaceregexp(file:"${config.script.sites.config}/linked-cache.xml",
				match:"multicastGroupPort=\\d*", replace:"multicastGroupPort=${++port}", byline:true)
				
			antBuilder.replaceregexp(file:"${config.script.sites.config}/ss-cache.xml",
			match:"multicastGroupPort=\\d*", replace:"multicastGroupPort=${++port}", byline:true)
		}
	}
	
	/**
	 * Updates WebCenter Sites silent installation template file with user specified and default values. Copies the template file to the config directory.
	 * 
	 * @param sampleRspFile
	 * @param config
	 * @return
	 */
	def static copyWCSSilentInstallResponseFile(def sampleRspFile,  def config) {		
		// Copies the sample silent installation response file to work directory
		antBuilder.copy(todir:config.work, overwrite:true, verbose:true) {
			fileset(file: "${sampleRspFile}")
		}
		
		def fileString = new File(config.work + "/"+ WCSITES_SILENT_INSTALL_RSP_FILE)
		// Updates the WebCenter Sites silent installation response file with user specified and default values
		updateSilentInstallResponseFile("${fileString}", config)
		// Copies over wcs_properties_bootstrap.ini for WebCenter Sites silent installation
		antBuilder.copy(todir:config.script.sites.config, overwrite:true, verbose:true) {
			fileset(file:"${fileString}")
		}
	}

	/**
	 * Monitors the log file for a message for maxTime
	 *
	 * @param msg - message to find
	 * @param logFilePath
	 * @param maxTime
	 * @return true if found in given time. Else return false.
	 */
	def static boolean monitorLogMsg(def msg, def logFilePath, def maxTime) {

		def found = false
		def count = 0 // Helps to prevent indefinite loop
		def curTime
		// Monitors the log contents for utmost maxTime or until the message is found successfully.
		while(!found) {
			String fileContents = new File(logFilePath).getText('UTF-8')
			found = fileContents.contains(msg)
			curTime = count * 10
			if(curTime <= maxTime)
				Thread.sleep(10000)
			else
				return false;
			count++
		}
		return true;
	}
	
	/**
	 * Updates the WebCenter Sites silent installation response file with the appropriate user specified and default values.
	 *
	 * @param rspFile, config
	 * @return
	 */
	private static updateSilentInstallResponseFile(def sampleRspFile, def config) {
		File file = new File(sampleRspFile)
		def rspFile = config.work + File.separator + file.getName()

		// Host name
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.hostname=", value: "oracle.wcsites.hostname=" + config.script.oracle.wcsites.hostname, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.cas.hostname=", value: "oracle.wcsites.cas.hostname=" + config.script.oracle.wcsites.hostname, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.cas.hostnameActual=", value: "oracle.wcsites.cas.hostnameActual=" + config.script.oracle.wcsites.hostname, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.cas.hostnameLocal=", value: "oracle.wcsites.cas.hostnameLocal=" + config.script.oracle.wcsites.hostname, summary: true)

		// Database type
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.database.type=", value: "oracle.wcsites.database.type=" + config.script.oracle.wcsites.database.type, summary: true)

		if(config.script.oracle.wcsites.appserver.type == WEBLOGIC)
			antBuilder.replace(file: rspFile, token: "oracle.wcsites.appserver.type=", value: "oracle.wcsites.appserver.type=" + WLS92, summary: true)

		// Port
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.portnumber=", value: "oracle.wcsites.portnumber=" + config.script.oracle.wcsites.portnumber, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.cas.portnumber=", value: "oracle.wcsites.cas.portnumber=" + config.script.oracle.wcsites.portnumber, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.cas.portnumberLocal=", value: "oracle.wcsites.cas.portnumberLocal=" + config.script.oracle.wcsites.portnumber, summary: true)

		// Data source name
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.database.datasource=", value: "oracle.wcsites.database.datasource=" + config.script.oracle.wcsites.database.datasource, summary: true)

		// Sites shared directory
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.shared=", value: "oracle.wcsites.shared=" + config.script.oracle.wcsites.shared, summary: true)

		// Samples
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples=", value: "oracle.wcsites.examples="+ config.script.oracle.wcsites.examples.examples, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.fsii=", value: "oracle.wcsites.examples.fsii="+ config.script.oracle.wcsites.examples.fsii, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.avisports=", value: "oracle.wcsites.examples.avisports="+ config.script.oracle.wcsites.examples.avisports, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.Samples=", value: "oracle.wcsites.examples.Samples="+ config.script.oracle.wcsites.examples.Samples, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.burlingtonfinancial=", value: "oracle.wcsites.examples.burlingtonfinancial="+ config.script.oracle.wcsites.examples.burlingtonfinancial, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.helloassetworld=", value: "oracle.wcsites.examples.helloassetworld="+ config.script.oracle.wcsites.examples.helloassetworld, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.gelighting=", value: "oracle.wcsites.examples.gelighting="+ config.script.oracle.wcsites.examples.gelighting, summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.examples.blogs=", value: "oracle.wcsites.examples.blogs="+ config.script.oracle.wcsites.examples.blogs, summary: true)

		// Protocol
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.protocol=", value: "oracle.wcsites.protocol="+ config.script.oracle.wcsites.protocol, summary: true)

		// Sites context path
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.contextpath=", value: "oracle.wcsites.contextpath="+ config.script.oracle.wcsites.contextpath, summary: true)

		// Bootstrap status
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.bootstrap.status=", value: "oracle.wcsites.bootstrap.status=never_done", summary: true)

		// Admin user
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.system.admin.user=", value: "oracle.wcsites.system.admin.user=" + config.script.oracle.wcsites.system.admin.user , summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.system.admin.password=", value: "oracle.wcsites.system.admin.password=" + config.script.oracle.wcsites.system.admin.password , summary: true)

		// Application user
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.app.user=", value: "oracle.wcsites.app.user=" + config.script.oracle.wcsites.app.user , summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.app.password=", value: "oracle.wcsites.app.password=" + config.script.oracle.wcsites.app.password , summary: true)

		// Satellite user
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.satellite.user=", value: "oracle.wcsites.satellite.user=" + config.script.oracle.wcsites.satellite.user , summary: true)
		antBuilder.replace(file: rspFile, token: "oracle.wcsites.satellite.password=", value: "oracle.wcsites.satellite.password=" + config.script.oracle.wcsites.satellite.password, summary: true)
	}
}