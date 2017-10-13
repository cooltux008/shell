############################################
#!/bin/bash
#To contribute to lvs_dr
#Made by liujun,2014/08/11
############################################
#Define system environment PATH
export PATH=$PATH
#Source function library
. /etc/rc.d/init.d/functions

#Define Variable
Sysconfig_Dir=/etc/sysconfig/network-scripts
VIP=192.168.10.100
Eth=eth0
Eth_Child_Num=0

#################
#Define functions
#################

network_restart() {
echo -e "\e[31;1mNetworking\e[0m \e[32;1mrestart\e[0m\n"
/etc/init.d/network restart
}

start_begin() {
echo -e "\e[31;1mActiving\e[0m \e[32;1m$Eth:$Eth_Child_Num\e[0m\r"
sleep 0.5
echo -e "\e[31;1mAdding\e[0m route rules to \e[32;1m$Eth:$Eth_Child_Num\e[0m\r"
echo -e "... ..."
sleep 0.5
}

start_end() {
sleep 0.5
echo -e "\n"
echo -e "ifcfg-\e[32;1m$Eth:$Eth_Child_Num\e[0m is \e[31;1mactived!\e[0m\n$(ifconfig $Eth:$Eth_Child_Num)"
echo -e "\e[31;1mRoute rules\e[0m is \e[32;1mcreated\e[0m\n$(route -ne|grep $VIP)"
}

stop_begin() {
echo -e "\e[31;1mRemoving\e[0m route rules from \e[32;1m$Eth:$Eth_Child_Num\e[0m\r"
sleep 0.5
echo -e "\e[31;1mInactiving\e[0m  \e[32;1m$Eth:$Eth_Child_Num\e[0m\r"
echo -e "... ..."
}

stop_end() {
sleep 0.5
echo -e "\n"
echo -e "The \e[31;1mroute rules\e[0m is \e[32;1mremoved\e[0m\r"
echo -e "The ifcfg-\e[31;1m$Eth:$Eth_Child_Num\e[0m is \e[32;1minactived\e[0m\r"
sleep 0.5
}

status() {
echo -e "\n"
if [ -f $Sysconfig_Dir/route-$Eth:$Eth_Child_Num ];then
	echo -e "ifcfg-\e[32;1m$Eth:$Eth_Child_Num\e[0m is \e[31;1mactived!\e[0m\n$(ifconfig $Eth:$Eth_Child_Num)"
	echo -e "\e[31;1mRoute rules\e[0m is \e[32;1mcreated\e[0m\n$(route -ne|grep $VIP)"
	else
	echo -e "ifcfg-\e[32;1m$Eth:$Eth_Child_Num\e[0m is \e[31;1minactived!\e[0m\n"
	echo -e "\e[31;1mNo route \e[0m to \e[32;1m$Eth:$Eth_Child_Num\e[0m\n"
fi
}


start() {
#Build /etc/sysconfig/network-scripts/ifcfg-eth0:0
start_begin

if  ! [ -f $Sysconfig_Dir/ifcfg-$Eth:$Eth_Child_Num ];then 
	cat > $Sysconfig_Dir/ifcfg-$Eth:$Eth_Child_Num <<HERE
DEVICE=$Eth:$Eth_Child_Num
BOOTPROTO=static
IPADDR=$VIP
NETMASK=255.255.255.255
BROADCAST=$VIP
NM_CONTROLLED=no
ONBOOT=yes
TYPE=Ethernet
HERE
fi

#Build /etc/sysconfig/network-scripts/route-$Eth:0
if ! [ -f $Sysconfig_Dir/route-$Eth:$Eth_Child_Num ];then 
cat >$Sysconfig_Dir/route-$Eth:$Eth_Child_Num <<HERE
$VIP  dev $Eth:$Eth_Child_Num
HERE
fi

network_restart
start_end

}

stop() {
stop_begin

rm -rf $Sysconfig_Dir/ifcfg-$Eth:$Eth_Child_Num >/dev/null 2>&1
rm -rf $Sysconfig_Dir/route-$Eth:$Eth_Child_Num >/dev/null 2>&1

stop_end
network_restart

}




#How to use

case $1 in 
start)
	start
	;;
stop)
	stop
	;;
restart)
	stop
	sleep 1
	echo -e "########################################################"
	echo -e "\n\n\n\n\n\n\n\n\n"
	echo -e "########################################################"
	start
	;;
status)
	status
	;;
	
*)
	echo -e "\e[32;1mUsage:\e[0m \e[33;1m$0\e[0m \e[34;1m{start|stop|restart|status}\e[0m"
	exit 1
	;;
esac
exit $?
