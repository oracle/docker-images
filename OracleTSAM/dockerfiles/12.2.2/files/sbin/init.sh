#!/bin/bash
source ~/sbin/functions.sh

if [ ! -f /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh ];then
  REMOTE_ONLY=y
else
  REMOTE_ONLY=n
fi

cd ~/scripts && . ./setenv.sh

if [ -n "$DB_CONNSTR" ];then # external oracle database
  IFS='/' read -a arr <<< "$DB_CONNSTR"
  arrlen=${#arr[@]}
  if [ $arrlen -ne 2 ];then
    echo "Invalid DB connection string, expected format: <hostname>:<port>/<service_name>"
    exit_after_time
  fi
  DB_HOST=$(echo ${arr[0]}|awk -F: '{print $1}')
  DB_PORT=$(echo ${arr[0]}|awk -F: '{print $2}')
  DB_SVCNAME=${arr[1]}
  export DB_HOST DB_PORT DB_SVCNAME
  if [ -z "$DB_PORT" ];then DB_PORT=1521; fi

  wait_for_remote_db

  verify_remote_db

  cd $DEPLOY
  if [ -z "$DB_ENABLE_PARTITION" ];then DB_ENABLE_PARTITION=no; fi

  source ~/.dbinfo
  export DB_SID

  inv_info=$(/u01/oracle/oraHome/OPatch/opatch lsinv)
  if [ "$DEBUG_MODE" = true ];then
    echo "$inv_info"
  fi
  if [ -z "`echo $inv_info|grep 25832345`" ];then
    COMMON_ARGS="-type oracle \
      -hostname $DB_HOST \
      -port $DB_PORT \
      -dbname $DB_SID \
      -user $DB_TSAM_USER \
      -password $DB_TSAM_PASSWD \
      -overwrite no \
      -adminpassword $TSAM_CONSOLE_ADMIN_PASSWD \
      -enable_partition $DB_ENABLE_PARTITION"
  else
    COMMON_ARGS="-type oracle \
      -url jdbc:oracle:thin:@//$DB_CONNSTR \
      -user $DB_TSAM_USER \
      -password $DB_TSAM_PASSWD \
      -overwrite no \
      -adminpassword $TSAM_CONSOLE_ADMIN_PASSWD \
      -enable_partition $DB_ENABLE_PARTITION"
  fi

  if [ "$DEBUG_MODE" = true ];then
    echo $COMMON_ARGS
  fi

  if [ "$DB_TYPE" = existing ];then
    if [ -z "$TSAM_CONSOLE_ADMIN_PASSWD" ];then
      TSAM_CONSOLE_ADMIN_PASSWD=dummy;
    fi
    ./DatabaseDeployer.sh $COMMON_ARGS
  else # DB_TYPE = new
    ./DatabaseDeployer.sh $COMMON_ARGS \
    -dbSysdbaUser $DBA_USER \
    -dbSysdbaPwd $DBA_PASSWD \
    -tsamDbTablespace $DB_TSAM_TBLSPACE
  fi

  if [ $? != 0 ];then
    echo "ERROR initializing TSAM Manager database, exit."
    exit_after_time
  fi
else # embedded oracle xe database
  if [ "$REMOTE_ONLY" = y ];then
    echo "ERROR: Remote DB connection information is required, exit."
    exit_after_time
  fi

  # not provided in this version
fi

# Create new wls domain
echo ""
echo "New WebLogic domain is about to be created, verifying required environment variables..."
verify_env_var WLS_PW "Admin password"
$WLHOME/oracle_common/common/bin/wlst.sh ~/scripts/wls-ds-create.py

colormsg YELLOW Starting WLS domain ...

cd $WLDOM
if [ -z "$WLS_USER" ];then
  export WLS_USER=weblogic
fi
nohup ./startWebLogic.sh > wls.log 2>&1 &
sleep 5
waitfile $WLDOM/wls.log "Server state changed to RUNNING" 5 1200 n

if [ "$DEBUG_MODE" = true ];then
  netstat -an|grep 7001
  cat $WLDOM/wls.log
fi

cd $DEPLOY
./DatabaseDeployer.sh -wlsdsJNDIname jdbc/tsamds

APP_DEPLOYED=n
if [ -e ~/.appdeployed ];then APP_DEPLOYED=y; fi
if [ "$APP_DEPLOYED" = n ];then
  app_svr_deploy
fi

if [ "$DEBUG_MODE" = true ] && [ -n "$DEBUG_CMD" ];then
  bash -c "$DEBUG_CMD"
fi

tail -f /dev/null

