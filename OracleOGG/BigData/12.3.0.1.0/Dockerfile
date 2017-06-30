FROM oraclelinux:7-slim
MAINTAINER OGG QA <hadi.koesnodihardjo@oracle.com>
#Container Additional Environment Variables
ENV OGG_SHIPHOME=V839824-01.zip \
    OGG_HOME=/u01/app/oracle/product/12.3.0.1.0/oggbd_1 \
    OGG_PORT=1700 \
    STAGE_SOFTWARE=/u01/software
ENV PATH=.:$PATH:$OGG_HOME \
    LD_LIBRARY_PATH=.:./lib:/usr/lib/jvm/jre/lib/amd64/server:$OGG_HOME:$LD_LIBRAY_PATH
#Command during the build
RUN yum install -y java-1.8.0-openjdk vim-minimal util-linux.x86_64 zip unzip tar && yum clean all
#OGG SHIPHOME
RUN mkdir -p $OGG_HOME $STAGE_SOFTWARE
ADD entrypoint.sh /
ADD $OGG_SHIPHOME $STAGE_SOFTWARE
#Copy any artifacts to the image
EXPOSE $OGG_PORT
ENTRYPOINT /entrypoint.sh
