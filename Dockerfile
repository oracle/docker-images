FROM debian:jessie

RUN apt-get update && apt-get install -y \
		bison \
		build-essential \
		cmake \
		curl \
		libncurses5-dev

RUN mkdir /usr/src/mysql \
	&& curl -SL https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.17.tar.gz \
		| tar -xzC /usr/src/mysql --strip-components=1
#ADD . /usr/src/mysql

WORKDIR /usr/src/mysql

RUN cmake .
RUN make -j"$(nproc)"
RUN make test
RUN make install
ENV PATH $PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts

RUN groupadd mysql && useradd -r -g mysql mysql

WORKDIR /usr/local/mysql
VOLUME /var/lib/mysql
RUN rm -rf data && ln -s /var/lib/mysql data

ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld", "--datadir=/var/lib/mysql", "--user=mysql"]
