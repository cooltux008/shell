############################################
#!/bin/bash
#To contribute to lvs_dr
#Made by liujun,2014/08/11
############################################
#Define system environment PATH
export PATH=$PATH
#Source function library
. /etc/rc.d/init.d/functions

VIP=192.168.10.100

#Define  function
start() {
	ifconfig eth0:0 $VIP netmask 255.255.255.255 broadcast $VIP up
	route add -host $VIP dev eth0:0

	echo -e "Derector \e[32;1mstarted\e[0m"
}
stop() {
	route del -host $VIP dev eth0:0
	ifconfig eth0:0 down

	echo -e "Derector \e[31;1mstopped\e[0m"
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
	start
	;;
*)
	echo -e "\e[32;1mUsage:\e[0m \e[33;1m$0\e[0m \e[34;1m{start|stop|restart}\e[0m"
	exit 1
	;;
esac
exit $?

