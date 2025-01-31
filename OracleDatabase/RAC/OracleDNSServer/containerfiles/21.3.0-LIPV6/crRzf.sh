#!/bin/bash

rm -f ./tmpRzf
touch ./tmpRzf
echo "" >> tmpRzf
echo "RAC_PUBLIC_SUBNET"
Count=1
while [ $Count -le 250 ]
do
echo "$Count.###RAC_PUBLIC_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###$Count.###DOMAIN_NAME###." >> ./tmpRzf
Count=`expr $Count + 1`
done

echo "" >> tmpRzf
echo "RAC_PUBLIC_VIP_SUBNET"
Count=1
while [ $Count -le 250 ]
do
echo "$Count.###PUBLIC_VIP_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###$Count-vip.###DOMAIN_NAME###." >> ./tmpRzf
Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_PUBLIC_SVIP_SUBNET"
Count=1
hostCount=1
nodeCount=1
while [ $Count -le 250 ]
do
while [ $hostCount -le 4 ]
do
 echo "$Count.###PUBLIC_SVIP_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###$nodeCount-svip-$hostCount.###DOMAIN_NAME###." >> ./tmpRzf
 Count=`expr $Count + 1`
 hostCount=`expr $hostCount + 1`
done
hostCount=1
nodeCount=`expr $nodeCount + 1`
done

## Add other resources like GNS,GNS-VIP,SCANS and CMAN

echo "" >> tmpZF
echo "RAC_SCAN_SUBNETS"
Count=1
while [ $Count -le 250 ]
do
 echo "$Count.###SCAN1_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###-scan$Count.###DOMAIN_NAME###." >> ./tmpRzf
 echo "$Count.###SCAN2_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###-scan$Count.###DOMAIN_NAME###." >> ./tmpRzf
 echo "$Count.###SCAN3_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###-scan$Count.###DOMAIN_NAME###." >> ./tmpRzf
 Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_GNS_SUBNET"
Count=1
while [ $Count -le 250 ]
do
 echo "$Count.###GNS_REVERSEIP###.in-addr.arpa.       IN PTR  ###RAC_NODE_NAME_PREFIX###-gns$Count.###DOMAIN_NAME###." >> ./tmpRzf
 Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_GNS_VIP_SUBNET"
Count=1
while [ $Count -le 250 ]
do
 echo "$Count.###GNS_VIP_REVERSEIP###.in-addr.arpa.   IN PTR  ###RAC_NODE_NAME_PREFIX###-gns$Count-vip.###DOMAIN_NAME###." >> ./tmpRzf
 Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_CMAN_SUBNET"
Count=1
while [ $Count -le 250 ]
do
 echo "$Count.###CMAN_REVERSEIP###.in-addr.arpa.      IN PTR  ###RAC_NODE_NAME_PREFIX###-cman$Count.###DOMAIN_NAME###." >> ./tmpRzf
 Count=`expr $Count + 1`
done

####

echo "" >> tmpRzf
echo "## RAC_PRIVATE_SUBNET" >> tmpRzf
echo "RAC_PRIVATE_SUBNET"
Count=1
while [ $Count -le 250 ]
do
echo "$Count.###RAC_PRIVATE_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###$Count-priv.###DOMAIN_NAME###." >> ./tmpRzf
Count=`expr $Count + 1`
done

echo "" >> tmpRzf
echo "## RAC_PRIVATE_SUBNET2" >> tmpRzf
echo "RAC_PRIVATE_SUBNET2"
Count=1
while [ $Count -le 250 ]
do
echo "$Count.###PRIVATE2_REVERSEIP###.in-addr.arpa.     IN PTR  ###RAC_NODE_NAME_PREFIX###$Count-priv2.###DOMAIN_NAME###." >> ./tmpRzf
Count=`expr $Count + 1`
done
