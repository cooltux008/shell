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
packages="gcc gcc-c++ autoconf make libcurl-devel libxml2-devel net-snmp-devel openldap-devel openssl-devel libssh2-devel unixODBC-devel OpenIPMI-devel mysql mysql-devel"
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
export nginx_root="/opt/nginx/html"
export php_ini="/usr/local/php/etc/php.ini"

export zabbix_server_host="localhost"
export zabbix_server_port="10051"
export zabbix_server_log="/tmp/zabbix_server.log"
 
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
--enable-server \
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
cp $build_dir/zabbix-$zabbix_version/misc/init.d/fedora/core/* /etc/init.d/
chmod +x /etc/init.d/zabbix_*
sed -i "/BASEDIR=/s#/usr/local#$zabbix_base_dir#g" /etc/init.d/zabbix_*

#########################################################
#Config file
#########################################################

#Zabbix server
mv $zabbix_base_dir/etc/zabbix_server.conf{,.default}
cat >$zabbix_base_dir/etc/zabbix_server.conf <<HERE
#ListenIP=
ListenPort=$zabbix_server_port
LogFile=$zabbix_server_log
LogFileSize=2
DebugLevel=3
DBSocket=$zabbix_db_sock
DBHost=$zabbix_db_host
DBPort=$zabbix_db_port
DBName=$zabbix_db
DBUser=$zabbix_db_user
DBPassword=$zabbix_db_user_password
CacheSize=16M
Timeout=10
TrapperTimeout=300
StartDBSyncers=4
StartDiscoverers=4
StartHTTPPollers=4
StartIPMIPollers=4
FpingLocation=/usr/local/sbin/fping
Fping6Location=/usr/local/sbin/fping6
Include=$zabbix_base_dir/etc/zabbix_server.conf.d/*.conf
HERE

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

#Mysql
if [ -d $mysql_base_dir ];then
	echo -e "\e[31;1mCreate\e[0m \e[32;1mzabbix database\e[0m"
	mysql -u$zabbix_db_user -p$zabbix_db_user_password -h$zabbix_db_host -P$zabbix_db_port -e "drop database if exists zabbix;create database zabbix default charset utf8;"
	if [ $? != 0 ];then
		echo -e "\e[31;1mDatabase ERROR\e[0m"
		exit 1
	fi

	echo -e "\e[31;1mImporting\e[0m \e[32;1mschema.sql\e[0m"
	mysql -u$zabbix_db_user -p$zabbix_db_user_password -h$zabbix_db_host -P$zabbix_db_port $zabbix_db <$build_dir/zabbix-$zabbix_version/database/mysql/schema.sql
	echo -e "\e[31;1mImporting\e[0m \e[32;1mimages.sql\e[0m"
	mysql -u$zabbix_db_user -p$zabbix_db_user_password -h$zabbix_db_host -P$zabbix_db_port $zabbix_db <$build_dir/zabbix-$zabbix_version/database/mysql/images.sql
	echo -e "\e[31;1mImporting\e[0m \e[32;1mdata.sql\e[0m"
	mysql -u$zabbix_db_user -p$zabbix_db_user_password -h$zabbix_db_host -P$zabbix_db_port $zabbix_db <$build_dir/zabbix-$zabbix_version/database/mysql/data.sql
	echo -e "\e[32;1mDone\e[0m"
	echo ""
fi

#php.ini
if [ -f $php_ini ];then
	sed -i '/max_execution_time =/c max_execution_time=300' $php_ini
	sed -i '/memory_limit =/c memory_limit=128M' $php_ini
	sed -i '/post_max_size =/c post_max_size=16M' $php_ini
	sed -i '/upload_max_filesize =/c upload_max_filesize=2M' $php_ini
	sed -i '/max_input_time =/c max_input_time=300' $php_ini
	sed -i '/date.timezone =/c date.timezone=Asia/Shanghai' $php_ini
	sed -i '/^;always_populate_raw_post_data/s/^;//' $php_ini
fi

#Nginx
if [ -d $nginx_root ];then
	cp -a $build_dir/zabbix-$zabbix_version/frontends/php/ $nginx_root/zabbix
	chmod -R o+w $nginx_root/zabbix/conf

	#zabbix zh_CN
	sed -i '/zh_CN/s/false/true/g' $nginx_root/zabbix/include/locales.inc.php
fi

#start zabbix
chkconfig zabbix_server on
chkconfig zabbix_agentd on
chkconfig --list zabbix_server
chkconfig --list zabbix_agentd 
service zabbix_server start
service zabbix_agentd start
service zabbix_server status
service zabbix_agentd status
}

echo "--------------------------------------------"
echo -e "\e[31;1mWether zabbix is installed or not\e[0m"
echo ""
if [ ! -x /etc/init.d/zabbix_server ];then
	echo ""
	echo -e "\e[31;1mInstalling zabbix\e[0m \e[34;1m... ...\e[0m"
#function
zabbix_install
else
        echo -e "\e[32;1mzabbix\e[0m is installed"
	service zabbix_server status
	service zabbix_agentd status
	exit 0
fi
