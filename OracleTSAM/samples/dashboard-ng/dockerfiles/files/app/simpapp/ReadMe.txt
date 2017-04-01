Example:
./simpcl -s TOUPPER1 -i 1000 -n 2 -t 10 -D 2 -N 2 -I 1000  string
return: "STRING!!"

Description:
the client's tpcall only support the "FML32" type.
the service name is TOUPPER1 TOUPPER2 ... TOUPPER15.

simpcl  -s [service name] -i [the interval between two tpcalls in client side] -n [times that client calls tpcall] -t [timeout for transaction] -D [the depth of callpath] -N [times of the service calling tpcall] -I [the interval between two tpcalls in server side] string_for_tpcall

-s for client means the service name used by tpcall and the option is mandatory.
-i for client means the interval between two tpcalls in client side. default value is 0.the unit is millisecond.
-t for client means if the client is with transaction. default is without transaction. the unit is second.
-n for client means the times of tpcall in client side. default value is 1.
-e for client means if the client ignores the error. This option can't be together with -t.
"string_for_tpcall": for client means  a string without option is the argument for tpcall's service. default value  is NULL.

-D for service means the depth of callpath. default value is 1.
-N for service means the times of the service calling tpcall. default value is 1.
-I for service means the interval between two tpcalls in server side. default value is 0. the unit is millisecond.

Return:
if the character is English letter ,then set it to capital. otherwise do nothing about the character. And append the character '!'  at the tail of the input string, the number of '!' is depth.
