cat >> /etc/security/limits.conf <<'EOF'
root	-	nofile	65536
root	-	nproc	16384
root	-	stack	10240
root	-	memlock	unlimited
*	-	nofile	65536
*	-	nproc	16384
*	-	stack	10240
*	-	memlock	unlimited
EOF

cat > /etc/modules-load.d/netfilter.conf <<EOF
nf_conntrack
nf_conntrack_ipv4
br_netfilter
EOF


cat > /etc/modprobe.d/netfilter_parameter.conf <<EOF
options nf_conntrack hashsize=524288
EOF


cat > /etc/sysctl.conf <<EOF
vm.swappiness=5
fs.file-max=6553600
fs.aio-max-nr=1048576
kernel.shmall=2097152
kernel.shmmax=4294967295
kernel.shmmni=4096
kernel.sem=250 32000 100 128
kernel.sysrq=0
kernel.core_uses_pid=1
kernel.msgmnb=65536
kernel.msgmax=65536
kernel.pid_max=65536
net.core.rmem_default=262144
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.wmem_max=1048576
net.core.netdev_max_backlog=262144
net.core.optmem_max=65536
net.ipv4.ip_local_port_range=9000 65500
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_tw_buckets=6000
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=0
net.ipv4.tcp_rmem=4096 87380 4194304
net.ipv4.tcp_wmem=4096 16384 4194304
net.ipv4.tcp_mem=94500000 915000000 927000000
net.ipv4.tcp_max_orphans=3276800
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_synack_retries=1
net.ipv4.tcp_syn_retries=1
net.ipv4.tcp_tw_recycle=0
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=1
net.ipv4.tcp_keepalive_time=30
net.ipv4.neigh.default.gc_thresh1=80000
net.ipv4.neigh.default.gc_thresh2=90000
net.ipv4.neigh.default.gc_thresh3=100000
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.netfilter.nf_conntrack_tcp_timeout_established=6000
net.netfilter.nf_conntrack_max=2097152
vm.max_map_count=262144
EOF

sysctl -p
