#!/bin/bash
#
#############################
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
# 

#source /tmp/envfile

source $SCRIPT_DIR/functions.sh 

####################### Constants #################
# shellcheck disable=SC2034
declare -r FALSE=1
# shellcheck disable=SC2034
declare -r TRUE=0
# shellcheck disable=SC2034
declare -r ETCHOSTS="/etc/hosts"
# shellcheck disable=SC2034
declare -A dbhost_map
# shellcheck disable=SC2034
declare -A rule_map
# shellcheck disable=SC2034
declare hostip
# shellcheck disable=SC2034
declare action=""
# shellcheck disable=SC2034
progname="$(basename $0)"
###################### Constants ####################

WALLET_TMPL_STR='wallet_location = 
	(source=
		(method=File)
		(method_data=
			(directory=###WALLET_LOCATION###)
	  	)
	)
SQLNET.WALLET_OVERRIDE = TRUE'

RULESRCSET=0
RULEDSTSET=0
RULESRVSET=0
CP="/bin/cp"

export TRULESTR="    (rule=
       (src=*)(dst=*)(srv=*)(act=accept)
       (action_list=(aut=off)(moct=0)(mct=0)(mit=0)(conn_stats=on))
    )"

export LOCAL_CMCTL_CONN_STR="    (rule=(src=###CMAN_HOSTNAME###.###DOMAIN###)(dst=127.0.0.1)(srv=cmon)(act=accept))"

all_check()
{
if [ -z ${DB_HOSTDETAILS} ]; then
   print_message "DB_HOSTDETAILS not set. Setting to default"
else
   print_message "DB_HOSTDETAILS name is ${DB_HOSTDETAILS}"
   get_dbhost_details
fi

check_cman_env_vars
}

check_cman_env_vars()
{
## Checking Grid Reponsfile or vip,scan ip and private ip
### if user has passed the Grid ResponseFile name, below checks will be skipped

# Following checks will be executed if user is not providing Grid Response File

if [ -z "${DOMAIN}" ]; then
   print_message  "Domain name is not defined. Setting Domain to 'example.com'"
   DOMAIN="example.com"
 else
 print_message "Domain is defined to $DOMAIN"
fi

if [ -z "${PORT}" ]; then
   print_message  "PORT is not defined. Setting PORT to '1521'"
   PORT="1521"
 else
 print_message "PORT is defined to $PORT"
fi

if [ -z "${PUBLIC_IP}" ]; then
    error_exit  "Container hostname is not set or set to the empty string"
else
    print_message "Public IP is set to ${PUBLIC_IP}"
fi

if [ -z "${PUBLIC_HOSTNAME}" ]; then
   error_exit "RAC Node PUBLIC Hostname is not set ot set to empty string"
else
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
fi

if [ -z "${LOG_LEVEL}" ]; then
   LOG_LEVEL=user
fi

if [ -z "${TRACE_LEVEL}" ]; then
   TRACE_LEVEL=user
fi
# shellcheck disable=SC2166
if [ "${TRACE_LEVEL}" != "user" -a "${TRACE_LEVEL}" != "admin" -a "${TRACE_LEVEL}" != "support" ]; then
      print_message "Invalid trace-level [${TRACE_LEVEL}] specified."
fi
# shellcheck disable=SC2166
if [ "${LOG_LEVEL}" != "user" -a "${LOG_LEVEL}" != "admin" -a "${LOG_LEVEL}" != "support" ]; then
      print_message "Invalid log-level [${LOG_LEVEL}] specified."
fi

if [ -z "${REGISTRATION_INVITED_NODES}" ]; then
   REGISTRATION_INVITED_NODES='*'
else
# shellcheck disable=SC2034
   REGINVITEDNODESET=1
fi

}

check_rule_env_vars ()
{

if [ -z "${RULE_SRC}" ]; then
   RULE_SRC='*'
else
   RULESRCSET=1
fi

if [ -z "${RULE_DST}" ]; then
   RULE_DST='*'
else
   RULEDSTSET=1
fi

if [ -z "${RULE_SRV}" ]; then
   RULE_SRV='*'
else
   RULESRVSET=1
fi

if [ -z "${RULE_ACT}" ]; then
   RULE_ACT='accept'
fi

contSubNetIP=`/sbin/ifconfig eth0 | grep 'inet ' | awk '{ print $2 }' | awk -F. '{ print $1 "." $2 "." $3 }'`
echo "Subnet=[$contSubNetIP]"

if [ $RULESRCSET -eq 1 ]; then
   echo ${RULE_SRC} | grep $contSubNetIP > /dev/null 2>&1

   if [ $? -ne 0 ]; then
      print_message "Invalid input. SourceIP [${RULE_SRC}] not a valid subnet. "
   fi
fi

if [ $RULEDSTSET -eq 1 ]; then
   echo ${RULE_DST} | grep $contSubNetIP > /dev/null 2>&1

   if [ $? -ne 0 ]; then
      print_message "Invalid input. DestinationIP [${RULE_DST}] not a valid subnet. "
   fi
fi

if [ $RULESRVSET -eq 1 ]; then
   echo ${RULE_SRV} | grep $contSubNetIP > /dev/null 2>&1

   if [ $? -ne 0 ]; then
      print_message "Invalid input. SrvIP [${RULE_SRV}] not a valid subnet. "
   fi
fi
# shellcheck disable=SC2166
if [ "${RULE_ACT}" != "accept" -a "${RULE_ACT}" != "reject" -a "${RULE_ACT}" != "drop" ]; then
      print_message "Invalid rule-action [${RULE_ACT}] specified."
fi

}

get_dbhost_details()
{

db_hostdetail_values=`echo ${DB_HOSTDETAILS} | sed -e 's/.*?=\(.*\)/\1/g'`
IFS=',' read  -a db_hostvalues <<< "${db_hostdetail_values}"

for db_hostvalue in "${db_hostvalues[@]}"
do
    IFS=':' read -a rule_env_vars <<< "${db_hostvalue}"
    for rule_env_var in "${rule_env_vars[@]}"
    do
       echo "export ${rule_env_var}"
# shellcheck disable=SC2163
       export ${rule_env_var}
    done

    if [ -z ${HOST} ]; then
       error_exit "DB HOST not set. Exiting"
    else
       print_message "DB_HOST name is ${HOST}"
    fi

    dbhost_map[${HOST}]=${IP}
    rule_map[${HOST}]=${db_hostvalue}
# shellcheck disable=SC2178
    rule_env_vars=""
done

check_dbhost_connections
if [ $? -ne 0 ]; then
   error_exit "check_dbhost_connections failed"
fi

}

get_host_ip() {

    nslookup $1 > /dev/null
    if [ $? -ne 0 ]; then
       hostip=""
       echo "$0() : nslookup on $1 failed"
       return 1
    fi

    hostip=`nslookup $1 | tail  -n -3 | grep -v '^$' | grep 'Address:' | awk '{ print $2 }'`

    return 0
}

check_dbhost_connections() {

for key in "${!dbhost_map[@]}";
do
  print_message " -- : $key --> ${dbhost_map[$key]}"
  ping $key -c 1 > /dev/null
  if [ $? -eq 0 ]; then
     print_message "host $key is pingable by name."
     continue
  fi
  if ( [ "${dbhost_map[$key]}" != "" ] ); then
      print_message "$key:${dbhost_map[$key]} is not reachable. Exiting."
      return 1
  fi
  get_host_ip $key
  if [ $? -eq 0 ]; then
     print_message "resolved host ip : $key --> ${hostip}. Check if pinagble by IP"
     ping ${hostip} -c 1 > /dev/null
     if [ $? -ne 0 ]; then
        print_message "host $key not pingable by IP. "
        print_message "host $key:${hostip} not reachable by Name/IP. Exiting"
        return 2
     fi
     dbhost_map[$key]=${hostip}
     continue
  else
     print_message "IP not found for host $key"
     return 3
  fi
done

return 0
}

####################################### ETC Host Function #############################################################

setupEtcResolvConf()
{
# shellcheck disable=SC2034
local stat=3

if [ "$action" == "" ]; then
   if [ ! -z "${DNS_SERVER}" ] ; then
     sudo sh -c "echo \"search  ${DOMAIN}\"  > /etc/resolv.conf"	   
     sudo sh -c "echo \"nameserver ${DNS_SERVER}\"  >> /etc/resolv.conf"
  fi
fi

}

SetupEtcHosts()
{
# shellcheck disable=SC2034
local stat=3
# shellcheck disable=SC2034
local HOST_LINE
if [ "$action" == "" ]; then
 if [ ! -z "${HOSTFILE}" ]; then 
   if [ -f "${HOSTFILE}" ]; then
     sudo sh -c "cat \"${HOSTFILE}\" > /etc/hosts"
   fi
 else	 
  sudo sh -c "echo -e \"127.0.0.1\tlocalhost.localdomain\tlocalhost\" > /etc/hosts"
  sudo sh -c "echo -e \"$PUBLIC_IP\t$PUBLIC_HOSTNAME.$DOMAIN\t$PUBLIC_HOSTNAME\" >> /etc/hosts"
 fi
fi

}

######### Grid setup Function###########################
cman_file ()
{
rm -f $logdir/$CMANORA
touch $logdir/$CMANORA
chown -R oracle:oinstall $logdir/$CMANORA
if [ -f $DB_HOME/network/admin/$CMANORA ]; then
   cp $DB_HOME/network/admin/$CMANORA $logdir/$CMANORA
else
   cat $SCRIPT_DIR/$CMANORA >> $logdir/$CMANORA
   if [ ! -z ${DB_HOSTDETAILS} ]; then
      sh -c "echo $'/(rule=\n\Emk%d\'k\E:x\n' | vi $logdir/$CMANORA" 2>/dev/null
      # Add the local CMCTL connection 
      sh -c "echo $'/(rule_list=\n\Eo${LOCAL_CMCTL_CONN_STR}\E:x\n' | vi $logdir/$CMANORA" 2>/dev/null
   fi
fi

sed -i -e "s|###CMAN_HOSTNAME###|$PUBLIC_HOSTNAME|g" $logdir/$CMANORA
## sed -i -e "s|###DB_HOSTNAME###|$key|g" $logdir/$CMANORA
sed -i -e "s|###DOMAIN###|$DOMAIN|g" $logdir/$CMANORA
sed -i -e "s|###DB_HOME###|$DB_HOME|g" $logdir/$CMANORA
sed -i -e "s|###PORT###|$PORT|g" $logdir/$CMANORA
sed -i -e "s|###LOG_LEVEL###|$LOG_LEVEL|g" $logdir/$CMANORA
sed -i -e "s|###TRACE_LEVEL###|$TRACE_LEVEL|g" $logdir/$CMANORA
sed -i -e "s|(registration_invited_nodes=.*)|(registration_invited_nodes=${REGISTRATION_INVITED_NODES})|g"  $logdir/$CMANORA
for key in "${!dbhost_map[@]}";
do
    unsetrulevars
    IFS=':' read  -a rule_env_vars <<< "${rule_map[$key]}"

    for rule_env_var in "${rule_env_vars[@]}"
    do
# shellcheck disable=SC2163
       echo "export ${rule_env_var}"
# shellcheck disable=SC2163
       export ${rule_env_var}
    done

    check_rule_env_vars
    sh -c "echo $'/(rule_list=\n\Eo${TRULESTR}\E:x\n' | vi $logdir/$CMANORA" 2>/dev/null
    sh -c "echo $'/(src=\n\Ec\$(src=${RULE_SRC})(dst=$key)(srv=${RULE_SRV})(act=${RULE_ACT})\E:x\n' | vi $logdir/$CMANORA" 2>/dev/null

done

if [ ! -z "${WALLET_LOCATION}" ]; then
   echo "$WALLET_TMPL_STR" >> $logdir/$CMANORA
   sed -i -e "s|###WALLET_LOCATION###|${WALLET_LOCATION}|g" $logdir/$CMANORA
fi

}

unsetrulevars()
{
unset RULE_SRC
unset RULE_DST
unset RULE_SRV
unset RULE_ACT
}

deleterule()
{

export CMANRULE="(src=${RULE_SRC})(dst=${RULE_DST})(srv=${RULE_SRV})(act=${RULE_ACT})"
CMANRULE=`echo $CMANRULE | sed -e 's/\*/\\\*/g'`

print_message "CMAN Rule to delete=[$CMANRULE]"
cp $DB_HOME/network/admin/$CMANORA $logdir/$CMANORA
grep "$CMANRULE" $logdir/$CMANORA > /dev/null
if [ $? -ne 0 ]; then
     error_exit "cman rule ${CMANRULE} not found in cman config file $logdir/$CMANORA. Exiting."
fi

sh -c "echo $'/${CMANRULE}\n\Ek0\Emk%d\'k\E:x\n' | vi $logdir/$CMANORA" 2>/dev/null

cp -f $logdir/$CMANORA $DB_HOME/network/admin/

reload_cman

return 0
}

copycmanora ()
{
mkdir -p $DB_HOME/network/admin/
sleep 2
cp $logdir/$CMANORA $DB_HOME/network/admin/
chown -R oracle:oinstall $DB_HOME/network/admin/
#rm -f $logdir/$CMANORA
}

reload_cman ()
{
local cmd
cmd="$DB_HOME/bin/cmctl reload -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN"
eval $cmd
}

start_cman ()
{
local cmd
export ORACLE_HOME=$DB_HOME
cmd="$DB_HOME/bin/cmctl startup -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN"
eval $cmd
}

stop_cman ()
{
local cmd
cmaninst=$1
export ORACLE_HOME=$DB_HOME
cmd="$DB_HOME/bin/cmctl shutdown -c $cmaninst"
eval $cmd
}

status_cman ()
{
local cmd
export ORACLE_HOME=$DB_HOME
cmd="$DB_HOME/bin/cmctl show service -c CMAN_$PUBLIC_HOSTNAME.$DOMAIN"
eval $cmd

if [ $? -eq 0 ];then
print_message "cman [CMAN_$PUBLIC_HOSTNAME.$DOMAIN] started sucessfully"
else
   if [ -z "${CMAN_DEBUG}" ]; then
      error_exit "Cman [CMAN_$PUBLIC_HOSTNAME.$DOMAIN] startup failed. Exiting"
   else
      print_message "Cman [CMAN_$PUBLIC_HOSTNAME.$DOMAIN] startup failed. Debug mode"
      tail -f /tmp/orod.log
   fi
fi
}


###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

########
#clear_files

while [ $# -gt 0 ]; do
    case "$1" in
       -addrule)
            action="add"
            ;;
       -delrule)
            action="delete"
            ;;
       -e)
             # envdetail="${1#*=}"
             shift
             envdetail="$1"
             envname=$(echo $envdetail | cut -d"=" -f 1)
             envval=$(echo $envdetail | cut -d"=" -f 2-)
             echo "name=[$envname]. val=[$envval]"
             export $envname=$envval
             ;;
       *)
            error_exit "* Error: Invalid argument [$1] specified.*\n"
    esac
    shift
done

####### Populating resolv.conf and /etc/hosts ###
setupEtcResolvConf
SetupEtcHosts
####################


if [ "$action" == "delete" ]; then
     del_rule_details=`echo ${RULEDETAILS} | sed -e 's/.*?=\(.*\)/\1/g'`
     IFS=':' read  -a del_rule_vars <<< "${del_rule_details}"
     unsetrulevars
     for del_rule_var in "${del_rule_vars[@]}"
     do
# shellcheck disable=SC2163
         echo "export ${del_rule_var}"
# shellcheck disable=SC2163
         export ${del_rule_var}
     done

     check_rule_env_vars
     deleterule

     exit 0

fi

if [ ! -z "${USER_CMAN_FILE}" ]; then
   if [ ! -f "${USER_CMAN_FILE}" ]; then
        error_exit "User supplied cman.ora file [${USER_CMAN_FILE}] not found. Exiting CMAN-Setup."
   else
        print_message "Using the user defined cman.ora file=[${USER_CMAN_FILE}]"
        ${CP} ${USER_CMAN_FILE} $logdir/$CMANORA
   fi
else
   all_check
   print_message "Generating CMAN file"
   cman_file
fi

print_message "Copying CMAN file to $DB_HOME/network/admin"
copycmanora
print_message "Starting CMAN"
start_cman
print_message "Reloading CMAN"
reload_cman
print_message "Checking CMAN Status"
status_cman
print_message "################################################"
print_message " CONNECTION MANAGER IS READY TO USE!            "
print_message "################################################"