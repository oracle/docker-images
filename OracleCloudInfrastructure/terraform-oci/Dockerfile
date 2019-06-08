FROM oraclelinux:7-slim

ARG TERRAFORM_VERSION
ARG OCI_PROVIDER_VERSION

RUN yum -y install oraclelinux-developer-release-el7 \
   && yum -y install terraform${TERRAFORM_VERSION} terraform-provider-oci${OCI_PROVIDER_VERSION} \
   && rm -rf /var/cache/yum/*

VOLUME ["/data"]
WORKDIR /data

CMD ["/bin/bash"]
