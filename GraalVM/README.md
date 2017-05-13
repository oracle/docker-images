# GraalVM

Graal is a new just-in-time (JIT) compiler for the JVM focused on peak performance and multi-language support.
Graal offers performance advantages not only to Java code, but also to dynamically typed languages such as JavaScript, Ruby, and R.

Additionally, it enables the execution of native code on the JVM via an LLVM-based front end (project [Sulong](https://github.com/graalvm/sulong)).

Languages are executed by Graal via the Truffle framework, which comes with seamless language interoperability, and polyglot debugging and profiling.

## Building the Docker image

The GraalVM image requires you to download the binary tarball from http://www.oracle.com/technetwork/oracle-labs/program-languages/downloads/index.html and place it into the `graalvm-0.22` directory prior to running `build.sh` or `docker build`.

## Usage

GraalVM requires the `JAVA_HOME` environment variable to point to a JVMCI enabled Java Development Kit or Java Runtime. This is automatically configured by the `Dockerfile`.

[Oracle Labs JDK](http://www.oracle.com/technetwork/oracle-labs/program-languages/downloads/index.html) is a JVMCI enabled version of JDK 8 which is included in the Docker image and is used to run GraalVM.

The bin directory contains:
* `java` - Runs the JVM with Graal as the default dynamic compiler for Java.
* `graalvm` - Runs the JVM in polyglot mode with JavaScript, Ruby, and R as available languages.
* `js` - Runs a JavaScript console with Graal.js.
* `node` - Drop-in replacement for node.js with Graal.js as the executing JavaScript engine.
* `ruby` - Drop-in replacement for MRI Ruby with TruffleRuby as the executing Ruby engine.
* `R` - Drop-in replacement for GNU R with FastR as the executing R engine.
* `aot-image` - Builds an ahead-of-time compiled executable or a shared library from Java programs, and the JavaScript and Ruby languages.

To get started look at example applications and the README description in the `/opt/graalvm-0.22/examples` folder.

## Benefits

* Performance - Graal incorporates our research on compiler technology, and offers better peak performance on average than a traditional JVM.
* Polyglot - Java, JavaScript, Ruby, and R are all available at competitive performance within the same execution environment.
* Interoperability - Programs written in different languages can call each other and each other's libraries without overhead.
* Embeddability - Embed dynamic languages into native code with sandboxing capabilities.
* Tooling - Graal benefits from JVM-based tooling and all languages share common tooling such as debugging and profiling.

## Learn more

The COPYRIGHT, LICENSE and README files for those languages are in the `/opt/graalvm-0.22/language` folder of this image.

You can learn more about GraalVM on Oracle Technology Network [here](http://www.oracle.com/technetwork/oracle-labs/program-languages/overview/index.html).

