###########################################################################
#!/bin/bash
#To install and configure httpd from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2015-11-01
###########################################################################
#:<<TEST_SYNTAX
#########################################################
#Check source file 
#########################################################
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mhttpd-x.x.x.tar.gz\e[0m"
	exit 1
fi

#########################################################
#Check user & group 
#########################################################
user_group(){
httpd_user=apache
httpd_group=apache
user_flag=$(cat /etc/passwd|cut -d: -f1 |grep $httpd_user)
group_flag=$(cat /etc/group|cut -d: -f1 |grep $httpd_group)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m"
echo ""
if [ "$group_flag" = "" ];then
	groupadd -r $httpd_group 
	echo -e "\e[32;1mGroup $httpd_group\e[0m is added"
else 
	echo -e "\e[32;1mGroup\e[0m $httpd_group is exist"
fi

if [ "$user_flag" = "" ];then
	useradd -r $httpd_user   -g $httpd_user -s /sbin/nologin
	echo -e "\e[32;1mUser $httpd_user\e[0m is added"
else
	echo -e "\e[32;1mUser\e[0m $httpd_user is exist"
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
for package in $(rpm -qa|grep httpd)
do
    rpm -e --nodeps $package
done
package="gcc gcc-c++ zlib zlib-devel"
for i in $package
do
	flag=$(rpm -qa|grep -w $i)
	if [ "$flag" == "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}


#########################################################
#Variables
#########################################################
export httpd_install_dir="/opt/apache/httpd"
export apr_install_dir="/opt/apache/apr"
export apr_util_install_dir="/opt/apache/apr-util"
export pcre_install_dir="/opt/apache/pcre"
export build_dir="/usr/local/src"
export httpd_tar=$1

#########################################################
#Building & Install
#########################################################
httpd_install(){
user_group
libs
sleep 1
#########################################################
#Build
#########################################################
apr=$(ls apr-*.tar*|grep -v apr-util)
apr_util=$(ls apr-util-*.tar*)
pcre=$(ls pcre-*.tar*)
#apr
if [ -f $apr ];then
	tar -xvf $apr -C /usr/local/src
	cd /usr/local/src/apr-*
	./configure --prefix=$apr_install_dir && make -j4 && make install
	ldconfig
	cd -
	echo -e "\e[31;1m$apr\e[0m is installed"
	echo ""
	sleep 1
else
	echo -e "\e[31;1m$apr\e[0m is not exsit"
	exit 1
fi
#apr-util
if [ -f $apr_util ];then
	tar -xvf $apr_util -C /usr/local/src
	cd /usr/local/src/apr-util-*
	./configure --prefix=$apr_util_install_dir --with-apr=$apr_install_dir && make -j4 && make install
	ldconfig
	cd -
	echo -e "\e[31;1m$apr_util\e[0m is installed"
	echo ""
	sleep 1
else
	echo -e "\e[31;1m$apr_util\e[0m is not exsit"
	exit 1
fi
#pcre
if [ -f $pcre ];then
	tar -xvf $pcre -C /usr/local/src
	cd /usr/local/src/pcre-*
	./configure --prefix=$pcre_install_dir && make -j4 && make install
	ldconfig
	cd -
	echo -e "\e[31;1m$pcre\e[0m is installed"
	echo ""
	sleep 1
else
	echo -e "\e[31;1m$pcre\e[0m is not exsit"
	exit 1
fi

#httpd
tar -xvf $httpd_tar -C $build_dir
cd $build_dir/httpd-*
./configure \
--prefix=$httpd_install_dir \
--enable-rewrite \
--enable-so \
--enable-headers \
--enable-expires \
--enable-modules=most \
--enable-deflate \
--enable-rewrite=shared \
--enable-deflate=shared \
--enable-expires=shared \
--enable-static-support \
--with-mpm=worker \
--with-apr=$apr_install_dir \
--with-apr-util=$apr_util_install_dir \
--with-pcre=$pcre_install_dir
if [ $? == 0 ];then
	make -j4 && make install
	echo -e "\e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
	#########################################################
	#bin PATH & man PATH
	#########################################################
	echo 'PATH=$PATH:/opt/apache/httpd/bin' >>/etc/profile
	source /etc/profile
	echo 'MANPATH /opt/apache/httpd/man' >>/etc/man.config
	echo ""

	#########################################################
	#Check init.d shell script
	#########################################################
	echo ""
	httpd_init=/etc/init.d/httpd 
	cp -f $build_dir/httpd-*/build/rpm/httpd.init $httpd_init
	sed -i "/httpd=/i HTTPD=$httpd_install_dir/bin/httpd" $httpd_init
	sed -i "/httpd=/i PIDFILE=$httpd_install_dir/logs/httpd.pid" $httpd_init
	sed -i "/CONFFILE=/ s#/etc/httpd#$httpd_install_dir#g" $httpd_init
	echo -e "\e[31;1mCreate $httpd_init \e[0m \e[32;1msuccessfully!\e[0m"

	htcacheclean_init=/etc/init.d/htcacheclean 
	cp /usr/local/src/httpd-*/build/rpm/htcacheclean.init /etc/init.d/htcacheclean
	sed -i "/htcacheclean=/i HTTPD=/opt/apache/httpd/bin/htcacheclean" /etc/init.d/htcacheclean
	sed -i "/htcacheclean=/i CACHEPATH=/opt/apache/httpd/cache-root" /etc/init.d/htcacheclean
	sed -i "/^pidfile=/c pidfile=/opt/apache/httpd/logs/${prog}.pid" /etc/init.d/htcacheclean
	mkdir -p /opt/apache/httpd/cache-root
	#########################################################
	#Check logrotate for httpd
	#########################################################
	cp -f $build_dir/httpd-*/build/rpm/httpd.logrotate /etc/logrotate.d
	sed -i "1c $httpd_install_dir/logs/*.log {" /etc/logrotate.d/httpd.logrotate

	echo ""
	chmod +x $httpd_init
	chmod +x $htcacheclean_init
	chkconfig --add httpd
	chkconfig --add htcacheclean
	chkconfig httpd on
	chkconfig htcacheclean on
	echo ""
	service httpd start
	service httpd status
	service htcacheclean start
	service htcacheclean status
	if [ $? == 0 ];then
		echo -e "\e[31;1mhttpd started \e[0m \e[32;1msuccessfully!\e[0m"
	fi
else
	echo -e "\e[31;1mError\e[0m"
	echo ""
	exit 1
fi
}
echo "--------------------------------------------"
echo -e "\e[31;1mWether httpd is installed or not\e[0m"
echo ""
if [ ! -x /etc/init.d/httpd ];then
echo ""
echo -e "\e[31;1mInstalling httpd\e[0m \e[34;1m... ...\e[0m"
#function
httpd_install
else
	echo -e "\e[32;1mhttpd\e[0m is installed"
	service httpd status
	exit 0
fi
