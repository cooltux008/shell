############################################
#!/bin/bash
#modify kernel args to contribute to lvs_dr
#Made by liujun,2014/08/11
############################################
#Define system environment PATH
export PATH=$PATH
#Source function library
. /etc/rc.d/init.d/functions

VIP=192.168.10.100

#Define  function
start() {
	ifconfig lo:0 $VIP netmask 255.255.255.255 broadcast $VIP up >/dev/null 2>&1
	route add -host $VIP dev lo:0 >/dev/null 2>&1
	echo 1 >/proc/sys/net/ipv4/conf/lo/arp_ignore
	echo 2 >/proc/sys/net/ipv4/conf/lo/arp_announce
	echo 1 >/proc/sys/net/ipv4/conf/all/arp_ignore
	echo 2 >/proc/sys/net/ipv4/conf/all/arp_announce

	sysctl -p >/dev/null 2>&1
	echo -e "RealServer \e[32;1mstarted\e[0m"
}
stop() {
	route del -host $VIP dev lo:0 >/dev/null 2>&1
	ifconfig lo:0 down >/dev/null 2>&1
	echo 0 >/proc/sys/net/ipv4/conf/lo/arp_ignore
	echo 0 >/proc/sys/net/ipv4/conf/lo/arp_announce
	echo 0 >/proc/sys/net/ipv4/conf/all/arp_ignore
	echo 0 >/proc/sys/net/ipv4/conf/all/arp_announce

	sysctl -p >/dev/null 2>&1
	echo -e "RealServer \e[31;1mstopped\e[0m"
}
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
	start
	;;
*)
	echo -e "\e[32;1mUsage:\e[0m \e[33;1m$0\e[0m \e[34;1m{start|stop|restart}\e[0m"
	exit 1
	;;
esac
exit $?

