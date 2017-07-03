# Use an official Tuxedo runtime as a base image
FROM oracle/tuxedotma:12.2.2
# Add TMA cases to container, this tar ball will automatically be extracted by ADD command
ADD tma_case.tar.gz /home/oracle/
# Set user to ROOT
USER root
# Base image doesn't include ksh, make and x3270 add them, required by TMA sample cases
RUN yum -y install ksh make x3270; yum -y clean all
# Change owner
RUN chown oracle:oracle -R /home/oracle/
# Set user to oracle
USER oracle
# Set working directory
WORKDIR /home/oracle
# Used by TMA sample cases
ENV PATH=.:$PATH
ENV LOGNAME=oracle
