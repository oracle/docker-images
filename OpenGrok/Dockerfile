FROM tomcat:9-jre8
MAINTAINER Nathan Guimaraes "dev.nathan.guimaraes@gmail.com"

#PREPARING OPENGROK BINARIES AND FOLDERS
ADD https://github.com/OpenGrok/OpenGrok/releases/download/1.0/opengrok-1.0.tar.gz /opengrok.tar.gz
RUN tar -zxvf /opengrok.tar.gz && mv opengrok-* /opengrok && chmod -R +x /opengrok/bin
RUN mkdir /src
RUN mkdir /data
RUN ln -s /data /var/opengrok
RUN ln -s /src /var/opengrok/src

#INSTALLING DEPENDENCIES
RUN apt-get update && apt-get install -y exuberant-ctags git subversion mercurial unzip openssh-server cron inotify-tools

#SSH configuration
RUN mkdir /var/run/sshd
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/[ #]*PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/[ #]*UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

# CRON for Reindex configuration
RUN echo "*/10 * * * * root  /scripts/index.sh" > /etc/cron.d/opengrok-cron
RUN chmod 0644 /etc/cron.d/opengrok-cron

#ENVIRONMENT VARIABLES CONFIGURATION
ENV SRC_ROOT /src
ENV DATA_ROOT /data
ENV OPENGROK_TOMCAT_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
ENV PATH /opengrok/bin:$PATH
ENV CATALINA_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV CATALINA_TMPDIR /usr/local/tomcat/temp
ENV JRE_HOME /usr
ENV CLASSPATH /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar

WORKDIR $CATALINA_HOME
RUN /opengrok/bin/OpenGrok deploy

EXPOSE 8080
EXPOSE 22

ADD scripts /scripts
RUN chmod -R +x /scripts
CMD ["/scripts/start.sh"]
