# Use Oracle 19c image as the base
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Set environment variables
ENV ORACLE_SID=DEV
ENV ORACLE_PDB=PDB1
ENV PATH=$ORACLE_HOME/bin:$PATH


USER root
# Install Java 11 OpenJDK
RUN yum install -y java-11-openjdk-devel

# Copy the APEX installation files to the container
COPY tmp/apex /opt/oracle/apex
COPY tmp/apex/images /opt/oracle/apex/images

# Copy scripts to configure APEX and ORDS
COPY setup_apex.sh /opt/oracle/scripts/setup/

# Expose necessary ports
EXPOSE 1521 8080 8443

# Make scripts executable
USER root
RUN chmod +x /opt/oracle/scripts/setup/setup_apex.sh

# Run the Oracle Database setup and the APEX setup scripts
USER oracle

# Default command to start the Oracle Database and APEX setup
CMD ["/bin/bash", "/opt/oracle/scripts/setup/setup_apex.sh"]

