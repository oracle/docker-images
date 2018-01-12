FROM oraclelinux:7-slim

ARG TERRAFORM_VERSION=0.11.2-1.el7
ARG OCI_PROVIDER_VERSION=2.0.6-1.el7

RUN yum-config-manager --enable ol7_developer \
   && yum -y install terraform-${TERRAFORM_VERSION} terraform-provider-oci-${OCI_PROVIDER_VERSION} \
   && rm -rf /var/cache/yum/*

VOLUME ["/data"]
WORKDIR /data

CMD ["/bin/bash"]
