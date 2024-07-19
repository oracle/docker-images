# Use a base image passed as a build argument
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DB_HOST
ARG DB_PORT
ARG DB_SERVICE
ARG DB_USER
ARG DB_PASSWORD
ARG ORDS_DB_API
ARG ORDS_REST_ENABLED_SQL
ARG ORDS_SDW
ARG ORDS_GATEWAY_MODE
ARG ORDS_GATEWAY_USER
ARG ORDS_PROXY_USER
ARG ORDS_PASSWORD_SYS
ARG ORDS_PASSWORD_APEX



# Set environment variables
ENV ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
ENV PATH=$ORACLE_HOME/bin:$PATH
ENV ORDS_HOME=/opt/oracle/ords
ENV CONFIG_DIR=/etc/ords/config

ENV DB_HOST=$DB_HOST
ENV DB_PORT=$DB_PORT
ENV DB_SERVICE=$DB_SERVICE
ENV DB_USER=$DB_USER
ENV DB_PASSWORD=$DB_PASSWORD
ENV ORDS_DB_API=$ORDS_DB_API
ENV ORDS_REST_ENABLED_SQL=$ORDS_REST_ENABLED_SQL
ENV ORDS_SDW=$ORDS_SDW
ENV ORDS_GATEWAY_MODE=$ORDS_GATEWAY_MODE
ENV ORDS_GATEWAY_USER=$ORDS_GATEWAY_USER
ENV ORDS_PROXY_USER=$ORDS_PROXY_USER
ENV ORDS_PASSWORD_SYS=$ORDS_PASSWORD_SYS
ENV ORDS_PASSWORD_APEX=$ORDS_PASSWORD_APEX

# Copy the ORDS files into the container
COPY tmp $ORDS_HOME
COPY ords_params.properties $CONFIG_DIR/


USER root
# Install Java 11 OpenJDK
RUN yum install -y java-11-openjdk-devel

# Add ORDS bin directory to PATH
RUN echo 'export PATH="$PATH:$ORDS_HOME/bin"' >> ~/.bashrc

# Create the configuration directory
RUN mkdir -p $CONFIG_DIR

# Provide database connection details and other configurations
RUN echo "db.hostname=$DB_HOST" > $CONFIG_DIR/ords_params.properties && \
    echo "db.port=$DB_PORT" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.servicename=$DB_SERVICE" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.username=$DB_USER" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.password=$DB_PASSWORD" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.apex.password=$ORDS_PASSWORD_APEX" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.ords.password=$ORDS_PASSWORD_SYS" >> $CONFIG_DIR/ords_params.properties && \
    echo "feature.sdw=$ORDS_SDW" >> $CONFIG_DIR/ords_params.properties && \
    echo "feature.db-api=$ORDS_DB_API" >> $CONFIG_DIR/ords_params.properties && \
    echo "feature.restEnabledSql=$ORDS_REST_ENABLED_SQL" >> $CONFIG_DIR/ords_params.properties && \
    echo "plsql.gateway.add=true" >> $CONFIG_DIR/ords_params.properties && \
	echo "plsql.gateway.mode=$ORDS_GATEWAY_MODE" >> $CONFIG_DIR/ords_params.properties && \
    echo "rest.services.enabled=ORDS_REST_ENABLED_SQL" >> $CONFIG_DIR/ords_params.properties

# Install ORDS using the new CLI with non-interactive parameters
RUN cd $ORDS_HOME && \
    ./bin/ords --config $CONFIG_DIR install \
       --log-folder ${ORDS_CONF}/logs \
       --admin-user $DB_USER \
       --db-hostname $DB_HOST \
       --db-port $DB_PORT \
       --db-servicename $DB_SERVICE \
       --feature-db-api true \
       --feature-rest-enabled-sql true \
       --feature-sdw true \
       --gateway-mode proxied \
       --gateway-user APEX_PUBLIC_USER \
       --proxy-user \
       --password-stdin <<EOF
SysPassw0rd
ApexPassw0rd
EOF

RUN sed -i 's|<entry key="plsql.gateway.mode">disabled</entry>|<entry key="plsql.gateway.mode">proxied</entry>|g' /etc/ords/config/databases/default/pool.xml


# Start ORDS using the new CLI
CMD ["sh", "-c", "$ORDS_HOME/bin/ords --config $CONFIG_DIR serve"]
