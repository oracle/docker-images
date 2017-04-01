find . -name "tuxconfig" | xargs rm -f
cat ubb.tplt | sed "s/@HOSTNAME@/$HOSTNAME/g"|sed "s/@MGR_HOSTNAME@/$MGR_HOSTNAME/g"|sed "s?@TUXDIR@?$TUXDIR?g"|sed "s?@APPDIR@?$APPDIR?g" > ubb
tmloadcf -y ubb

CURRDIR=$PWD
if [ ! -e simpcl ];then
  cd $APP_ROOT/simpapp
  cp -f shutdown.sh clean.sh simpcl $CURRDIR
  cd $APP_ROOT/simpapp2
  cp -f simpserv0906_15 $CURRDIR/simpserv0906
fi
