#!/bin/bash

cat >/etc/resolv.conf <<HERE
nameserver  172.25.130.31 
nameserver  172.25.130.32
HERE

mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat >/etc/apt/sources.list <<HERE
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty universe
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty main restricted
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty-updates main restricted
HERE
apt-get update || exit 3

IP=$(/sbin/ifconfig |grep 172.25|grep -oP "(?<=inet addr:).*(?= Bcast)")
NAME=$(echo $IP|awk -F"." '{print $3$4}')
sed -i "/$IP/d" /etc/hosts
echo $IP ct$NAME >> /etc/hosts
NET=$(/sbin/ifconfig |grep -o "inet addr:172.25[^ ]*" |awk -F. '{print $3}')
apt-get install libxtst6 bc pciutils dmidecode -y --force-yes
SERIAL=$(dmidecode|grep 'System Information' -A4|grep 'Serial Number'|awk '{print $3}')
echo "${NAME}CT${SERIAL}.ulecloud.uledns.com" >/etc/hostname
hostname $(cat /etc/hostname)


sed -i 's/source/#source/g'  /etc/network/interfaces
cat >/etc/network/interfaces <<HERE
auto lo
iface lo inet loopback

auto em1
iface em1 inet static
address $IP
netmask 255.255.255.0
gateway 172.25.$NET.1
dns-nameservers 172.25.130.31 172.25.130.32

HERE
[ $NET == 148 ] && sed -i 's/172.25.148.41/172.25.148.30/g' /etc/network/interfaces

apt-get install apache2-utils vim ntp -y --force-yes

mv /etc/ntp.conf /etc/ntp.conf.bak 
cat >> /etc/ntp.conf <<EOF
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable
server 172.25.130.31  iburst
server 172.25.130.32  iburst
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
restrict 127.0.0.1
restrict ::1
EOF
/etc/init.d/ntp restart

echo "colorscheme peachpuff" >> /etc/vim/vimrc

passwd << EOF
uleroot#201723
uleroot#201723
EOF

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' >/etc/timezone
hwclock -w

ln -svf /usr/bin/rotatelogs /usr/sbin/rotatelogs

key_setup(){
#设置172.24.138.100 root-key认证登录
mkdir -p /root/.ssh/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5ADiAMoa8grNRkW8xB2gKlm7Hex6BB4dy3RFv+4PK1SFXawf475cTXDdpNflAX/FAxtUB+uE24C7jZUiikzTxZwWttFyij0NICblmpSW7p/9tOyxdpYvhSfi4I2zTqXgeP+wRmcHyEh/ese5BcS4bBSQNl9U81Yvhx5R5gR3jEzQUNTbQoYatwjFgnM8FinO7m4+fy52DsFcnvntdVrarBUMo2PteKRTl/f7l3M98ys5XoaHvo3wNS9+Cljb9MIr79XWs342Kf9OMaPMFRo1iKGH16b+61clegmkIhaU2gWFLL4B74EI4SkA3V8CJIJI6KdDmTrOHP1CKZs36vf4ew== root@Monitor" >>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvC7V7jp49KJBGgraicF/cQQW7P5w/OidPOx3vR3awF5lNJFtm+lpBvaQ2JsRY82AGk7ufWunVGqfDA3lTovfYBedjXRgWcjcsFDxoonb732UcztkZs4+ADNcr1ZRSF2aO/MfI/aEZ9Qpql69dg5ydDpqe9vwgQwtKyFb4/tgrUdeu+IAwWjNJ4N84fLtD3tfuqGn5MuAqIqVWMUnWjalqMAgmWqgNSduM/hmPqt6V53G9mzL13+4aLrXogAdhhJ6qZ1vV3ktUgnYhDHEpDPDxg2P8TzbqjFB0rCOajgY2LSBTc7uywnRUPN+7sFtxrtekn7Dq8Xi3Q+AkLipHODTV root@tu147240" >> /root/.ssh/authorized_keys
#设置172.24.138.79 web-key登陆
id web
if [ $? != 0 ]
then
	useradd -m -d /home/web -s /bin/bash web
passwd web << EOF
uleweb@201702
uleweb@201702
EOF
	mkdir -p /home/web/.ssh
	touch /home/web/.ssh/authorized_keys
	chmod 600 /home/web/.ssh/authorized_keys
	chown -R web.users /home/web/.ssh/authorized_keys
fi
#设置172.24.138.79/172.24.147.240 web-key认证登录
	mkdir -p /home/web/.ssh
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAralqfhe6S/a6U+h8ALRY/HaZJRbRPteHs25h6g4tazsYpN2YdV61S0U2A2ujnzOMv/whN83ja5QNPGZ3lGTKs/kHTqET2yogTTvbNADZXU+EJfWmY+LH9n/ZB3OX5l6q3YicBE8Nykl7ShpfF5l+45zGvt+2444QJZteBQc1qdqXmVX92GmT6tyN4Ii381Jgg8TPLC40AU+PrethCIgE+lMl9ev07Gp35PABhK0GvXy3SQkFM9C87OmicIfcb6m31gvgVX7eQ7GUO4UsQtiKDcWNjqvHtOQ14qyp/6m1IU4ooDexaJsAmUe3Dnsn9LDRM3WZBd6n7nJNOEgIdYUOeQ== web@ebay53" >> /home/web/.ssh/authorized_keys
        echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDic2vQiqZ0lMDwqxfjXuBxYpHnLUrpe0e4u2FGnpnQJYmlVI9n21J96O0DMZ+gq4K5XTiQi8WR6HhaLz4lSRMPPjo11cWCOdXDc93OeQgjj0Jyw7fvlSu9tNdXpAfBpYmyHjQWuIfANRv7DvNeWDYtiBfX+c8jQC8Qm67dZQSBoQtXVklU7SQctQ6wQQlhnPvDZ8nRDCdyVmLdwKGYmNWCfIKFZOjHO7DlycO5V01yJUCaLz0GWeqzz0QYyhqsWxpPkx1PUxpVrLYklJ7EudS+TCY79AsToadpICQxLNoh/1r1fVePbPuesqjF0PZJCahrTw6HKoZCYYmCnWz/qD/D web@debian"  >> /home/web/.ssh/authorized_keys
	chmod 600 /home/web/.ssh/authorized_keys
	chown -R web.users /home/web/.ssh/authorized_keys
G
#设置240 ubuntu用户免密码登录服务器
        mkdir -p /home/ubuntu/.ssh
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDic2vQiqZ0lMDwqxfjXuBxYpHnLUrpe0e4u2FGnpnQJYmlVI9n21J96O0DMZ+gq4K5XTiQi8WR6HhaLz4lSRMPPjo11cWCOdXDc93OeQgjj0Jyw7fvlSu9tNdXpAfBpYmyHjQWuIfANRv7DvNeWDYtiBfX+c8jQC8Qm67dZQSBoQtXVklU7SQctQ6wQQlhnPvDZ8nRDCdyVmLdwKGYmNWCfIKFZOjHO7DlycO5V01yJUCaLz0GWeqzz0QYyhqsWxpPkx1PUxpVrLYklJ7EudS+TCY79AsToadpICQxLNoh/1r1fVePbPuesqjF0PZJCahrTw6HKoZCYYmCnWz/qD/D web@debian" >> /home/ubuntu/.ssh/authorized_keys
	chmod 600 /home/ubuntu/.ssh/authorized_keys
	chown -R ubuntu.users /home/ubuntu/.ssh/authorized_keys

if ! id readlog &>/dev/null;then
	useradd -m -d /home/readlog -s /bin/bash readlog
passwd readlog << EOF
dev.login#
dev.login#
EOF
        mkdir -p /home/readlog
        cd /home/readlog
        wget http://172.24.138.32/software/authorized_keys.readlog
        mkdir .ssh
        chmod -R 700 .ssh
#设置172.24.138.79  readlog-key认证登录
        cat authorized_keys.readlog >> .ssh/authorized_keys
        chown -R readlog.users /home/readlog
fi


#初始化SSH配置，禁用SSH反向查询DNS，禁止ROOT密码交互登陆

wget http://172.24.138.32/software/yuhao/sshd_config.ubuntu -O /etc/ssh/sshd_config
service ssh restart
}


sys_para(){

#设置系统优化参数
#echo "ulimit -HSn 65536" >>/etc/rc.local
echo "*    soft    nofile    655360" >>/etc/security/limits.conf
echo "*    hard    nofile    655360" >>/etc/security/limits.conf 
echo "ulimit -HSn 655360" >>/root/.bashrc
sed -i '/exit 0/i\ulimit -HSn 65536'  /etc/rc.local 
cp /etc/fstab /etc/fstab.bak
sed -i '/#/!s/defaults/defaults,nodiratime,noatime,nobarrier/' /etc/fstab
sed -i '/#/!s/errors=remount-ro/errors=remount-ro,nodiratime,noatime,nobarrier/' /etc/fstab
echo 'net.ipv6.conf.all.disable_ipv6=1' > /etc/sysctl.d/disableipv6.conf 

echo 10 > /proc/sys/vm/swappiness
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 10 > /proc/sys/vm/dirty_ratio

}

history_profile(){
#设置登录后多长时间没有活动自动退出

echo "HISTFILESIZE=3000" >>/etc/profile
echo "HISTSIZE=3000" >>/etc/profile
echo "export HISTTIMEFORMAT=\"%F %T\"" >>/etc/profile


#设置登录显示的应用、系统接口人信息
echo -e "系统接口人: 系统运维部 28943666-转4036"  >>/etc/motd.tail
echo -e "系统接口人: 系统运维部 28943666-转4036" >>/etc/motd
#设置resolve

}

history_profile
key_setup
sys_para

# openstack init
apt-get --force-yes -y install ifenslave

# configure bond0
cat >>/etc/network/interfaces <<HERE
#slave interfaces
auto em2
iface em2 inet manual
bond-master bond0

auto em3
iface em3 inet manual
bond-master bond0

#bond interface
auto bond0
iface bond0 inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down
#there are several modes, this is also known as mode 4
bond-mode 802.3ad
bond-miimon 100
bond-slaves em2 em3
HERE

# load modules for bond
cat >/etc/modules <<HERE
lp
rtc
bonding
8021q
br_netfilter
HERE

# kernel args
cat >/etc/sysctl.conf <<HERE
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.netfilter.nf_conntrack_max = 2097152
net.netfilter.nf_conntrack_tcp_timeout_established=6000
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
modprobe nf_conntrack
modprobe nf_conntrack_ipv4
modprobe br_netfilter
sysctl -p
#128G mem
echo 524288 >/sys/module/nf_conntrack/parameters/hashsize
echo 'options nf_conntrack hashsize=524288' >/etc/modprobe.d/nova_nf_conntrack.conf 

# kernel tune
echo always > /sys/kernel/mm/transparent_hugepage/enabled
echo never >    /sys/kernel/mm/transparent_hugepage/defrag
echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
flag=$(grep -w transparent_hugepage /etc/init.d/ntp)
if [ "$flag" == "" ];then
	cat >>/etc/init.d/ntp <<HERE
echo always > /sys/kernel/mm/transparent_hugepage/enabled
echo never >    /sys/kernel/mm/transparent_hugepage/defrag
echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
HERE
fi
