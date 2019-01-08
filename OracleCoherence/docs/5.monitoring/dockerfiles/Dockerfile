# LICENSE UPL 1.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Coherence 12.2.1 using JMXMP for JMX management
#
# REQUIRED BASE IMAGE TO BUILD THIS IMAGE
# ---------------------------------------
# This Dockerfile requires the base image oracle/coherence:12.2.1.3.0-standalone
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sh buildDockerImage.sh -s
#
# or if your Docker client requires root access you can run:
#      $ sudo sh buildDockerImage.sh -s
#
FROM oracle/coherence:12.2.1.3.0-standalone

ADD coherence-examples-jmx-1.0-SNAPSHOT.jar       /lib/coherence-examples-jmx-1.0-SNAPSHOT.jar
ADD opendmk_jmxremote_optional_jar-1.0-b01-ea.jar /lib/opendmk_jmxremote_optional_jar-1.0-b01-ea.jar

