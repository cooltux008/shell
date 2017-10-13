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
interface_out=eth0
if [ "$interface_out" == ""  ];then
	echo -e "\e[31;1mPlease confirm the interface!\e[0m"
	exit 1
fi
#ipv4 & ipv6
interface_in_ipv4=$(ifconfig $interface_in|grep -w 'inet addr'|awk '{print $2}'|cut -d: -f2)
interface_out_ipv4=$(ifconfig $interface_out|grep -w 'inet addr'|awk '{print $2}'|cut -d: -f2)
interface_in_ipv6=$(ifconfig $interface_in|grep -w 'inet6 addr'|awk '{print $3}'|cut -d'/' -f1)
interface_out_ipv6=$(ifconfig $interface_out|grep -w 'inet6 addr'|awk '{print $3}'|cut -d'/' -f1)

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
##定义变量，多个IP(地址段,网段)以空隔隔开并加上双引号"",有多少个ip就要有多少个数组元素与之对应，数组元素用双引号""引起来，且数组元数的栏位及个数又与端口相对应
##ports_tcp为服务监听tcp端口列表,ports_udp为服务监听udp端口列表
##ip_list为离散ip,ip_range为连续ip地址段,如:ip_list="10.10.10.1 192.168.8.0/254"  ip_range="192.168.0.10-192.168.0.20 172.16.0.10-172.16.0.20"
##ip_list_roles_tcp是一个数组变量[用小括号()括起来]对应ip_list的各栏位，ip_range_roles_tcp对应ip_range,有几个ip就有几组,有几个端口就有几个roles位，而每一组又对应所有的端口,端口位为1则对该ip应用规则（默认接受),ip_list_roles_udp针对udp同理
##log_roles_tcp/log_roles_udp定义是否开启防火墙日志,对应ports中的各栏位，值为1则开启对应端口的防火墙日志
#--------------------------------------------------------------------

#ports_udp="137 138"
#ip_list_roles_udp=("1 0" "1 1" "0 1")
#ip_range_roles_udp=("1 1" "0 1")

ports_tcp="80 8080 8091 22"
ip_list="192.168.8.254 192.168.2.254 10.10.10.2"
ip_range="10.10.10.5-10.10.10.30 172.25.254.10-172.25.254.20"
ip_list_roles_tcp=("1 0 1 0" "0 1 1 0" "0 0 1 0")
ip_range_roles_tcp=("1 0 0 0" "0 0 0 1")


#针对端口记录日志
log_roles_tcp="1 1 1 1"
log_roles_udp="1 1"

#数组元素个数,不要改动
ip_list_num=$(echo $ip_list|wc -w)
ip_range_num=$(echo $ip_range|wc -w)
ip_list_roles_tcp_num=${#ip_list_roles_tcp[@]}
ip_list_roles_udp_num=${#ip_list_roles_udp[@]}
ip_range_roles_tcp_num=${#ip_range_roles_tcp[@]}
ip_range_roles_udp_num=${#ip_range_roles_udp[@]}
log_roles_tcp_num=$(echo $ports_tcp|wc -w)
log_roles_udp_num=$(echo $ports_udp|wc -w)


echo -e "\e[36;1m--------------------------------------------------------\e[0m"
#----------------------------------
#防火墙日志
#----------------------------------
#TCP
if [ ! "$log_roles_tcp_num" == "0" ];then
	for ((i=1;i<="$log_roles_tcp_num";i++))
	do
		log_flag=$(echo $log_roles_tcp|cut -d' ' -f$i)
		if [ ! "$log_flag" == "0" ];then
			port_real=$(echo $ports_tcp|cut -d' ' -f$i)
			iptables -A INPUT  -i $interface_out  -p tcp --dport $port_real --sport 1024:65534 -j LOG
			echo -e "\e[31;1m$port_real\e[0m is \e[32;1mLOG\e[0m"
		fi
	done
	echo -e "\e[31;1mTCP LOG\e[0m \e[32;1mOK\e[0m!"
fi
#UDP
if [ ! "$log_roles_udp_num" == "0" ];then
	echo ""
	for ((i=1;i<="$log_roles_udp_num";i++))
	do
		log_flag=$(echo $log_roles_udp|cut -d' ' -f$i)
		if [ ! "$log_flag" == "0" ];then
			port_real=$(echo $ports_udp|cut -d' ' -f$i)
			iptables -A INPUT  -i $interface_out  -p udp --dport $port_real --sport 1024:65534 -j LOG
			echo -e "\e[31;1m$port_real\e[0m is \e[32;1mLOG\e[0m"
		fi
	done
	echo -e "\e[31;1mUDP LOG\e[0m \e[32;1mOK\e[0m!"
fi

echo -e "\e[36;1m--------------------------------------------------------\e[0m"

#----------------------------------
#离散ip
#----------------------------------
#TCP
if [ "$ip_list_roles_tcp_num" -eq "$ip_list_num" ] && [ ! "$ip_list_num" == "0" ];then
	for ((i=0;i<"$ip_list_roles_tcp_num";i++))
	do
		ip_flag=${ip_list_roles_tcp[i]}
		ip_flag_num=$(echo $ip_flag|wc -w)
		for ((j=1;j<="$ip_flag_num";j++))
		do
			flag=$(echo $ip_flag|cut -d' ' -f$j)
			if [ ! "$flag" == "0" ];then
			port_real=$(echo $ports_tcp|cut -d' ' -f$j)
			ip_real=$(echo $ip_list|cut -d' ' -f$[i+1])
			#------------
			#interface_out
			#------------
			#ipv4
			iptables -A INPUT  -i $interface_out  -s $ip_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_out_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			#ipv6
			#ip6tables -A INPUT  -i $interface_out  -s $ip_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_out_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"

			#------------
			#interface_in
			#------------
			##ipv4
			#iptables -A INPUT  -i $interface_in  -s $ip_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_in_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#iptables -A INPUT  -i $interface_in  -s $ip_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_in_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			fi
		done
	done
	echo -e "\e[31;1mTCP ip_list\e[0m \e[32;1mOK \e[0m!"
fi
#UDP
if [ "$ip_list_roles_udp_num" -eq "$ip_list_num" ] && [ ! "$ip_list_num" == "0" ];then
	for ((i=0;i<"$ip_list_roles_udp_num";i++))
	do
		ip_flag=${ip_list_roles_tcp[i]}
		ip_flag_num=$(echo $ip_flag|wc -w)
		for ((j=1;j<="$ip_flag_num";j++))
		do
			flag=$(echo $ip_flag|cut -d' ' -f$j)
			if [ ! "$flag" == "0" ];then
			port_real=$(echo $ports_tcp|cut -d' ' -f$j)
			ip_real=$(echo $ip_list|cut -d' ' -f$[i+1])
			#------------
			#interface_out
			#------------
			##ipv4
			iptables -A INPUT  -i $interface_out  -s $ip_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_out_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#ip6tables -A INPUT  -i $interface_out  -s $ip_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_out_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"

			#------------
			#interface_in
			#------------
			#ipv4
			iptables -A INPUT  -i $interface_in  -s $ip_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_in_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#ip6tables -A INPUT  -i $interface_in  -s $ip_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$ip_real\e[0m===>\e[36;1m$interface_in_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			fi
		done
	done
	echo -e "\e[31;1mUDP ip_list\e[0m \e[32;1mOK \e[0m!"
fi

#----------------------------------
#连续ip地址段
#----------------------------------
#TCP
if [ "$ip_range_roles_tcp_num" -eq "$ip_range_num" ] && [ ! "$ip_range_num" == "0" ];then
	for ((i=0;i<"$ip_range_roles_tcp_num";i++))
	do
		ip_flag=${ip_range_roles_tcp[i]}
		ip_flag_num=$(echo $ip_flag|wc -w)
		for ((j=1;j<="$ip_flag_num";j++))
		do
			flag=$(echo $ip_flag|cut -d' ' -f$j)
			if [ ! "$flag" == "0" ];then
			port_real=$(echo $ports_tcp|cut -d' ' -f$j)
			range_real=$(echo $ip_range|cut -d' ' -f$[i+1])
			#------------
			#interface_out
			#------------
			##ipv4
			iptables -A INPUT  -i $interface_out  -m iprange  --src-range $range_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_out_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#ip6tables -A INPUT  -i $interface_out  -m iprange  --src-range $range_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_out_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"

			#------------
			#interface_in
			#------------
			##ipv4
			iptables -A INPUT  -i $interface_in  -m iprange  --src-range $range_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_in_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#ip6tables -A INPUT  -i $interface_in  -m iprange  --src-range $range_real -p tcp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_in_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			fi
		done
	done
	echo -e "\e[31;1mTCP ip_range\e[0m \e[32;1mOK \e[0m!"
fi
#UDP
if [ "$ip_range_roles_udp_num" -eq "$ip_range_num" ] && [ ! "$ip_range_num" == "0" ];then
	for ((i=0;i<"$ip_range_roles_udp_num";i++))
	do
		ip_flag=${ip_range_roles_udp[i]}
		ip_flag_num=$(echo $ip_flag|wc -w)
		for ((j=1;j<="$ip_flag_num";j++))
		do
			flag=$(echo $ip_flag|cut -d' ' -f$j)
			if [ ! "$flag" == "0" ];then
			port_real=$(echo $ports_udp|cut -d' ' -f$j)
			range_real=$(echo $ip_range|cut -d' ' -f$[i+1])
			#------------
			#interface_out
			#------------
			##ipv4
			iptables -A INPUT  -i $interface_out  -m iprange  --src-range $range_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_out_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#ip6tables -A INPUT  -i $interface_out  -m iprange  --src-range $range_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_out_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"

			#------------
			#interface_in
			#------------
			##ipv4
			iptables -A INPUT  -i $interface_in  -m iprange  --src-range $range_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_in_ipv4\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			##ipv6
			#ip6tables -A INPUT  -i $interface_in  -m iprange  --src-range $range_real -p udp --dport $port_real --sport 1024:65534 -j ACCEPT
			#echo -e "\e[34;1m$range_real\e[0m===>\e[36;1m$interface_in_ipv6\e[0m:\e[31;1m$port_real\e[0m is \e[32;1maccepted\e[0m"
			fi
		done
	done
	echo -e "\e[31;1mUDP ip_range\e[0m \e[32;1mOK \e[0m!"
fi
#----------------------------------
#默认自定义规则
#----------------------------------
#如果没有定义允许访问的客户端ip,即变量ip_list和ip_range同时为空时，开放所有端口开放给全部外网,即对外网不作任何限制，用于排错和特殊情况
if [ "$ip_list" == "" ] && [ "$ip_range" == "" ];then
	iptables -A INPUT  -i $interface_out -j ACCEPT
fi

#----------------------------------
#CentOS iptables开机生效
#----------------------------------
#将规则写入/etc/sysconfig/iptables，让规则永久生效
iptables-save >/etc/sysconfig/iptables

echo -e "\e[36;1m--------------------------------------------------------\e[0m"
#----------------------------------
#显示目前生效的filter表的所有规则
#----------------------------------
#clear
#iptables -L -n
echo -e "\e[32;1mGood luck!\e[0m"
