#!/bin/sh
#
# This script modifies the installer scripts and response files to match the local environment.
# This includes the following substitutions:
#
# Variable		Use						Example	
# --------------	---------------------------------------		---------------------
# KIT_LOCATION		Where the installer zip file is located		/home/tuxtest/Downloads
# INSTALLER_DIR		Where the installed will be unzipped to		/home/tuxtest/temp
# PRODUCT_HOME		Where the product's home directory should be	/home/tuxtest/tuxHome
# HOME_NAME		Name of the product's home			tuxHome
# PRODUCT_BASE								C:\app
# ORA_INVENTORY		Location of the oraInst.loc file		/home/tuxtest/oraInventory
# USER_NAME		User name of the account installing the kit	tuxtest
# GROUP_NAME		Group name of the account installing the kit	tuxtest
# TLISTEN_PORT		Port for tlisten				3050
# TLISTEN_PASSWORD	Password for tlisten				oracle
#	
# To run this script, create a file with the above variables and their values with the variable name in the first
# column and the value in the second column.  Invoke this script passing in the name of that file and the name
# of the file to perform the substitutions in.
#
# Example:   fix_locations tuxedo.docker tuxedo12.1.3.rsp
#
#
TFILE="fix${RANDOM}.$$.tmp"
cp $2 $TFILE
while read var value
do
	sed -i "s=<$var>=$value=g" $TFILE
done <$1
cat $TFILE; rm $TFILE
