FROM oraclelinux:latest

## -- The environment variables set using ENV will persist when a container
## -- is run from the resulting image. -- ##

ENV PACKAGE_URL='https://repo.mysql.com/yum/mysql-5.7-community/docker/x86_64/mysql-community-server-minimal-5.7.5-0.3.m15.el7.x86_64.rpm'

# Install server
RUN yum localinstall -y \
  $PACKAGE_URL \
  && rm -rf /var/cache/yum/*

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]

