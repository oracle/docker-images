#!/bin/sh
set -e

export GOPATH=/go
export LOGSPOUT_VERSION=3.1
export LOGSPOUT_URL=https://github.com/gliderlabs/logspout/archive

apk upgrade
apk update
apk add curl jq
apk add --virtual .build-deps wget go git build-base

mkdir -p /go/src/github.com/gliderlabs

wget -O /tmp/v${LOGSPOUT_VERSION}.tar.gz \
  ${LOGSPOUT_URL}/v${LOGSPOUT_VERSION}.tar.gz && \
  tar xzf /tmp/v${LOGSPOUT_VERSION}.tar.gz \
    -C /go/src/github.com/gliderlabs && \
  ln -s /go/src/github.com/gliderlabs/logspout-${LOGSPOUT_VERSION} \
    /go/src/github.com/gliderlabs/logspout

cd /go/src/github.com/gliderlabs/logspout
go get -x
go build -v -ldflags "-X main.Version dev" -o /bin/logspout

apk del .build-deps
rm -rf /go
rm -rf /var/cache/apk/*
rm /tmp/v${LOGSPOUT_VERSION}.tar.gz
