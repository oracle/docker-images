#!/bin/sh
if [ ! -d jdk1.7.0_80 ]; then
  tar xzf server-jre-7u80-windows-x64.tar.gz
fi
docker build -t oracle/serverjre:7-windowsservercore -f windowsservercore/Dockerfile .
docker build -t oracle/serverjre:7-nanoserver -f nanoserver/Dockerfile .
