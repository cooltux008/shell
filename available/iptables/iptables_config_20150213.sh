###############################################################
#!/bin/bash
#Customize iptables
#Made by liujun,liujun_live@msn.com  2014/10/22
###############################################################
#----------------------------------
#export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

#define LAN & WAN
interface_in=eth0
interface_out=eth1

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
#accept Lan
iptables -A INPUT -i $interface_in -j ACCEPT
#accept 己完成3次握手
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#----------------------------------
#accept some ICMP
ICMP="0 3 3/4 4 11 12 14 16 18 8"
for i in $ICMP
do
	iptables -A INPUT -i $interface_out -p icmp --icmp-type $i -j ACCEPT
done

#--------------------------------------------------------------------
#定义变量,多个IP(地址段,网段)以空隔隔开并加上双引号"",有多少个ip就要有多少个数>组元素与之对应,数组元素用双引号""引起来,且数组元数的栏位及个数又与端口相对应

#ports,服务监听端口列表
#ip_list,离散ip
#ip_range,连续ip地址段
#ip_list_roles,数组变量,用小括号()括起来,对应ip_list的各栏位,ip_range_roles对应ip_range,有几个ip就有几组,有几个端口就有几个roles位,而每一组又对应所有的端口,端口位为1则对该ip应用规则(默认接受)
#log_roles,是否开启防火墙日志,对应ports中的各栏位
#ports_open,特殊端口,允许所有
#如:
##ports="3306 27017 8099 80 3389"
##ip_list="10.10.10.1 192.168.8.0/254"
##ip_list_roles=("0 1 0 0 1" "1 1 1 1 1")
##ip_range="192.168.0.10-192.168.0.20 172.16.0.10-172.16.0.20"
##ip_range_roles=("0 1 0 0 1" "1 1 1 1 1")
##log_roles="1 1 1 1 1"
##ports_open="22"
#--------------------------------------------------------------------
config="/root/ly_wan.txt"
source $config

#数组元素个数
ip_list_num=$(echo $ip_list|wc -w)
ip_range_num=$(echo $ip_range|wc -w)
ip_list_roles_num=${#ip_list_roles[@]}
ip_range_roles_num=${#ip_range_roles[@]}
log_roles_num=$(echo $ports|wc -w)

#----------------------------------
#防火墙日志
#----------------------------------
if [ ! "$log_roles_num" == "0" ];then
	for ((i=1;i<="$log_roles_num";i++))
	do
		log_flag=$(echo $log_roles|cut -d' ' -f$i)
		if [ ! "$log_flag" == "0" ];then
			port_real=$(echo $ports|cut -d' ' -f$i)
			#TCP
			iptables -A INPUT  -i $interface_out  -p tcp --dport $port_real --sport 1024:65534 -j LOG
			#UDP
			#iptables -A INPUT  -i $interface_out  -p udp --dport $port_real --sport 1024:65534 -j LOG
		fi
	done
fi

#----------------------------------
#离散ip
#----------------------------------
if [ "$ip_list_roles_num" -eq "$ip_list_num" ] && [ ! "$ip_list_num" == "0" ];then
	for ((i=0;i<"$ip_list_roles_num";i++))
	do
		ip_flag=${ip_list_roles[i]}
		ip_flag_num=$(echo $ip_flag|wc -w)
		for ((j=1;j<="$ip_flag_num";j++))
		do
			flag=$(echo $ip_flag|cut -d' ' -f$j)
			if [ ! "$flag" == "0" ];then
			port_real=$(echo $ports|cut -d' ' -f$j)
			ip_real=$(echo $ip_list|cut -d' ' -f$[i+1])
			#TCP
			iptables -A INPUT  -i $interface_out  -s $ip_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#TDP
			#iptables -A INPUT  -i $interface_out  -s $ip_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			fi
		done
	done
fi

#----------------------------------
#连续ip地址段
#----------------------------------
if [ "$ip_range_roles_num" -eq "$ip_range_num" ] && [ ! "$ip_range_num" == "0" ];then
	for ((i=0;i<"$ip_range_roles_num";i++))
	do
		ip_flag=${ip_range_roles[i]}
		ip_flag_num=$(echo $ip_flag|wc -w)
		for ((j=1;j<="$ip_flag_num";j++))
		do
			flag=$(echo $ip_flag|cut -d' ' -f$j)
			if [ ! "$flag" == "0" ];then
			port_real=$(echo $ports|cut -d' ' -f$j)
			range_real=$(echo $ip_range|cut -d' ' -f$[i+1])
			#TCP
			iptables -A INPUT  -i $interface_out  -m iprange  --src-range $range_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#UDP
			#iptables -A INPUT  -i $interface_out  -m iprange  --src-range $range_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			fi
		done
	done
fi

#----------------------------------
#特殊端口，不作任何限制
#----------------------------------
for port_open in $ports_open
do
	iptables -A INPUT  -p tcp --dport $port_open -j ACCEPT
done

#----------------------------------
#默认自定义规则
#----------------------------------
#如果没有定义允许访问的客户端ip,即变量ip_list和ip_range同时为空时，开放所有端口开放给全部外网,即对外网不作任何限制，用于排错和特殊情况
#if [ "$ip_list" == "" ] && [ "$ip_range" == "" ];then
#	iptables -A INPUT  -i $interface_out -j ACCEPT
#fi

#----------------------------------
#CentOS iptables开机生效
#----------------------------------
#将规则写入/etc/sysconfig/iptables，让规则永久生效
iptables-save >/etc/sysconfig/iptables
