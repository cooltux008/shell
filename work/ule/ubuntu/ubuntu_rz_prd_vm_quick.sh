#!/bin/bash

cat >/etc/resolv.conf <<HERE
nameserver  172.25.130.31 
nameserver  172.25.130.32
HERE

cat >/etc/apt/sources.list <<HERE
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty universe
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty main restricted
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty-updates main restricted
HERE

passwd ubuntu<<EOF
ubuntu
ubuntu
EOF
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service ssh restart

IP=$(/sbin/ifconfig |grep 172.25|grep -oP "(?<=inet addr:).*(?= Bcast)")
NAME=$(echo $IP|awk -F"." '{print $3$4}')
sed -i "/$IP/d" /etc/hosts
echo $IP ct$NAME >> /etc/hosts
hostname ct$NAME
echo ct$NAME >/etc/hostname
NET=$(/sbin/ifconfig |grep -o "inet addr:172.25[^ ]*" |awk -F. '{print $3}')

echo 'zabbix ALL=(root) NOPASSWD:/bin/netstat' > /etc/sudoers.d/zabbix

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
 iface eth0 inet static
 address $IP
 netmask 255.255.255.0
 gateway 172.25.$NET.1
 dns-nameservers 172.25.130.31 172.25.130.32
up route add -host 169.254.169.254 gw 172.25.$NET.31
EOF
