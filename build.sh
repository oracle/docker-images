#!/bin/bash
#set -x
echo "====================="
#

if [ ! -e tuxedo121300_64_Linux_01_x86.zip ]
then
  echo "Download the Tuxedo 12cR2 ZIP Distribution and"
  echo "drop the file tuxedo121300_64_Linux_01_x86.zip in this folder before"
  echo "building this Tuxedo Docker container!"
  exit 
fi

MD5="7194e8711a257951211185b2280bedd6  tuxedo121300_64_Linux_01_x86.zip"
MD5_CHECK="`md5sum tuxedo121300_64_Linux_01_x86.zip`"

if [ "$MD5" != "$MD5_CHECK" ]
then
  echo "MD5 does not match! Download again!"
  exit
fi


if [ ! -e p*_121300_Linux-x86-64.zip ]
then
  echo "Installing Tuxedo without any patches"
fi

#MD5="3b311c87e921fa9df696bf74c39c3348  p19927652_121300_Linux-x86-64.zip"
#MD5_CHECK="`md5sum p19927652_121300_Linux-x86-64.zip`"
#
#if [ "$MD5" != "$MD5_CHECK" ]
#then
#  echo "MD5 does not match! Download again!"
#  exit
#fi

echo "====================="

# Fix up the locations of things
sh fix_locations.sh tuxedo.docker tuxedo12.1.3.rsp.template >tuxedo12.1.3.rsp
sh fix_locations.sh tuxedo.docker tuxedo12.1.3_silent_install.sh.template >tuxedo12.1.3_silent_install.sh
sh fix_locations.sh tuxedo.docker Dockerfile.template >Dockerfile

docker build -t oracle/tuxedo .
if [ "$?" = "0" ]
    then
	echo ""
	echo "Tuxedo Docker image is ready to be used. To create a container, run:"
	echo "docker run -i -t oracle/tuxedo /bin/bash"
    else
	echo "Build of Tuxedo Docker image failed."
fi

