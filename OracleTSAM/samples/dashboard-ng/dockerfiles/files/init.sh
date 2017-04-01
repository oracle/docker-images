#!/bin/bash
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

verify_env_var() {
  var=$1
  varvalue="$(eval echo \$$var)"
  if [ "$DEBUG_MODE" = true ];then
    echo "$var=$varvalue"
    echo ""
  fi
  if [ -z "$varvalue" ];then
    echo "ERROR: environment variable $var is required, exit."
    exit_after_time
  fi
}

if [ -n "$SSH_PUBKEY" ];then
  echo "$SSH_PUBKEY" >> ~/.ssh/authorized_keys
fi

if [ "$DEBUG_MODE" = true ] && [ -n "$DEBUG_CMD" ];then
  bash -c "$DEBUG_CMD"
fi

cd ~/app && ./start_domain.sh
sleep 5
nohup ./runload.sh > runload.out 2>&1 &

tail -f /dev/null

