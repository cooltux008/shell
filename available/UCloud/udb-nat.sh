iptables -F
iptables -X
iptables -Z
iptables -F -t nat
iptables -X -t nat
iptables -Z -t nat
iptables -t nat -A PREROUTING -p tcp --dport 3306 -j DNAT --to-destination 10.10.67.42:3306
iptables -t nat -A POSTROUTING -s 0.0.0.0/0 -o eth0 -j MASQUERADE
