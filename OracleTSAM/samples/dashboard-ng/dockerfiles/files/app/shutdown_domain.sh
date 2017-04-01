shutdown_domain()
{
  cd $APP_ROOT/$1
  . ./setenv.sh
  tmshutdown -yc
  ./shutdown.sh
  cd $APP_ROOT
}

. ./setenv.sh

shutdown_domain simpapp4 > /dev/null 2>&1
shutdown_domain simpapp3 > /dev/null 2>&1
shutdown_domain simpapp2 > /dev/null 2>&1
shutdown_domain simpapp > /dev/null 2>&1
# shutdown_domain strt
# shutdown_domain simpjob
#./ipclean.sh > /dev/null 2>&1
