###########################################################################
#!/bin/bash
#To install and configure memcached from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2016-05-12
###########################################################################
#:<<TEST_SYNTAX
#########################################################
#Check source file 
#########################################################
if [ $# -ne 1 ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mmemcached-x.x.x\e[0m"
	exit 1
fi

#########################################################
#Variables
#########################################################
export memcached_user=memcached
export memcached_group=memcached
export package="gcc gcc-c++ unzip gzip bzip2 libevent-devel cyrus-sasl-devel systemtap-sdt-devel"

export memcached_base_dir="/opt/memcached"
export memcached_port=11211
export memcached_maxconn=1024
export memcached_maxmem=2048
export memcached_options="-U 0"

export build_dir="/usr/local/src"
export memcached_tar=$1
#########################################################
#Check user & group 
#########################################################
user_group(){
user_flag=$(cat /etc/passwd|cut -d: -f1 |grep $memcached_user)
group_flag=$(cat /etc/group|cut -d: -f1 |grep $memcached_group)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m\n"
if [ "$group_flag" = "" ];then
	groupadd -r $memcached_group 
	echo -e "Group \e[32;1m$memcached_group\e[0m is \e[33;1madded\e[0m"
else 
	echo -e "Group \e[32;1m$memcached_group\e[0m is \e[31;1mexist\e[0m"
fi

if [ "$user_flag" = "" ];then
	useradd -m -r $memcached_user -g $memcached_group -s /sbin/nologin
	echo -e "User \e[32;1m$memcached_user\e[0m is \e[33;1madded\e[0m"
else
	echo -e "User \e[32;1m$memcached_user\e[0m is \e[31;1mexist\e[0m"
fi
echo -e "\n"
sleep 1
}

#########################################################
#Install dependent libs 
#########################################################
dependent_libs(){
echo "--------------------------------------------"
echo -e "Check \e[31;1mlibs developed\e[0m\n"
for i in $package
do
	flag=$(rpm -qa|grep -w $i|grep -v bzip2-libs)
	if [ "$flag" == "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}


#########################################################
#Building & Install
#########################################################
memcached_install(){
tar -xvf $memcached_tar -C $build_dir
cd $build_dir/memcached-*
./configure --prefix=$memcached_base_dir \
--enable-sasl \
--enable-sasl-pwdb \
--enable-dtrace \
--enable-64bit
make -j4 && make -j4 install
 
cp -a $memcached_base_dir/share/man/* /usr/share/man/
cp -a $build_dir/memcached-*/scripts $memcached_base_dir
cd - >/dev/null
}

#########################################################
#Check init.d shell script
#########################################################
memcached_init_script(){
echo ""
rhel_version=$(uname -r|awk -F'-' '{print $1}')
if [ "$rhel_version" == "3.10.0" ];then
	cp -f $memcached_base_dir/scripts/memcached.service /lib/systemd/system/
	sed -i "/^ExecStart=/s#/usr#$memcached_base_dir#" /lib/systemd/system/memcached.service
	cat >/etc/sysconfig/memcached <<HERE
PORT=$memcached_port
USER=$memcached_user
CACHESIZE=$memcached_maxmem
MAXCONN=$memcached_maxconn
OPTIONS="$memcached_options"
HERE
elif [ "$rhel_version" == "2.6.32" ];then
	cp -f $memcached_base_dir/scripts/memcached.sysv /etc/init.d/memcached
	sed -i "s#daemon memcached#daemon $memcached_base_dir/bin/memcached#" /etc/init.d/memcached
	sed -i "/^PORT=/c PORT=$memcached_port" /etc/init.d/memcached
	sed -i "/^USER=/c USER=$memcached_user" /etc/init.d/memcached
	sed -i "/^MAXCONN=/c MAXCONN=$memcached_maxconn" /etc/init.d/memcached
	sed -i "/^CACHESIZE=/c CACHESIZE=$memcached_maxmem" /etc/init.d/memcached
	sed -i "/^OPTIONS=/c OPTIONS=\"$memcached_options\"" /etc/init.d/memcached
	chmod +x /etc/init.d/memcached
fi

[ $? -eq 0 ] && echo -e "\e[31;1mCreate /etc/init.d/memcached \e[0m \e[32;1msuccessfully!\e[0m" || (echo -e "/etc/init.d/memcached \e[31;1merror\e[0m";exit 1)
echo ""
echo ""

mkdir -p /var/run/memcached/
chown -R $memcached_user:$memcached_group $memcached_base_dir
chkconfig memcached on
service memcached start
service memcached status
if [ $? == 0 ];then
	echo -e "\e[31;1mMemcached started \e[0m \e[32;1msuccessfully!\e[0m"
fi
}

#########################################################
#Main
#########################################################
if [ ! -f $memcached_tar ];then
	echo -e "\e[31;1mError\e[0m ($memcached_tar)"
	exit 1
fi
echo "--------------------------------------------"
echo -e "\e[31;1mWether memcached is installed or not\e[0m"
if [ ! -x /etc/init.d/memcached -a ! -f /lib/systemd/system/memcached.service ];then
	echo -e "\n\e[31;1mInstalling memcached\e[0m \e[34;1m... ...\e[0m"
	user_group
	dependent_libs
	memcached_install
	memcached_init_script
else
	echo -e "\n\e[32;1mMemcached\e[0m is installed on \e[34;1m$memcached_base_dir\e[0m"
	service memcached status
	exit 0
fi
