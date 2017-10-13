###########################################################################
#!/bin/bash
#To install and configure mariadb from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2014-11-21
###########################################################################
#:<<TEST_SYNTAX
#########################################################
#Check source file 
#########################################################
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mmariadb-x.x.x.tar.gz\e[0m"
	exit 1
fi

#########################################################
#Check user & group 
#########################################################
user_group(){
mariadb_user=mysql
mariadb_group=mysql
user_flag=$(cat /etc/passwd|cut -d: -f1 |grep $mariadb_user)
group_flag=$(cat /etc/group|cut -d: -f1 |grep $mariadb_group)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m"
echo ""
if [ "$group_flag" = "" ];then
	groupadd -r $mariadb_group 
	echo -e "Group \e[32;1m$mariadb_group\e[0m is \e[33;1madded\e[0m"
else 
	echo -e "Group \e[32;1m$mariadb_group\e[0m is \e[31;1mexist\e[0m"
fi

if [ "$user_flag" = "" ];then
	useradd -r $mariadb_user   -g $mariadb_user -s /sbin/nologin
	echo -e "User \e[32;1m$mariadb_user\e[0m is \e[33;1madded\e[0m"
else
	echo -e "User \e[32;1m$mariadb_user\e[0m is \e[31;1mexist\e[0m"
fi
sleep 1
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
package="gcc gcc-c++ unzip gzip bzip2"
for i in $package
do
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
	if [ "$flag" != "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
if [ "$(which jemalloc-config 2>/dev/null)" == "" ];then
	jemalloc_tar=$(ls jemalloc-* 2>/dev/null)
	if [ -z "$jemalloc_tar" ];then
		wget -t 3 https://github.com/jemalloc/jemalloc/releases/download/4.0.4/jemalloc-4.0.4.tar.bz2 -O jemalloc-4.0.4.tar.bz2 --no-check-certificate
		jemalloc_tar=$(ls jemalloc-* 2>/dev/null)
		tar -xvf $jemalloc_tar -C $build_dir
		cd $build_dir/jemalloc-*
		./configure && make -j4 && make -j4 install
		ln -s /usr/local/lib/libjemalloc.so* /lib64/ 2>/dev/null
		ln -s /usr/local/lib/libjemalloc.so /lib64/libjemalloc.so.1 2>/dev/null
		ldconfig
		cd - >/dev/null
		echo -e "\e[32;1mjemalloc\e[0m is installed"
		echo ""
	else
		tar -xvf $jemalloc_tar -C $build_dir
		cd $build_dir/jemalloc-*
		./configure && make -j4 && make -j4 install
		ln -s /usr/local/lib/libjemalloc.so* /lib64/ 2>/dev/null
		ln -s /usr/local/lib/libjemalloc.so /lib64/libjemalloc.so.1 2>/dev/null
		ldconfig
		cd - >/dev/null
		echo -e "\e[32;1mjemalloc\e[0m is installed"
		echo ""
	fi
fi
}


#########################################################
#Variables
#########################################################
export mariadb_base_dir="/opt/mariadb"
export mariadb_data_dir="$mariadb_base_dir/data"
export mariadb_conf_dir="/etc"
export mariadb_sock="/tmp/mysql.sock"
export mariadb_pid="$mariadb_base_dir/mysqld.pid"
export mariadb_log="$mariadb_base_dir/log/mysqld.log"
export mariadb_log_dir="$mariadb_base_dir/log"
export build_dir="/opt"
export mariadb_tar=$1

#########################################################
#Building & Install
#########################################################
mariadb_install(){
user_group
libs
sleep 1
#########################################################
#Uncompress
#########################################################
#mariadb
tar -xvf $mariadb_tar -C $build_dir
mv $build_dir/mariadb-* $build_dir/mariadb
echo -e "\e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
#########################################################
#bin PATH & man PATH
#########################################################
echo "PATH=\$PATH:$mariadb_base_dir/bin" >>/etc/profile
source /etc/profile
echo "MANPATH $mariadb_base_dir/man" >>/etc/man.config
echo ""

#########################################################
#init mariadb
#########################################################
echo -e "\e[31;1mMariaDB \e[0m \e[32;1minit ...\e[0m"
sleep 2
$mariadb_base_dir/scripts/mysql_install_db --user=$mariadb_user --basedir=$mariadb_base_dir --datadir=$mariadb_data_dir
[ ! -d $mariadb_log_dir ] && mkdir -p $mariadb_log_dir
chown -R $mariadb_user:$mariadb_group $mariadb_base_dir/
echo ""
echo -e "\e[31;1mInit \e[0m \e[32;1mOK!\e[0m"

#########################################################
#Config file
#########################################################
mariadb_conf_file="/etc/my.cnf"
echo ""
sleep 2
cp -f $mariadb_base_dir/support-files/my-huge.cnf $mariadb_conf_file
sed -i "/\[mysqld\]/a log_error = $mariadb_log" $mariadb_conf_file
sed -i "/\[mysqld\]/a pid-file = $mariadb_pid" $mariadb_conf_file
sed -i "/^socket/c socket = $mariadb_sock" $mariadb_conf_file
echo -e "\e[31;1mCreate $mariadb_conf_file \e[0m \e[32;1msuccessfully!\e[0m"

#########################################################
#Check init.d shell script
#########################################################
echo ""
cp -f $mariadb_base_dir/support-files/mysql.server /etc/init.d/mysql
sed -i "/^basedir=/c basedir=$mariadb_base_dir" /etc/init.d/mysql
sed -i "/^datadir=/c datadir=$mariadb_data_dir" /etc/init.d/mysql
sed -i "/^basedir=/c basedir=$mariadb_base_dir" /opt/mariadb/bin/mysql_secure_installation
echo -e "\e[31;1mCreate /etc/init.d/mysql \e[0m \e[32;1msuccessfully!\e[0m"
#########################################################
#Check logrotate for mysql
#########################################################
cp -f $mariadb_base_dir/support-files/mysql-log-rotate /etc/logrotate.d
sed -i "s#/usr/local/mysql#$mariadb_base_dir#g" /etc/logrotate.d/mysql-log-rotate
sed -i "s#$mariadb_data_dir/mysqld.log#$mariadb_log#g" /etc/logrotate.d/mysql-log-rotate

echo ""
chmod +x /etc/init.d/mysql
chkconfig --add mysql
chkconfig mysql on
echo ""
service mysql start
service mysql status
if [ $? == 0 ];then
	echo -e "\e[31;1mMariaDB started \e[0m \e[32;1msuccessfully!\e[0m"
fi
}
echo "--------------------------------------------"
echo -e "\e[31;1mWether mysql is installed or not\e[0m"
echo ""
if [ ! -x /etc/init.d/mysql ];then
echo ""
echo -e "\e[31;1mInstalling mysql\e[0m \e[34;1m... ...\e[0m"
#function
mariadb_install
else
	echo -e "\e[32;1mMariaDB\e[0m is installed"
	service mysql status
	exit 0
fi
