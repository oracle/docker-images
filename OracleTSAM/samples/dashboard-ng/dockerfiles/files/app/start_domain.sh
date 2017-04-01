start_domain()
{
  cd $APP_ROOT/$1
  . ./setenv.sh
  ./startup.sh
  tmboot -y
  cd $APP_ROOT
}
. ./setenv.sh
./shutdown_domain.sh
sleep 1

echo $APP_ACTION | egrep "(all|tuxedo)"
if [ "$?" -eq 0 ];then
  start_domain simpapp
  start_domain simpapp2
  start_domain simpapp3
  start_domain simpapp4
fi
echo $APP_ACTION | egrep "(all|cics)"
if [ "$?" -eq 0 ];then
  start_domain strt
fi
echo $APP_ACTION | egrep "(all|batch)"
if [ "$?" -eq 0 ];then
  start_domain simpjob
fi
