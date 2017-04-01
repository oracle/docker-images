is11g=`echo $TSAM_VERSION | awk -F . '{print $1}'`
if [ $is11g -ge 12 ]; then
	nohup tlisten -j rmi://tux.box:$RMI_PORT -l //tux.box:$TLISTEN_PORT > t1.log 2>&1 &
else
	echo
fi

find . -name "tuxconfig" | xargs rm -f
find . -name "bdmconfig" | xargs rm -f

cat ubb.tplt | sed "s/@HOSTNAME@/$HOSTNAME/g"|sed "s/@MGR_HOSTNAME@/$MGR_HOSTNAME/g"|sed "s?@TUXDIR@?$TUXDIR?g"|sed "s?@APPDIR@?$APPDIR?g" > ubb
cat domcfg.tplt | sed "s/@HOSTNAME@/$HOSTNAME/g" > domcfg

tmloadcf -y ubb
dmloadcf -y domcfg

CURRDIR=$PWD
if [ ! -e simpcl ];then
  cd $APP_ROOT/simpapp
  cp -f shutdown.sh clean.sh make.sh tool.sh *.c *.h $CURRDIR
  cd $CURRDIR
  ./make.sh 11 15
fi
