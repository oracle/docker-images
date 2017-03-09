#!/bin/powershell
docker build -t oracle/serverjre:8-windowsservercore -f windowsservercore/Dockerfile .
docker build -t oracle/serverjre:8-nanoserver -f nanoserver/Dockerfile .
