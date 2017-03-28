exit_after_time() {
  if [ "$DEBUG_MODE" = true ];then
    return
  else
    time=${1-120}
  fi
  echo "Exit after $time seconds..."
  sleep $time
  exit 1
}

wait_for_remote_db() {
  COUNT=0
  CHECKCMD="tcpvalidbash $DB_HOST $DB_PORT"
  while :;do
    CHECKOUTPUT=`$CHECKCMD`
    if [ "$CHECKOUTPUT" = y ];then
      if [ $COUNT -gt 0 ];then
        echo "INFO: Destination $DB_HOST:$DB_PORT is reachable now."
      fi
      break;
    fi
    RECHECK=y
    sleep 3
    COUNT=`expr $COUNT + 1`
    echo "INFO: Destination $DB_HOST:$DB_PORT is not reachable, check later..."
    if [ "$COUNT" = 12 ];then
      echo "ERROR: Destination $DB_HOST:$DB_PORT is not reachable, exit"
      exit_after_time
    fi
  done
  if [ "$RECHECK" = y ];then
    echo "Waiting for DB instance to boot up ..."
    sleep 30
  fi
}

verify_env_var() {
  var=$1
  desc=$2
  varvalue="$(eval echo \$$var)"
  if [ "$DEBUG_MODE" = true ];then
    echo "$var=$varvalue"
  fi
  if [ -z "$varvalue" ];then
    if [ -n "$desc" ];then
      msg="for $desc"
    fi
    echo "ERROR: environment variable $var $msg is required, exit."
    exit_after_time
  fi
}

verify_tsam_db() {
  SQL_OUTPUT=$(SQL="select 1 VERIFY_RESULT from dual;" ~/instantclient/sqlrun.sh | sed "/^$/d")
  title=$(echo "$SQL_OUTPUT"|sed -n 1p)
  value=$(echo "$SQL_OUTPUT"|sed -n 3p)
  if [ "$title" = VERIFY_RESULT ] && [ "$value" -eq 1 ];then
    if [ "$DEBUG_MODE" = true ];then
      echo "$SQL_OUTPUT"
      echo ""
    fi
    DB_SID=$(SQL="select instance from v\$thread;" ~/instantclient/sqlrun.sh | sed "/^$/d" | sed -n 3p)
    echo "DB_SID=$DB_SID" > ~/.dbinfo
  else
    echo "WARNING: Invalid DB connection information provided for user \"$DB_TSAM_USER\"."
    if [ "$DEBUG_MODE" = true ];then
      echo "$SQL_OUTPUT"
      echo ""
    fi
    return 1
  fi
}

verify_sys_db() {
  SQL_OUTPUT=$(DBA_MODE=y SQL="select 1 VERIFY_RESULT from dual;" ~/instantclient/sqlrun.sh | sed "/^$/d")
  title=$(echo "$SQL_OUTPUT"|sed -n 1p)
  value=$(echo "$SQL_OUTPUT"|sed -n 3p)
  if [ "$title" = VERIFY_RESULT ] && [ "$value" -eq 1 ];then
    if [ "$DEBUG_MODE" = true ];then
      echo "$SQL_OUTPUT"
      echo ""
    fi
    DB_SID=$(DBA_MODE=y SQL="select instance from v\$thread;" ~/instantclient/sqlrun.sh | sed "/^$/d" | sed -n 3p)
    echo "DB_SID=$DB_SID" > ~/.dbinfo
    return 0
  else
    echo "ERROR: Invalid DB connection information provided for user $DBA_USER, error message:"
    echo "$SQL_OUTPUT"
    echo ""
    return 1
  fi
}

verify_remote_db() {
  verify_env_var DB_TSAM_USER
  verify_env_var DB_TSAM_PASSWD
  verify_tsam_db
  if [ $? != 0 ];then
    echo "INFO: Couldn't connect with TSAM DB user \"$DB_TSAM_USER\", validating DBA user..."
    verify_env_var DBA_USER
    verify_env_var DBA_PASSWD
    verify_env_var DB_TSAM_TBLSPACE
    verify_env_var TSAM_CONSOLE_ADMIN_PASSWD
    verify_sys_db > /dev/null 2>&1
    if [ $? != 0 ];then
      tmpfile=/tmp/tmp.log
      echo "Waiting for DB instance to boot up ..."
      sleep 15
      COUNT=0
      while :;do
        verify_sys_db > $tmpfile 2>&1
        if [ $? = 0 ];then
          echo ""
          break;
        fi
        COUNT=`expr $COUNT + 1`
        if [ "$COUNT" = 20 ];then
          cat $tmpfile
          echo ""
          echo "Oracle DB failed to boot up, exit."
          exit_after_time
        fi
        echo .
        sleep 15
      done
    fi

    user_output=`DBA_MODE=y SQL="select username from dba_users;" ~/instantclient/sqlrun.sh | grep -i "^${DB_TSAM_USER}$"`
    if [ -n "$user_output" ];then
      echo "ERROR: TSAM DB user \"$DB_TSAM_USER\" already exists, please provide correct login credentials."
      exit_after_time
    fi

    DB_TYPE=new
  else
    DB_TYPE=existing
  fi
}

app_svr_deploy() {
  echo ""
  cd $DEPLOY

  mkdir e && cd e
  jar xf ../tsam_wls12c.ear
  mkdir t && cd t
  jar xf ../tsam.war
  sed -i "s?\\\$USER_INSTALL_DIR\\\$?/opt/tsam/tsam12.2.2.0.0?g" WEB-INF/web.xml
  jar cf ../tsam.war *
  cd .. && rm -rf t
  jar cf ../tsam_wls12c.ear *
  cd .. && rm -rf e

  admport=${ADMIN_PORT-7001}
  ./AppServerDeployer.sh -type weblogic -adminurl t3://localhost:$admport -directory $WLHOME/wlserver -user weblogic -password weblogic1
  if [ $? != 0 ];then
    echo "ERROR deploying TSAM Plus Manager application, exit."
    exit_after_time
  else
    touch ~/.appdeployed
  fi
}
