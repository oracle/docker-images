FROM oraclelinux:7
ARG VERSION_JDK
ARG VERSION_GSC
COPY ./jdk-${VERSION_JDK}_linux-x64_bin.rpm /tmp
COPY ./oracle-graph-${VERSION_GSC}.x86_64.rpm /tmp
RUN yum install -y unzip numactl vim python3 openssl \
 && yum clean all \
 && rm -rf /var/cache/yum/* \
 && rpm -ivh /tmp/jdk-${VERSION_JDK}_linux-x64_bin.rpm \
 && rpm -ivh /tmp/oracle-graph-${VERSION_GSC}.x86_64.rpm
ENV JAVA_HOME=/usr/java/jdk-${VERSION_JDK}
ENV PATH=$PATH:/opt/oracle/graph/bin
ENV SSL_CERT_FILE=/etc/oracle/graph/ca_certificate.pem
RUN keytool -import -trustcacerts \
    -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit \
    -alias pgx -file /etc/oracle/graph/ca_certificate.pem -noprompt \
 && pip3 install pyjnius
EXPOSE 7007
WORKDIR /opt/oracle/graph/bin
CMD ["sh", "/opt/oracle/graph/pgx/bin/start-server"]