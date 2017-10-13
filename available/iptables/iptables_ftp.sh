#!/bin/bash
echo "1" > /proc/sys/net/ipv4/ip_forward

# 模块加载先后顺序很重要
modprobe iptable_nat
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp

#iptables -F
#iptables -X
#iptables -Z
#iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW -m tcp --sport 21 -j ACCEPT
#iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 7899 -j DNAT --to-destination 10.130.112.112:21
iptables -t nat -A POSTROUTING -p tcp -m tcp -d 10.130.112.112 -j SNAT --to-source 172.25.130.40
