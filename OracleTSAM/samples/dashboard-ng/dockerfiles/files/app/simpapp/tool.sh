
servername="simpserv0906_*"

cp()
{
	/bin/cp $servername $1
}

clean()
{
	/bin/rm $servername
}

make()
{
	./make.sh $1 $2
}

bu()
{
	/bin/cp -r $1 ~/backup
}

cl()
{
	buildclient -f simpclfml.c -o simpcl
}

wscl()
{
	buildclient -w -f simpclfml.c -o wscl
}

joltcl()
{
	javac JoltClient.java
}


if [ $1 = "clean" ] || [ $1 = "joltcl" ] || [ $1 = "cl" ] || [ $1 = "wscl" ]; then
	$1
fi

if [ $1 = "cp" ] || [ $1 = "bu" ]; then
	$1 $2
fi

if [ $1 = "make" ] ; then
	$1 $2 $3
fi
