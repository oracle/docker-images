#!/bin/bash
#START METHOD FOR INDEXING OF OPENGROK
start_opengrok(){
    # wait for tomcat startup
    date +"%R Waiting for tomcat startup..">>/opengrok/indexing.log
    while ! ( grep -q "org.apache.catalina.startup.Catalina.start Server startup"  /usr/local/tomcat/logs/catalina.*.log ); do
        sleep 1;
    done
    date +"%R Startup finished..">>/opengrok/indexing.log
    /scripts/index.sh
}

#START ALL NECESSARY SERVICES.	
start_opengrok & 
catalina.sh run &
cron &
/usr/sbin/sshd -D
