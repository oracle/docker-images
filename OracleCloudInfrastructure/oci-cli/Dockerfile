FROM oraclelinux:8

RUN dnf update -y && \
    dnf install -y oraclelinux-developer-release-el8 && \
    dnf install -y python36-oci-cli

RUN groupadd -r oracle && \
    useradd -r -g oracle oracle

USER oracle

WORKDIR /home/oracle
