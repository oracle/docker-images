if [ ! -d site1 ];then mkdir site1; fi
if [ ! -d site2 ];then mkdir site2; fi

is11g=`echo $TSAM_VERSION | awk -F . '{print $1}'`
if [ $is11g -ge 12 ]; then
  nohup tlisten -j rmi://$HOSTNAME:$RMI_PORT1 -l //$HOSTNAME:$TLISTEN_PORT1 > t1.log 2>&1 &
  PMID="slave5";export PMID
  nohup tlisten -j rmi://$HOSTNAME:$RMI_PORT2 -l //$HOSTNAME:$TLISTEN_PORT2 > t2.log 2>&1 &
  unset PMID
else
  nohup tlisten -l //$HOSTNAME:$TLISTEN_PORT1 > t1.log 2>&1 &
  export PMID="slave5";export PMID
  nohup tlisten -l //$HOSTNAME:$TLISTEN_PORT2 > t2.log 2>&1 &
  unset PMID
fi

find . -name "tuxconfig" | xargs rm -f
find . -name "bdmconfig" | xargs rm -f

cat ubb.tplt | sed "s/@HOSTNAME@/$HOSTNAME/g"|sed "s/@MGR_HOSTNAME@/$MGR_HOSTNAME/g"|sed "s?@TUXDIR@?$TUXDIR?g"|sed "s?@APPDIR@?$APPDIR?g" > ubb
cat domcfg.tplt | sed "s/@HOSTNAME@/$HOSTNAME/g" > domcfg

tmloadcf -y ubb
dmloadcf -y domcfg
./crdl.sh

if [ ! -e simpcl ];then
  ./make.sh 1 10
fi

