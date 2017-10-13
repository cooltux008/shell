#################################################
#!/bin/bash
#To share a wifi
#Made by liujun,2012-01-21
#################################################
#临时开启IP转发，即路由功能
echo 1 >/proc/sys/net/ipv4/ip_forward
echo "己开启路由转发功能"
echo ""
sleep 0.3

#清除防火墙规则
iptables -F
iptables -X
iptables -Z
iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z


#允许网络包进入
for i in lo eth0 wlan0 
do
	iptables -A INPUT -i $i -j ACCEPT
done

#允许网络包出去
iptables -A OUTPUT -j ACCEPT
iptables -A FORWARD -j ACCEPT

#路由功能
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE


echo "Done"
echo ""
echo "Having a good time!"
