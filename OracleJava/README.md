Oracle Java on Docker
=====
Build a Docker image containing Oracle Java (Server JRE specifically).

The Oracle Java Server JRE provides the same features as Oracle Java JDK commonly required for Server-side Applications (i.e. Java EE application servers). For more information about Server JRE, visit this [release notes](http://www.oracle.com/technetwork/java/javase/7u21-relnotes-1932873.html#serverjre).

## Java 8
[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) `.tar.gz` file and drop it inside folder `java-8`. 
Build it:

```
$ cd java-8
$ docker build -t oracle/serverjre:8 .
```

## Java 7
[Download Server JRE 7](http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase7-521261.html#sjre-7u80-oth-JPR) `.tar.gz` file and drop it inside folder `java-7`: 
Build it:

```
$ cd java-7
$ docker build -t oracle/serverjre:7 .
```
## Java 8 JDK
[Download Server JDK 8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) `.tar.gz` file and drop it inside folder `java-8-jdk`. 
Build it:

```
$ cd java-8-jdk
$ docker build -t oracle/serverjdk:8 .
```

## Windows

### Java 8
[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) `.tar.gz` file and drop it inside folder `windows-java-8`. 
Build it:

```
$ cd windows-java-8
$ docker build -t oracle/serverjre:8-windowsservercore -f windowsservercore/Dockerfile .
$ docker build -t oracle/serverjre:8-nanoserver -f nanoserver/Dockerfile .
```

### Java 7
[Download Server JRE 7](http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase7-521261.html#sjre-7u80-oth-JPR) `.tar.gz` file and drop it inside folder `windows-java-7`. You also have to extract all files as there are issues adding the `tar.gz` file directly. 
Build it:

```
$ cd windows-java-7
$ tar xzf server-jre-7u80-windows-x64.tar.gz
$ docker build -t oracle/serverjre:7-windowsservercore -f windowsservercore/Dockerfile .
$ docker build -t oracle/serverjre:7-nanoserver -f nanoserver/Dockerfile .
```
