svcname="TOUPPER"
header=$TUXDIR/include
filename=simpservfml
output=simpserv0906

i=$1
while [ $i -le $2 ]
do
  svcname="TOUPPER"$i
  echo $svcname
  CFLAGS="-D _SVCNAME_=$svcname";export CFLAGS
  buildserver -f $filename.c  -o $output"_"$i -s $svcname
  i=`expr $i + 1`
done

./tool.sh cl
