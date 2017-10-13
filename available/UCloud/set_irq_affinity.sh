#########################################################################
# setting up irq affinity according to /proc/irq/*/eth*
# version 0.8:
#	if virtual_machines determine if or not mutiqueue with /sys/class/net/eth0/queues
# version 0.7:
#	mod MAC_CPU == 1,MAX_CPU is negative number,processor name change 
# version 0.6:
#	if MAX_CPU < 8 Soft interrupt average assigned to each CPU 
# version 0.5:
#       Added if mutiqueue disable rps/rfs 
# version 0.4:
# 	Added rps/rfs support
# version 0.3:  
#      Don't kill irqbalance if there is no mutiqueue netcard
#
# version 0.2:  
#      Added chelsio netcard support
#
# version 0.1:   
#      Initial version, a best effort to set cpu affinity for both intel and bnx2 drivers
#
###########################################################################

version=0.8
pethDEV=0

disable_rps_rfs()
{	
	local rps_rfs_zero=0
	echo $rps_rfs_zero > /proc/sys/net/core/rps_sock_flow_entries
	for fileRps in $(ls /sys/class/net/eth*/queues/rx-*/rps_cpus)  
	do
		echo $rps_rfs_zero > $fileRps  
	done

	for fileRfc in $(ls /sys/class/net/eth*/queues/rx-*/rps_flow_cnt)  
	do
		echo $rps_rfs_zero  > $fileRfc  
	done
}

set_rps_rfs()
{
	local MAX_CPU=$(( $(grep "^processor" /proc/cpuinfo | wc -l) ))

	if [ "$virtual_machines_flag" == "0" ];then
		if [[ $MAX_CPU -gt  10 ]];then
			let "MAX_CPU = ${MAX_CPU}/2-2"
		else
			let "MAX_CPU = ${MAX_CPU}"
		fi
	else
		if [[ $MAX_CPU -gt 8 ]];then
			let "MAX_CPU = ${MAX_CPU}-2"
		else
			let "MAX_CPU = ${MAX_CPU}"
		fi
	fi

	if [ $MAX_CPU -ge 32 ];then
		MASK_FILL="" 
		MASK_LOW_32_BIT="ffffffff" 
		let "IDX = $MAX_CPU / 32"
		for ((i=1; i<=$IDX;i++)) 
		do 
			MASK_FILL="${MASK_FILL},${MASK_LOW_32_BIT}" 
		done 
		let "cpuno -= 32 * $IDX" 
		rpsno=$(echo "2^$MAX_CPU - 1" | bc)
		rpsnof=$(echo "ibase=10; obase=16; $rpsno" | bc | tr '[A-Z]' '[a-z]')
		rpsnof=`printf "%X%s" $rpsnof $MASK_FILL` 
	else
		rpsno=$(echo "2^$MAX_CPU - 1" | bc)
		rpsnof=$(echo "ibase=10; obase=16; $rpsno" | bc | tr '[A-Z]' '[a-z]')
	fi
	rfc=4096  
	rsfe=$(echo $MAX_CPU*$rfc | bc)  
	echo $rsfe > /proc/sys/net/core/rps_sock_flow_entries
	#sysctl -w net.core.rps_sock_flow_entries=$rsfe  
	for fileRps in $(ls /sys/class/net/eth*/queues/rx-*/rps_cpus)  
	do
		echo $rpsnof > $fileRps  
    		printf "set rps_cpus=%s\n" ${rpsnof}
	done

	for fileRfc in $(ls /sys/class/net/eth*/queues/rx-*/rps_flow_cnt)  
	do
		echo $rfc > $fileRfc  
	done
}

#MAX_CPU the number of physical CPU - 2
set_virtual_machines_affinity()
{
	local MAX_CPU=$(( $(grep "^processor" /proc/cpuinfo | wc -l) ))
	local DEV="virtio0"

	for DIR in input output
	do 
	MAX=`egrep -i "$DEV-$DIR" /proc/interrupts | wc -l`
		for queue_no in `seq 0 1 $MAX`
		do
			IRQ=`cat /proc/interrupts | grep -i virtio0-$DIR.$queue_no"$" | cut  -d:  -f1 | sed "s/ //g"`
			if [ -n  "$IRQ" ]; then
				queue=$(($[queue_no%${MAX_CPU}]))
				MASK=$((1<<$((queue))))
				set_affinity 
			fi
		done
	done
}

set_affinity()
{

    printf "%s mask=%X for /proc/irq/%d/smp_affinity\n" $DEV $MASK $IRQ
    printf "%X" $MASK > /proc/irq/$IRQ/smp_affinity
}


set_intel_broadcom()
{
	#######################Intel############################
	#  Assuming a device with two RX and TX queues.
	#  This script will assign: 
	#
	#	eth0-rx-0  CPU0
	#	eth0-rx-1  CPU1
	#	eth0-tx-0  CPU0
	#	eth0-tx-1  CPU1
	#######################Intel############################
	
	######################broadcom##########################
	# bnx2:
	# eth0-0 eth0-1 eth0-2 eth0-3 eth0-4
	# eth0-0 eth0-1 eth0-2 eth0-3
	#
	# bnx2x:
	# eth0-rx-0 eth0-rx-1 ...
	# eth0-tx-0 eth0-tx-1 ...
	######################broadcom##########################

	local MAX_CPU=$(( $(grep "^processor" /proc/cpuinfo | wc -l) ))
	local defaule_cpu=0
	let "defaule_cpu = $MAX_CPU"
	let "MAX_CPU = ${MAX_CPU}/2-2"
	if [[ $MAX_CPU -gt 0 ]];then
		if [[ $MAX_CPU -lt 3 ]];then
			let  "MAX_CPU = $defaule_cpu"
		else
			let "MAX_CPU = ${defaule_cpu}/2-2"
		fi
	else
		let "MAX_CPU = $defaule_cpu"
	fi

	cd /proc/irq
	ls -d */*eth* | sed 's/[^0-9][^0-9]*/ /g' > /tmp/irqaffinity
	while read irq eth queue
	do
		if [ -n "${queue}" ]; then
			queue=$(($[queue%${MAX_CPU}]))
			MASK=$((1<<$((queue))))
			IRQ=$irq
			DEV="eth"$eth
			##### compatible with xen0 ####
			if [ $pethDEV -eq 1 ]; then
				DEV="peth"$eth
			fi
			set_affinity
		fi
	done < /tmp/irqaffinity
}
set_chelsio()
{
	local MAX_CPU=$(( $(grep "^processor" /proc/cpuinfo | wc -l)-1 ))
	cpu=$((1))
	for DEV in $(ifconfig -a | grep 00:07:43 | awk '{print $1}'); do
		##### compatible with xen0 #######
		if [ $pethDEV -eq 1 -a "${DEV/peth/}" == "$DEV" ]; then
			continue
		fi
		for IRQ in $(egrep "rdma|ofld|${DEV}" /proc/interrupts | awk '{printf "%d\n",$1}'); do
			MASK=${cpu}
			set_affinity
			cpu=$((${cpu}<<1))
			if [[ ${cpu} -gt $((1<<${MAX_CPU})) ]]; then
				cpu=$((1))
			fi
		done
		ethtool -K $DEV gro off
	done	
}


if [ "$1" = "--version" -o "$1" = "-V" ]; then
	echo "version: $version"
	exit 0
elif [ -n "$1" ]; then
	echo "Description:"
	echo "    This script attempts to bind each queue of a multi-queue NIC"
	echo "    to the same numbered core, ie tx0|rx0 --> cpu0, tx1|rx1 --> cpu1"
	echo "usage:"
	echo "    $0 "
	exit 0
fi

ifconfig peth1 > /dev/null 2>&1 
if [ "$?" == "0" ]; then
	pethDEV=1
	echo "Set IRQ affinity for xen0:"
fi

########### Set up the desired devices. ##################################
virtual_machines_flag=`egrep -i "virtio" /proc/interrupts | wc -l`
if [ "$virtual_machines_flag" == "0" ];then
	mutiqueue=`ls -d /proc/irq/*/*eth* | grep eth.*-.*1`
	if [ -n "${mutiqueue}" ]; then
		# check for irqbalance running
		IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
		if [ "$IRQBALANCE_ON" == "0" ] ; then
			echo " WARNING: irqbalance is running and will"
			echo "          likely override this script's affinitization."
			echo "          So I stopped the irqbalance service by"
			echo "          'killall irqbalance'"
			killall irqbalance
		fi
		result=$(ifconfig -a | grep "00:07:43")
		if [ -n "${result}" ]; then
			set_chelsio
		else
			disable_rps_rfs
			set_intel_broadcom
		fi
	else
		set_rps_rfs
	fi
else
	mutiqueue=`ls -1 /sys/class/net/eth0/queues/ | grep -c tx-*`
	if [ "$mutiqueue" -gt "1" ]; then
		# check for irqbalance running
		IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
		if [ "$IRQBALANCE_ON" == "0" ] ; then
			echo " WARNING: irqbalance is running and will"
			echo "          likely override this script's affinitization."
			echo "          So I stopped the irqbalance service by"
			echo "          'killall irqbalance'"
			killall irqbalance
		fi
		disable_rps_rfs
		set_virtual_machines_affinity
	else
		set_rps_rfs
	fi
fi
