# Use a base image passed as a build argument
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Set environment variables
ENV ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
ENV PATH=$ORACLE_HOME/bin:$PATH
ENV ORDS_HOME=/opt/oracle/ords
ENV CONFIG_DIR=/etc/ords/config


# Copy the ORDS files into the container
COPY tmp $ORDS_HOME
COPY ords_params.properties $CONFIG_DIR/
COPY gen_pool_xml.sh $CONFIG_DIR/


USER root
# Install Java 11 OpenJDK
RUN yum install -y java-11-openjdk-devel

# Add ORDS bin directory to PATH
RUN echo 'export PATH="$PATH:$ORDS_HOME/bin"' >> ~/.bashrc

# Create the configuration directory
RUN mkdir -p $CONFIG_DIR

# Provide database connection details and other configurations
RUN echo "db.hostname=192.168.4.48" > $CONFIG_DIR/ords_params.properties && \
    echo "db.port=1521" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.servicename=DEV" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.username=sys" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.password=SysPassw0rd" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.apex.password=ApexPassw0rd" >> $CONFIG_DIR/ords_params.properties && \
    echo "db.ords.password=OrdsPassw0rd" >> $CONFIG_DIR/ords_params.properties && \
    echo "feature.sdw=true" >> $CONFIG_DIR/ords_params.properties && \
    echo "feature.db-api=true" >> $CONFIG_DIR/ords_params.properties && \
    echo "feature.restEnabledSql=true" >> $CONFIG_DIR/ords_params.properties && \
    echo "plsql.gateway.add=true" >> $CONFIG_DIR/ords_params.properties && \
	echo "plsql.gateway.mode=proxied" >> $CONFIG_DIR/ords_params.properties && \
    echo "rest.services.enabled=true" >> $CONFIG_DIR/ords_params.properties

# Install ORDS using the new CLI with non-interactive parameters
RUN cd $ORDS_HOME && \
    ./bin/ords --config $CONFIG_DIR install \
       --log-folder ${ORDS_CONF}/logs \
       --admin-user SYS \
       --db-hostname 192.168.4.48 \
       --db-port 1521 \
       --db-servicename DEV \
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

# Run the gen_pool_xml.sh script
RUN cd $CONFIG_DIR && \
    bash ./gen_pool_xml.sh

# Optional: Clean up by removing the script if no longer needed
RUN rm $CONFIG_DIR/gen_pool_xml.sh


# Expose the ORDS port
EXPOSE 8080

# Start ORDS using the new CLI
CMD ["sh", "-c", "$ORDS_HOME/bin/ords --config $CONFIG_DIR serve"]
