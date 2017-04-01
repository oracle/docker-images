rm -f site1/* 2>/dev/null
rm -f site2/* 2>/dev/null
find . -name "*.out" -o -name "*err" -o -name "ULOG*" -o -name "tsam.log*" -o -name "log.*" -o -name "*.trc" -o -name "access.*" -o -name "id.out*" -o -name "core" -o -name "core.*" -o -name "good.*" -o -name "tmusrevt.dat" -o -name "t1.log" -o -name "t2.log" -o -name "t3.log" -o -name "*  tlisten*.log"|xargs rm -f > /dev/null 2>&1
