FROM oraclelinux:7-slim

ARG TERRAFORM_VERSION
ARG OCI_PROVIDER_VERSION

RUN yum-config-manager --enable ol7_developer \
   && yum -y install terraform${TERRAFORM_VERSION} terraform-provider-oci${OCI_PROVIDER_VERSION} \
   && rm -rf /var/cache/yum/*

VOLUME ["/data"]
WORKDIR /data

CMD ["/bin/bash"]
