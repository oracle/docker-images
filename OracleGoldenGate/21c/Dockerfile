## Copyright (c) 2021, Oracle and/or its affiliates.
FROM          oraclelinux:8-slim
LABEL         maintainer="Stephen Balousek<stephen.balousek@oracle.com>"

ARG           INSTALLER
RUN           : ${INSTALLER:?}

ENV           OGG_HOME               "/u01/ogg"
ENV           OGG_DEPLOYMENT_HOME    "/u02"
ENV           OGG_TEMPORARY_FILES    "/u03"
ENV           PATH                   "${OGG_HOME}/bin:${PATH}"

COPY          install-*.sh      /tmp/
COPY          ${INSTALLER}      /tmp/installer.zip
COPY          bin/              /usr/local/bin/

RUN           bash -c  /tmp/install-prerequisites.sh && \
              bash -c  /tmp/install-deployment.sh    && \
              rm   -fr /tmp/*   /etc/nginx

COPY          nginx/            /etc/nginx/

EXPOSE        443
VOLUME      [ "${OGG_DEPLOYMENT_HOME}", "${OGG_TEMPORARY_FILES}" ]
HEALTHCHECK   --start-period=90s --retries=1 \
        CMD [ "/usr/local/bin/healthcheck" ]
ENTRYPOINT  [ "/usr/local/bin/deployment-main.sh" ]
