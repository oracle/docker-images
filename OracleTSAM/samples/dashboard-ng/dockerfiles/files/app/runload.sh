#!/bin/bash
cd ~/app && source setenv.sh
cd simpapp && . ./setenv.sh

while [ 1 ]; do
  TIMES=$((RANDOM%20+20))
  WAIT=$((RANDOM%200))
  DEPTH=$((RANDOM%2+2))
  echo "calling for $TIMES times, call depth: $DEPTH  ..."
  ./simpcl -s TOUPPER9 -i 1 -n $TIMES -D $DEPTH -N 1 -I 5 hello | grep -v HELLO
  echo
  echo "sleeping for $WAIT seconds ..."
  sleep $WAIT
done
