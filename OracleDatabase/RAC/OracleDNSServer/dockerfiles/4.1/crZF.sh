#!/bin/bash

rm -f ./tmpZF
touch ./tmpZF
echo "" >> tmpZF
echo "RAC_PUBLIC_SUBNET"
Count=1
while [ $Count -le 250 ]
do
echo "###RAC_NODE_NAME_PREFIX###$Count         IN A    ###RAC_PUBLIC_SUBNET###.$Count" >> tmpZF
Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_PUBLIC_VIP_SUBNET"
Count=1
while [ $Count -le 250 ]
do
echo "###RAC_NODE_NAME_PREFIX###$Count-vip         IN A    ###RAC_PUBLIC_VIP_SUBNET###.$Count" >> tmpZF
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
 echo "###RAC_NODE_NAME_PREFIX###$nodeCount-svip-$hostCount         IN A    ###RAC_PUBLIC_SVIP_SUBNET###.$Count" >> tmpZF
 Count=`expr $Count + 1`
 hostCount=`expr $hostCount + 1`
done
hostCount=1
nodeCount=`expr $nodeCount + 1`
done

echo "" >> tmpZF
echo "RAC_SCAN_SUBNETS"
Count=1
while [ $Count -le 250 ]
do
 echo "###RAC_NODE_NAME_PREFIX###-scan$Count            IN A    ###RAC_SCAN1_SUBNET###.$Count" >> tmpZF
 echo "###RAC_NODE_NAME_PREFIX###-scan$Count            IN A    ###RAC_SCAN2_SUBNET###.$Count" >> tmpZF
 echo "###RAC_NODE_NAME_PREFIX###-scan$Count            IN A    ###RAC_SCAN3_SUBNET###.$Count" >> tmpZF
 Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_GNS_SUBNET"
Count=1
while [ $Count -le 250 ]
do
 echo "###RAC_NODE_NAME_PREFIX###-gns$Count             IN A    ###RAC_GNS_SUBNET###.$Count" >> tmpZF
 Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_GNS_VIP_SUBNET"
Count=1
while [ $Count -le 250 ]
do
 echo "###RAC_NODE_NAME_PREFIX###-gns$Count-vip         IN A    ###RAC_GNS_VIP_SUBNET###.$Count" >> tmpZF
 Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "RAC_CMAN_SUBNET"
Count=1
while [ $Count -le 250 ]
do
 echo "###RAC_NODE_NAME_PREFIX###-cman$Count            IN A    ###RAC_CMAN_SUBNET###.$Count" >> tmpZF
 Count=`expr $Count + 1`
done

####

echo "" >> tmpZF
echo "## RAC_PRIVATE_SUBNET" >> tmpZF
echo "RAC_PRIVATE_SUBNET"
Count=1
while [ $Count -le 250 ]
do
echo "###RAC_NODE_NAME_PREFIX###$Count-priv         IN A    ###RAC_PRIVATE_SUBNET###.$Count" >> tmpZF
Count=`expr $Count + 1`
done

echo "" >> tmpZF
echo "## RAC_PRIVATE_SUBNET2" >> tmpZF
echo "RAC_PRIVATE_SUBNET2"
Count=1
while [ $Count -le 250 ]
do
echo "###RAC_NODE_NAME_PREFIX###$Count-priv2         IN A    ###RAC_PRIVATE_SUBNET2###.$Count" >> tmpZF
Count=`expr $Count + 1`
done
