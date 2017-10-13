#!/bin/bash
# local apt source
cat >/etc/apt/sources.list <<HERE
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty universe
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty main restricted
deb [ arch=amd64 ] http://ubuntu.prd.uledns.com/ubuntu trusty-updates main restricted
HERE
echo 'deb  [ arch=amd64 ]   http://ubuntu.prd.uledns.com/cloud trusty-updates/liberty main' > /etc/apt/sources.list.d/cloudarchive-liberty.list

# common user for nova on all openstack nodes
groupadd -g 113 nova
useradd -u 107 -g 113 -d /var/lib/nova nova

# install nova & neutron
apt-get update   
apt-get --force-yes -y install rng-tools software-properties-common python-openstackclient nova-compute sysfsutils neutron-plugin-linuxbridge-agent conntrack
update-rc.d rng-tools enable
service rng-tools restart
flag=$(ps -ef|grep rngd|grep -v grep)
if [ -z "$flag" ];then
	modprobe tpm-rng
	echo tpm-rng >> /etc/modules
	service rng-tools restart
fi

# configure nova node
curl http://172.24.138.32/software/openstack-2.0.tar|tar -xvf -
sed -i "s/172.25.131.81/$(/sbin/ifconfig |grep -o "inet addr:172.25[^ ]*" |awk -F: '{print $2}')/g" nova.conf
cp -fv nova.conf /etc/nova/
cp -fv neutron.conf /etc/neutron/
cp -fv libvirtd.conf /etc/libvirt/
cp -fv libvirt-bin.conf /etc/init/
cp -fv libvirt-bin /etc/default/
cp -fv qemu.conf /etc/libvirt/
cp -fv linuxbridge_agent.ini /etc/neutron/plugins/ml2/
cp -fv ml2_conf.ini /etc/neutron/plugins/ml2/

# zabbix
curl -sSL http://172.24.138.32/software/zabbix-agent_3.0.8-1+trusty_amd64.deb -o /tmp/zabbix-agent_3.0.8-1+trusty_amd64.deb
dpkg -i  /tmp/zabbix-agent_3.0.8-1+trusty_amd64.deb
sed -i  's/Server=/Server=zabbix.beta.uledns.com,zabbix.prd.uledns.com,/g' /etc/zabbix/zabbix_agentd.conf
sed -i  's/ServerActive=/ServerActive=zabbix.beta.uledns.com,/g' /etc/zabbix/zabbix_agentd.conf
chown -R zabbix.zabbix  /etc/zabbix
mkdir -p /home/zabbix
chown -R zabbix.zabbix  /home/zabbix
usermod -d /home/zabbix -s /bin/bash zabbix
mkdir -p /var/run/zabbix/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLqoxYeNXD65ZK9FQvmqDCnrVZ6sCuD9U9RBdBnjGu1tMtlqqRv0rq+HjQnHT8QrrRl2ApAnv6VcKCsueV81GN4cUn6eGP2tKdLlT70gO7FnajkV
EaE5i48sqEYMla8YENlwZsX8bq82N6hyZvp+VjU/ph1xw4Mh3HWQtxTxNHWFjAIyXczgdexEX4v5o5O1Qlm4fk/z7FyB9KrtpXivNqZ74nEH3LgyMOYGpjCtCoR3ef2X7dUwPFEUkJBbOnEpA9p5DZddyw++
JjZvQqm9SpeQFVGN9uGDUPmKwrmnsjdFV4pFX6Fsc1MVkLA112QL65/NYeysnBAxHfIkZ3QusZ web@tu138173" >>/var/run/zabbix/.ssh/authorized_keys
/etc/init.d/zabbix-agent restart
passwd zabbix << EOF
ulejiankong
ulejiankong
EOF

# add data disk
echo "mkfs.ext4 -F /dev/sdb"
echo "echo '/dev/sdb    /var/lib/nova/instances    ext4    defaults,noatime,nodiratime    0    0' >>/etc/fstab"
echo "mount -a"
echo "chown nova.nova /var/lib/nova/instances"
echo "mount"
echo "ls -ld /var/lib/nova/instances"

# reboot
echo ""
echo "reboot"
