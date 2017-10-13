#!/bin/sh

# define function
package_install(){
	[ -n "$(rpm -q $1|egrep "(not installed)|未安装软件包")" ] && yum -y install $1 || echo "$1 is installed"
}
service_restart(){
	systemctl enable $1
	systemctl restart $1
	systemctl status $1
}
network_static(){
	IPADDR=$(ip a|grep "$1"|grep -oP "(?<=inet ).*(?= brd)"|awk -F'/' '{print $1}')
	IPADDR_DHCP_AGENT=$(echo $IPADDR|awk -F'.' '{print $1"."$2"."$3}')
	HOSTNAME=$(echo $IPADDR|tr -s '.' '-'|tee /etc/hostname)
	sed -i "/$IPADDR/d" /etc/hosts
	echo "$IPADDR $HOSTNAME" >> /etc/hosts
	hostname $HOSTNAME
	cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<HERE
TYPE=Ethernet
BOOTPROTO=none
IPADDR=$IPADDR
PREFIX=24
GATEWAY=192.168.130.2
DNS1=192.168.130.2
DEFROUTE=yes
IPV4_FAILURE_FATAL=yes
IPV4_ROUTE_METRIC=0
IPV4_DNS_PRIORITY=100
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
IPV6_DNS_PRIORITY=100
NAME=eth0
DEVICE=eth0
ONBOOT=yes
HERE
	cat >/etc/sysconfig/network-scripts/route-eth0 <<HERE
ADDRESS0=169.254.169.254
NETMASK0=255.255.255.255
GATEWAY0=${IPADDR_DHCP_AGENT}.31
METRIC0=0
HERE
}

# local yum source
rm -rf /etc/yum.repos.d/*
curl -sSL http://192.168.130.254/yum/centos7.repo -o /etc/yum.repos.d/centos7.repo

# network
network_static "192.168.130"

# enable ssh (root) password
sed -i  -e 's/PermitRootLogin without-password/PermitRootLogin yes/g' \
	-e 's/PasswordAuthentication no/PasswordAuthentication yes/g' \
	-e '/^#UseDNS yes/c UseDNS no' /etc/ssh/sshd_config
systemctl restart sshd 
cp -f /home/cloud-user/.ssh/authorized_keys /root/.ssh/
echo root:root|chpasswd

# timezone & ntp
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai 2>/dev/null
package_install chrony
sed -i -e '/0.centos.pool.ntp.org/i server 192.168.130.254 iburst' -e '/centos.pool.ntp.org/d' /etc/chrony.conf
service_restart chronyd.service
chronyc sources

# disable selinux
sed -i '/SELINUX=enforcing/c SELINUX=disabled' /etc/sysconfig/selinux
setenforce 0
cat > /etc/rc.d/rc.local <<EOF
touch /var/lock/subsys/local
setenforce 0
EOF
chmod +x /etc/rc.d/rc.local

# disable iptables
systemctl disable firewalld
systemctl stop firewalld
iptables -F
iptables -X
iptables -Z
iptables -F -t nat
iptables -X -t nat
iptables -Z -t nat
iptables-save >/etc/sysconfig/iptables

# kernel args
cat >/usr/lib/sysctl.d/vm_init.conf <<HERE
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.netfilter.nf_conntrack_max = 2097152
net.netfilter.nf_conntrack_tcp_timeout_established=600
#net.netfilter.nf_conntrack_buckets = 524288

net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
fs.file-max = 6553600
net.ipv4.tcp_sack = 0
net.ipv4.ip_local_port_range = 30000 65000
net.core.optmem_max = 65535
kernel.pid_max = 65534
HERE
sysctl -p /usr/lib/sysctl.d/vm_init.conf
