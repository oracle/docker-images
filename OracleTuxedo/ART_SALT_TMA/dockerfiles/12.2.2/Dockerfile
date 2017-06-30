# Use an official Tuxedo runtime as a base image
FROM oracle/tuxedoartrt:12.2.2
# The ARG instruction defines a variable that users can pass at build-time to the builder with the docker build command using the --build-arg <varname>=<value> flag. 
# TMA SNA needs Tuxedo RP003 before installation.
ARG tuxedo_rp
# Copy all the files needed by the installation to the container
COPY install_tmasna.sh tmasna12.2.2.rsp tmasna122200_64_linux_x86_64.zip install_tmatcp.sh tmatcp12.2.2.rsp tmatcp122200_64_linux_x86_64.zip $tuxedo_rp install_tuxedorp.sh /home/oracle/Downloads/
# Change user to oracle to install TMA
USER oracle
# Set working directory
WORKDIR /home/oracle/Downloads
# TUXDIR environment variable is needed before installation
ENV ORACLE_HOME=/home/oracle/tuxHome
ENV TUXDIR /home/oracle/tuxHome/tuxedo12.2.2.0.0
# Install Tuxedo RP
RUN sh install_tuxedorp.sh $tuxedo_rp
# Install TMA SNA
RUN sh install_tmasna.sh
# Install TMA TCP
RUN sh install_tmatcp.sh
# Clean up installer files
RUN rm -f *.zip install_*.sh tma*.rsp
# Set working directory
WORKDIR /home/oracle
