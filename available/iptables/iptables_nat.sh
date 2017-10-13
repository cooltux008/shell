###############################################################
#!/bin/bash
#Customize iptables
#Made by liujun, 2014/09/24
###############################################################
#----------------------------------
#export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

#define LAN & WAN
Interface_In=eth0
Interface_Out=eth1
Wan=$(ifconfig $Interface_Out|grep 'inet addr:'|awk '{print $2}'|cut -d: -f2)

#----------------------------------
#clean up iptables rules
#filter
iptables -F
iptables -X
iptables -Z
#nat
iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z

#----------------------------------
#set iptables policy
#filter
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
#filter
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT

#----------------------------------
#accept lo (localhost)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#----------------------------------
#accept some ICMP
ICMP="0 3 3/4 4 11 12 14 16 18 8"
for i in $ICMP
do
	iptables -A INPUT -i $Interface_Out -p icmp --icmp-type $i -j ACCEPT
done

#----------------------------------
#定义相关变量，多个IP(地址段)以空隔隔开
Trust_Ip_Special="221.232.172.157"
Trust_Ip_List="10.10.10.1 192.168.0.1"
Trust_Ip_Range="192.168.100.100-192.168.100.110 172.16.100.100-172.16.100.200"

Flag=$(grep "net.ipv4.ip_forward" /etc/sysctl.conf)
if [ "$Flag" == "" ];then
	echo 1 >/proc/sys/net/ipv4/ip_forward
	echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
	sysctl -p &>/dev/null
	else
		sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf &>/dev/null
		sysctl -p &>/dev/null
		echo 1 >/proc/sys/net/ipv4/ip_forward
fi
iptables -t nat -A POSTROUTING -o $Interface_Out -j LOG
iptables -t nat -A POSTROUTING -o $Interface_Out -j SNAT --to-source $Wan
