rm -f $APPDIR/site1/TUXFS $APPDIR/site2/TUXFS
e=`tmadmin << EOF
crdl -z $APPDIR/site1/TUXFS -b 500
crlog -m SITE1
crdl -z $APPDIR/site2/TUXFS -b 500
inlog -m SITE2
q
EOF`
