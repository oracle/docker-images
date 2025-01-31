#!/bin/bash
rm -f ./tmpZF
touch ./tmpZF
echo "" >> tmpZF
echo "RAC_PUBLIC_SUBNET"
RAC_PUBLIC_SUBNET="192.168.17.0"
PUB_IP_DIGIT_3=`echo $RAC_PUBLIC_SUBNET | cut -d"." -f3`
PUB_IP_DIGIT_2=`echo $RAC_PUBLIC_SUBNET | cut -d"." -f2`
PUB_IP_DIGIT_1=`echo $RAC_PUBLIC_SUBNET | cut -d"." -f1`
Count=1
while [ $Count -le 1000 ]
do
QUOT=`expr $Count / 250 + 1`
echo "###RAC_NODE_NAME_PREFIX###$Count         IN A    ###RAC_PUBLIC${QUOT}_SUBNET###.$Count" >> tmpZF
Count=`expr $Count + 1`
done

RAC_PUBLIC_REVERSE_IP="${PUB_IP_DIGIT_3}.${PUB_IP_DIGIT_2}.${PUB_IP_DIGIT_1}"
echo  "RAC_PUBLIC_REVERSE_IP set to $RAC_PUBLIC_REVERSE_IP"

for i in {1..8}
do
   export RAC_PUBLIC_REVERSE${i}_IP="${PUB_IP_DIGIT_3}.${PUB_IP_DIGIT_2}.${PUB_IP_DIGIT_1}"
   export TMPSTR=\$RAC_PUBLIC_REVERSE${i}_IP
   export TMPREVIP=`eval echo ${TMPSTR}`
   echo "TMPREVIP=${TMPREVIP}"
   echo "RAC_PUBLIC_REVERSE${i}_IP set to `eval echo ${TMPSTR}`"
   PUB_IP_DIGIT_3=`expr $PUB_IP_DIGIT_3 + 1`
done

echo "Exiting"

exit 0

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
