# env from sanity.config
PROCEDURE=all;export PROCEDURE
CASE=all;export CASE
APP_ACTION='tuxedo';export APP_ACTION

# db info
DB=derby;export DB
DB_CONNECT='jdbc:derby://localhost:1528/TSAM';export DB_CONNECT
SYS_DB_CONNECT=;export SYS_DB_CONNECT
DB_HOSTNAME=localhost;export DB_HOSTNAME
DB_PORT=1528;export DB_PORT
DB_NAME=TSAM;export DB_NAME
DB_USER=app;export DB_USER
DB_PSW=app;export DB_PSW
DB_ADM_PSW=;export DB_ADM_PSW
TABLE_SPACE=;export TABLE_SPACE

APP_ROOT=$PWD;export APP_ROOT

TUX_VERSION=12.2.2.0.0;export TUX_VERSION
TSAM_VERSION=12.2.2.0.0;export TSAM_VERSION

ORACLE_HOME=/home/oracle/tuxHome;export ORACLE_HOME

TUXDIR=$ORACLE_HOME/tuxedo$TUX_VERSION;export TUXDIR
TSAM_DIR=$ORACLE_HOME/tsam$TUX_VERSION;export TSAM_DIR
ARTDIR=$ORACLE_HOME/art$TUX_VERSION;export ARTDIR

FILE_DIR=/nfs/users/beadev/tsam/sanity_tool_RP007_12cr2;export FILE_DIR
TUX_LEVEL=null;export TUX_LEVEL
TSAM_LEVEL=null;export TSAM_LEVEL
SANITY_HOST=localhost;export SANITY_HOST

APPDIR=$APP_ROOT/simpapp;export APPDIR
HOSTNAME=`uname -n`;export HOSTNAME
ORACLE_HOME_NAME=sanity_home; export ORACLE_HOME_NAME
MGR_HOSTNAME=tsam.box; export MGR_HOSTNAME

#this use for install tuxedo pack
PATH=/usr/vac/bin:/opt/ss11/SUNWspro/bin:/usr/local/packages/vac_remote/vac_9_March2011/usr/vac/bin:/usr/local/bin:$TUXDIR/bin:.:$APP_ROOT/java_tool:$PATH:$ORACLE_HOME/OPatch;export PATH
#/opt/ss11/SUNWspro/bin for slc03kqe
#/usr/vac/bin for bjaix4
TOMCAT_DIR=$TSAM_DIR/apache-tomcat;export TOMCAT_DIR
JAVA_OPTS="-Xmx724m -XX:PermSize=32M -XX:MaxPermSize=256m";export JAVA_OPTS;
CLASSPATH=$APP_ROOT:$TSAM_DIR/db-derby-bin/lib/derbyclient.jar:.:$APP_ROOT/java_tool/ojdbc5.jar:$APP_ROOT/java_tool/apache-ant-1.8.2.jar:$APP_ROOT/java_tool:$CLASSPATH;export CLASSPATH
LANG=C;export LANG
LC_ALL=C;export LC_ALL
IATEMPDIR=
if [ "$IATEMPDIR"x != "x" ] && [ ! -d "$IATEMPDIR" ];then
    mkdir $IATEMPDIR
fi

#application server
SERVER_TYPE=Tomcat;export SERVER_TYPE
WLS_HOME=;export WLS_HOME
ADF_HOME=;export ADF_HOME
DOMAIN_HOME=;export DOMAIN_HOME
JAVA_VENDOR=;export JAVA_VENDOR
WLS_JAVA=;export WLS_JAVA


PLATFORM=Linux;export PLATFORM
if [ "$PLATFORM"x = "AIX"x ] ;then
	# for AIX 64
	JVMLIBS=$JAVA_HOME/lib/ppc64/classic:$JAVA_HOME/lib/ppc64:$JAVA_HOME/bin;
	# for AIX 32
    JVMLIBS=$JAVA_HOME/jre/bin/j9vm:$JAVA_HOME/jre/lib/ppc/j9vm:$JAVA_HOME/jre/lib/ppc:$JAVA_HOME/jre/bin:$JVMLIBS;
    # for TSAM_DIR/jdk
    JVMLIBS=$JAVA_HOME/lib/ppc/j9vm:$JAVA_HOME/lib/ppc:$JVMLIBS;
	LIBPATH=$TUXDIR/lib:$JVMLIBS:$LIBPATH; export LIBPATH
#	alias ps="ps auxww"
elif [ "$PLATFORM"x = "SOL_SPARC_64"x ] ;then
        JVMLIBS=$JAVA_HOME/lib/sparcv9/server:$JAVA_HOME/bin
        LD_LIBRARY_PATH=$TUXDIR/lib:$JVMLIBS:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH
elif [ "$PLATFORM"x = "SOL_X86"x ] ;then
echo  "SOL_X86"
elif [ "$PLATFORM"x = "SOL_SPARC_32"x ] ;then
        JVMLIBS=$JAVA_HOME/lib/sparcv/server:$JAVA_HOME/bin
        LD_LIBRARY_PATH=$TUXDIR/lib:$JVMLIBS:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH
elif [ "$PLATFORM"x = "HP_64"x ] ;then
	JVMLIBS=$JAVA_HOME/lib/IA64W/server:$JAVA_HOME/jre/lib/IA64W/server; export JVMLIBS
#	SHLIB_PATH=$TUXDIR/lib:$JVMLIBS:$SHLIB_PATH; export SHLIB_PATH
	LD_LIBRARY_PATH=$TUXDIR/lib:$JVMLIBS:$LD_LIBRARY_PATH;  export LD_LIBRARY_PATH
	LD_PRELOAD=$JAVA_HOME/lib/IA64W/server/libjvm.so; export LD_PRELOAD
#	alias ps="ps -efx"
elif [ "$PLATFORM"x = "HP_32"x ] ;then
	JVMLIBS=$JAVA_HOME/lib/IA64N/server:$JAVA_HOME/jre/lib/IA64N/server; export JVMLIBS
#	SHLIB_PATH=$TUXDIR/lib:$JVMLIBS:$SHLIB_PATH; export SHLIB_PATH
	LD_LIBRARY_PATH=$TUXDIR/lib:$JVMLIBS:$LD_LIBRARY_PATH;  export LD_LIBRARY_PATH
	LD_PRELOAD=$JVMLIBS; export LD_PRELOAD
#	alias ps="ps -efx"

elif [ "$PLATFORM"x = "Linux"x ] ;then
	JVMLIBS=$JAVA_HOME/lib/amd64/server:$JAVA_HOME/lib/i386/server:$JAVA_HOME/jre/lib/amd64/server; export JVMLIBS
	LD_LIBRARY_PATH=$TUXDIR/lib:$JVMLIBS:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH
elif [ "$PLATFORM"x = "zLinux"x ]; then
        . $TUXDIR/tux.env
else
        echo "not surpport $PLATFORM platform, sanity tool will set TUXDIR/tux.env"
        . $TUXDIR/tux.env
fi
#alias ps
#set fml

FIELDTBLS32=optfml
FLDTBLDIR32=$APP_ROOT
export FIELDTBLS32 FLDTBLDIR32

DELETE_TRASH=n;export DELETE_TRASH
OVER_WRITE_DB=yes;export OVER_WRITE_DB

if [ ! -f "$APP_ROOT/awk" ] && [ $PLATFORM = 'SOL_SPARC_64' ];then
    awkdir=`which nawk`
    ln -s $awkdir $APP_ROOT/awk > /dev/null 2>&1
fi
    PATH=$APP_ROOT:$PATH ; export PATH

if [ -f  "${APP_ROOT}/ex_env.sh" ];then
    chmod 777 ${APP_ROOT}/ex_env.sh
    . ${APP_ROOT}/ex_env.sh
fi

COBDIR=$ORACLE_HOME/cobol;export COBDIR
ORACLE_LIB=$APP_ROOT/lib;export ORACLE_LIB


PORT=9001;export PORT
IPCKEY_BASE=30000;export IPCKEY_BASE
IPCKEY_INC=0;export IPCKEY_INC
PORT_INC=0;export IPCKEY_INC
PORT_LEN=23;export PORT_LEN

