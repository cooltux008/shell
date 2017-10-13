#!/bin/bash

read -p "Continue y/n":  YN
[ $YN != y ] && exit 3

export IP=$(/sbin/ifconfig eth0|grep -oP "(?<=inet addr:).*(?= Bcast)")
export NET=$(/sbin/ifconfig eth0|grep -o "inet addr:[^ ]*" |awk -F. '{print $3}')


init_hostname(){
sed -i "/$IP/d" /etc/hosts
echo $IP ubuntu-$IP >> /etc/hosts
echo ubuntu-$IP > /etc/hostname
hostname ubuntu-$IP
}

init_network_dns(){
cat > /etc/network/interfaces.d/eth0.cfg <<EOF
auto eth0
iface eth0 inet static
address $IP
netmask 255.255.255.0
gateway 172.25.$NET.31
up route add -host 169.254.169.254 gw 172.25.$NET.31
EOF
cat > /etc/resolvconf/resolv.conf.d/tail <<EOF
nameserver 172.25.130.32
nameserver 172.25.130.31
EOF
resolvconf -u
}

init_apt_sources(){
mv /etc/apt/sources.list /etc/apt/sources.list.default
curl -sSL http://172.24.138.32/software/sources.list.ubuntu -o /etc/apt/sources.list
apt-get update || exit 3
}

init_timezone_ntp(){
cp -a /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

apt-get install ntp -y
mv /etc/ntp.conf /etc/ntp.conf.bak 
cat > /etc/ntp.conf <<EOF
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
#/usr/sbin/ntpdate 172.25.130.31

hwclock -w
}

init_users(){
passwd  <<EOF
Aiwoyoule#123
Aiwoyoule#123
EOF

[ "$(id logview 2>/dev/null)" == "" ] && useradd -m -d /home/logview -s /bin/bash logview
passwd logview <<EOF
viewlog
viewlog
EOF

passwd zabbix <<EOF
ule.zabbix
ule.zabbix
EOF
}

init_logrotate(){
ln -svf /usr/bin/rotatelogs /usr/sbin/rotatelogs
mkdir -p /data/soft
mkdir -p /data/logs
apt-get install libxtst6 -y
}


init_crontab(){
cat > /var/spool/cron/crontabs/root <<EOF
#*/10 * * * * /usr/sbin/ntpdate 172.25.130.31
EOF
}

init_ssh_key(){
mkdir -p /root/.ssh/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5ADiAMoa8grNRkW8xB2gKlm7Hex6BB4dy3RFv+4PK1SFXawf475cTXDdpNflAX/FAxtUB+uE24C7jZUiikzTxZwWttFyij0NICblmpSW7p/9tOyxdpYvhSfi4I2zTqXgeP+wRmcHyEh/ese5BcS4bBSQNl9U81Yvhx5R5gR3jEzQUNTbQoYatwjFgnM8FinO7m4+fy52DsFcnvntdVrarBUMo2PteKRTl/f7l3M98ys5XoaHvo3wNS9+Cljb9MIr79XWs342Kf9OMaPMFRo1iKGH16b+61clegmkIhaU2gWFLL4B74EI4SkA3V8CJIJI6KdDmTrOHP1CKZs36vf4ew== root@Monitor" >>/root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
}

init_ssh_conf(){
wget http://172.24.138.32/software/yuhao/sshd_config.ubuntu -O /etc/ssh/sshd_config
service ssh restart
}

init_kernel_args(){
cat >/etc/sysctl.conf <<EOF 
net.ipv4.ip_forward = 0
#net.ipv4.conf.default.rp_filter = 1
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
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
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
net.ipv4.ip_local_port_range = 30000    65000
net.ipv4.conf.default.rp_filter = 0
net.core.optmem_max = 65535
vm.swappiness = 10
kernel.pid_max = 65534
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
#net.ipv6.conf.all.disable_ipv6=1
EOF
sysctl -p

cat >>/etc/security/limits.conf <<EOF
*    soft    nofile    655360 
*    hard    nofile    655360
EOF
}

init_fstab(){
cp /etc/fstab /etc/fstab.default
sed -i '/#/!s/defaults/defaults,nodiratime,noatime,nobarrier/' /etc/fstab
sed -i '/#/!s/errors=remount-ro/errors=remount-ro,nodiratime,noatime,nobarrier/' /etc/fstab
}

init_history_motd_issue(){
cat >>/etc/profile <<EOF
HISTFILESIZE=3000
HISTSIZE=3000
export HISTTIMEFORMAT=\"%F %T\""
echo -e "系统接口人: 系统运维部 28943666-转4036"  >>/etc/motd.tail
echo -e "系统接口人: 系统运维部 28943666-转4036" >>/etc/motd
EOF
}

init_zabbix_agent(){
apt-get install zabbix-agent -y

sed -i  's/Server=/Server=zabbix.beta.uledns.com,zabbix.prd.uledns.com,/g' /etc/zabbix/zabbix_agentd.conf
sed -i  's/ServerActive=/ServerActive=zabbix.beta.uledns.com,/g' /etc/zabbix/zabbix_agentd.conf
mkdir -p /home/zabbix
chown -R zabbix.zabbix  /home/zabbix
usermod -d /home/zabbix -s /bin/bash zabbix

/etc/init.d/zabbix-agent restart
}

init_app(){
mkdir -p /data/{postmall,tomcat,jboss,logs}
chmod 700 /data/{postmall,tomcat,jboss,logs}

curl -sSL http://172.24.138.32/software/jdk1.6.tar.gz|tar -xvf - -C /data/soft --gzip
curl -sSL http://172.24.138.32/software/jdk1.8.0_45.tar.gz|tar -xvf - -C /data/soft --gzip
mv  /data/soft/jdk1.8.0_45 /data/soft/jdk1.8
ln -svf /data/soft/jdk /data/soft/jdk-1.6
ln -svf jdk jdk1.8 /usr/local/
export JAVA_HOME=/usr/local/jdk
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib
cat >> /etc/profile <<EOF
export JAVA_HOME=/usr/local/jdk
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib
EOF
}

init_end(){
apt-get install vim bc telnet ftp wget screen netcat tcpdump pciutils dmidecode -y
cat > /etc/vim/vimrc <<'EOF'
set nu
set hlsearch 
set flash 
set backspace=2 
set autoindent 
set smartindent 
set ruler 
set showmatch 
set history=400  
set magic 
set fileencodings=utf-8,gb2312,gbk,gb18030,big5,ucs-bom,cp936,tuf-16,euc-jp 
"set bg=dark
sy on 
colorscheme peachpuff
syntax on
EOF
[ $? == 0 ] && dpkg-reconfigure tzdata || (echo "dpkg-reconfigure tzdata";/etc/init.d/cron restart)
}


init_hostname
init_network_dns
init_apt_sources
init_timezone_ntp
init_users
init_logrotate
init_crontab
init_ssh_key
init_ssh_conf
init_kernel_args
init_fstab
init_history_motd_issue
init_zabbix_agent
init_app
init_end
