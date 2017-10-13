###############################################################
#!/bin/bash
#Customize iptables
#Made by liujun,liujun_live@msn.com  2014/10/13
###############################################################
#----------------------------------
#export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

#define LAN & WAN
Interface_in=eth0
Interface_out=eth1

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
iptables -A INPUT -i $Interface_in -j ACCEPT
#accept 己完成3次握手
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#----------------------------------
#accept some ICMP
ICMP="0 3 3/4 4 11 12 14 16 18 8"
for i in $ICMP
do
	iptables -A INPUT -i $Interface_out -p icmp --icmp-type $i -j ACCEPT
done

#----------------------------------
#定义变量，多个IP(地址段,网段)以空隔隔开并加上双引号"",Open_ports为开放端口列表，每个端口由两部分(端口号,二进制01编码)组成,以","为分隔符，0表示“拒绝”，即拒绝访问该端口，1表示“允许"，即允许访问该端口
#Ip_list="10.10.10.1 192.168.8.0/254"
#Ip_range="192.168.0.10-192.168.0.20 172.16.0.10-172.16.0.20"
Ip_list=""
Ip_range=""
Open_ports="80,1 8080,1 8091,1 22,1"


#----------------------------------
#开放指定端口
#----------------------------------
#1.记录所有开放端口的日志
#2.开放编码为1的端口号，即ACCEPT所有定义的ip
#3.拒绝所有其它未定义的资源(客户端ip，目标服务及端口)
#----------------------------------

#离散ip地址
if [ ! "$Ip_list" == "" ];then
	for List in $Ip_list
	do
		if [ ! "$Open_ports" == "" ];then
			for Port in $Open_ports
			do
				Port_real=$(echo $Port|cut -d, -f1)
				Flag=$(echo $Port|cut -d, -f2)
				if [ "$Flag" == "1" ];then
				#TCP
				iptables -A INPUT  -i $Interface_out  -p tcp --dport $Port_real --sport 1024:65534 -j LOG
				iptables -A INPUT  -i $Interface_out  -s $List -p tcp --dport $Port_real --sport 1024:65534 -j ACCEPT
				#UDP
 				#iptables -A INPUT  -i $Interface_out  -p udp --dport $Port_real --sport 1024:65534 -j LOG
 				#iptables -A INPUT  -i $Interface_out  -s $List -p udp --dport $Port_real --sport 1024:65534 -j ACCEPT
				fi
			done
		fi
	done
fi

#连续ip地址段
if [ ! "$Ip_range" == "" ];then
	for Range in $Ip_range
	do
		if [ ! "$Open_ports" == "" ];then
			for Port in $Open_ports
			do
				Port_real=$(echo $Port|cut -d, -f1)
				Flag=$(echo $Port|cut -d, -f2)
				if [ "$Flag" == "1" ];then
				#TCP
				iptables -A INPUT  -i $Interface_out  -p tcp --dport $Port_real --sport 1024:65534 -j LOG
				iptables -A INPUT  -i $Interface_out  -m iprange  --src-range $Range -p tcp --dport $Port_real --sport 1024:65534 -j ACCEPT
				#UDP
				#iptables -A INPUT  -i $Interface_out  -p udp --dport $Port_real --sport 1024:65534 -j LOG
				#iptables -A INPUT  -i $Interface_out  -m iprange  --src-range $Range -p udp --dport $Port_real --sport 1024:65534 -j ACCEPT
				fi
			done
		fi
	done
fi

#如果没有定义允许访问的客户端ip,即变量Ip_list和Ip_range同时为空时，开放所有端口给全部外网,即对外网不作任何限制，用于排错和特殊情况
if [ "$Ip_list" == "" ] && [ "$Ip_range" == "" ];then
	iptables -A INPUT  -i $Interface_out -j ACCEPT
fi

#将规则写入/etc/sysconfig/iptables，让规则永久生效
iptables-save >/etc/sysconfig/iptables
