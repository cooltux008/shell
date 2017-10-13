############################################################################
#!/bin/bash
#To install and configure zabbix from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2015-05-01
############################################################################

#########################################################
#Check zabbix source file 
#########################################################
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mzabbix-x.x.x.tar.gz\e[0m"
	exit 1
fi

#########################################################
#Check user & group 
#########################################################
user_group(){
user=$(cat /etc/passwd|cut -d: -f1 |grep zabbix)
group=$(cat /etc/group|cut -d: -f1 |grep zabbix)
echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m"
echo ""
if [ "$group" = "" ];then
	groupadd -r zabbix 
	echo -e "\e[32;1mGroup zabbix\e[0m is added"
else 
	echo -e "\e[32;1mGroup\e[0m zabbix is exist"
fi

if [ "$user" = "" ];then
	useradd -r zabbix -g zabbix -s /sbin/nologin
	echo -e "\e[32;1mUser zabbix\e[0m is added"
else
	echo -e "\e[32;1mUser\e[0m zabbix is exist"
fi
echo ""
echo ""
echo ""
}
#########################################################
#Install libs developed
#########################################################
libs(){
echo "--------------------------------------------"
echo -e "Check \e[31;1mlibs developed\e[0m"
echo ""
rpm -e --nodeps mysql mysql-libs &>/dev/null
packages="gcc gcc-c++ autoconf make libcurl-devel libxml2-devel net-snmp-devel openldap-devel openssl-devel libssh2-devel unixODBC-devel OpenIPMI-devel"
for i in $packages
do
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
	if [ "$flag" != "" ];then
		yum -y install $i 2>/dev/null
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}

#########################################################
#Variables
#########################################################
export zabbix_base_dir="/opt/zabbix"
export build_dir="/usr/local/src"
export zabbix_tar=$1
export zabbix_version=$(echo $zabbix_tar|grep -oP "(?<=zabbix-).*(?=.tar.*)")

export mysql_base_dir="/opt/mariadb"

export zabbix_server_host="192.168.8.254"
export zabbix_server_port="10051"
 
export zabbix_agentd_host="$HOSTNAME"
export zabbix_agentd_port="10050"
export zabbix_agentd_log="/tmp/zabbix_agentd.log"
 
export zabbix_db_host="localhost"
export zabbix_db_port="3306"
export zabbix_db_sock="/tmp/mysql.sock"
export zabbix_db_user="root"
export zabbix_db_user_password="root"
export zabbix_db="zabbix"
#########################################################
#Building & Install
#########################################################
zabbix_install(){
user_group
libs
sleep 1

tar -xvf $zabbix_tar -C $build_dir
cd $build_dir/zabbix-$zabbix_version
./configure \
--prefix=$zabbix_base_dir \
--enable-agent \
--enable-ipv6 \
--with-mysql \
--with-net-snmp \
--with-libcurl \
--with-libxml2 \
--with-ldap \
--with-openssl \
--with-ssh2 \
--with-unixodbc \
--with-openipmi
[ $? != 0 ] && echo -e "\e[31;1mERROR\e[0m" && exit 1
make -j4 install
[ $? == 0 ] && echo -e "\e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
#########################################################
#Check init.d shell script
#########################################################
ln -s $mysql_base_dir/lib/libmysqlclient.so.18 /usr/lib64/ 2>/dev/null
ln -s $mysql_base_dir/bin/{mysql,mysqladmin} /usr/bin 2>/dev/null
cp $build_dir/zabbix-$zabbix_version/misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
chmod +x /etc/init.d/zabbix_agentd
sed -i "/BASEDIR=/s#/usr/local#$zabbix_base_dir#g" /etc/init.d/zabbix_agentd

#########################################################
#Config file
#########################################################

#Zabbix agentd
mv $zabbix_base_dir/etc/zabbix_agentd.conf{,.default}
cat >$zabbix_base_dir/etc/zabbix_agentd.conf <<HERE
#ListenIP=
ListenPort=$zabbix_agentd_port
LogFile=$zabbix_agentd_log
LogFileSize=2
DebugLevel=3
Server=$zabbix_server_host
ServerActive=$zabbix_server_host
Hostname=$zabbix_agentd_host
EnableRemoteCommands=1
LogRemoteCommands=1
Timeout=10
StartAgents=4
Include=$zabbix_base_dir/etc/zabbix_agentd.conf.d/*.conf
LoadModulePath=$zabbix_base_dir/lib
#LoadModule=dummy.so
UnsafeUserParameters=1
UserParameter=system.test,who|wc -l
HERE

#Zabbix mysql
cat >$zabbix_base_dir/etc/.my.cnf <<HERE
[mysql]
host     = $zabbix_db_host
port	 = $zabbix_db_port
user     = $zabbix_db_user
password = $zabbix_db_user_password
socket   = $zabbix_db_sock
[mysqladmin]
host     = $zabbix_db_host
port	 = $zabbix_db_port
user     = $zabbix_db_user
password = $zabbix_db_user_password
socket   = $zabbix_db_sock
HERE
cp -f $build_dir/zabbix-$zabbix_version/conf/zabbix_agentd/userparameter_mysql.conf $zabbix_base_dir/etc/zabbix_agentd.conf.d/
sed -i "s#/var/lib/zabbix#$zabbix_base_dir/etc#g" $zabbix_base_dir/etc/zabbix_agentd.conf.d/userparameter_mysql.conf

#start zabbix
chkconfig zabbix_agentd on
chkconfig --list zabbix_agentd 
service zabbix_agentd start
service zabbix_agentd status
}

echo "--------------------------------------------"
echo -e "\e[31;1mWether zabbix is installed or not\e[0m"
echo ""
if [ ! -x /etc/init.d/zabbix_agentd ];then
	echo ""
	echo -e "\e[31;1mInstalling zabbix\e[0m \e[34;1m... ...\e[0m"
#function
zabbix_install
else
        echo -e "\e[32;1mzabbix\e[0m is installed"
	service zabbix_agentd status
	exit 0
fi
