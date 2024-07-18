#!/bin/bash

# Function to check if the listener and database are up
check_db_ready() {
  local DB_USER="sys"
  local DB_PASSWORD="SysPassw0rd"
  local DB_HOST="192.168.4.42"
  local DB_PORT="1521"
  local DB_SERVICE="DEV"

  while true; do
    echo "exit" | sqlplus -s "$DB_USER/$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_SERVICE as sysdba" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Listener and database are up and ready."
      break
    else
      echo "Waiting for listener and database to be ready..."
      sleep 10
    fi
  done
}

# Call the function to check if the database and listener are up
check_db_ready
