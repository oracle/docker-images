#!PowerShell
docker build -t oracle/serverjre:7-windowsservercore -f windowsservercore/Dockerfile .
docker build -t oracle/serverjre:7-nanoserver -f nanoserver/Dockerfile .
