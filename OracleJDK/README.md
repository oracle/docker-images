Oracle JDK on Docker
=====
Build a Docker image containing Oracle JDK (Server JRE specifically):

## Java 8
[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) and drop the file inside folder `java-8`. 
Build it:

```
$ cd java-8
$ docker build -t oracle/jdk:8 .
```

## Java 7
[Download Server JRE 7](http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase7-521261.html#sjre-7u80-oth-JPR) and drop the file inside folder `java-7`:
Build it: 

```
$ cd java-7
$ docker build -t oracle/jdk:7 .
```
