Oracle Java on Docker
=====
Build a Docker image containing Oracle Java (Server JRE specifically).

The Oracle Java Server JRE provides the same features as Oracle Java JDK commonly required for Server-side Applications (i.e. Java EE application servers). For more information about Server JRE, visit the [Understanding the Server JRE](https://blogs.oracle.com/java-platform-group/understanding-the-server-jre) blog entry from the Java Product Management team.

## Java 8
[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) `.tar.gz` file and drop it inside folder `java-8`. 
Build it:

```
$ cd java-8
$ docker build -t oracle/serverjre:8 .
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
