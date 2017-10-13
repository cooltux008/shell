#!/bin/bash
downtime1_nature="2017-04-05 17:30"
uptime1_nature="2017-04-05 19:50"
downtime2_nature="2017-04-14 13:30"
uptime2_nature="2017-04-14 13:30"

downtime1=$(date -d "$downtime1_nature" +%s)
uptime1=$(date -d "$uptime1_nature" +%s)
downtime2=$(date -d "$downtime2_nature" +%s)
uptime2=$(date -d "$uptime2_nature" +%s)
downtime=$downtime2
uptime=$uptime1

echo downtime1=$downtime1_nature uptime1=$uptime1_nature 
echo downtime2=$downtime2_nature uptime2=$uptime2_nature
MTBF=$[$downtime-$uptime] #秒
MTTR=$(echo "($uptime1-$downtime1+$uptime2-$downtime2)/2"|bc)
AVAILABILITY=$(echo "scale=5;$MTBF/($MTBF+$MTTR)"|bc)

echo "MTBF=downtime2-uptime2=$downtime2_nature-$uptime1_nature=$MTBF"
echo "MTTR=[(uptime1-downtime1)+(uptime2-downtime2)]/2=[($uptime1_nature-$downtime1_nature)+($uptime2_nature-$downtime2_nature)]/2=$MTTR"
echo -e "\nAVAILABILITY=MTBF/(MTBF+MTTR)=$MTBF/($MTBF+$MTTR)=$AVAILABILITY"
