/**
 * Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
 * Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 */
package com.oracle.wcsites.install

interface AppServer {

	/**
	 * Extracts binaries, copies relevant files/directories
	 */
	def unPack()
	
	/**
	 * Creates database schema
	 */
	def createSchema()

	/**
	 * Kicks off silent install and restarts server
	 */
	def install()
}
