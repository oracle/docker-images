source $TUXDIR/tux.env
tlisten -l //${HOSTNAME}:3450
trap exit SIGINT
while true; do
	sleep 1s 
done

