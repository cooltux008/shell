###########################################################################
#!/bin/bash
#To install and configure php&php-fpm from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2015-05-04
###########################################################################
#########################################################
#Check source file 
#########################################################
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mphp-x.x.x.tar.gz\e[0m"
	exit 1
fi

#########################################################
#Check user & group 
#########################################################
php_fpm_user=php-fpm
php_fpm_group=php-fpm
user_group(){
user_flag=$(cat /etc/passwd|cut -d: -f1 |grep $php_fpm_user)
group_flag=$(cat /etc/group|cut -d: -f1 |grep $php_fpm_group)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m"
echo ""
if [ "$group_flag" = "" ];then
	groupadd -r $php_fpm_group 
	echo -e "\e[32;1mGroup $php_fpm_group\e[0m is added"
else 
	echo -e "\e[32;1mGroup\e[0m $php_fpm_group is exist"
fi

if [ "$user_flag" = "" ];then
	useradd -r $php_fpm_user   -g $php_fpm_user -s /sbin/nologin
	echo -e "\e[32;1mUser $php_fpm_user\e[0m is added"
else
	echo -e "\e[32;1mUser\e[0m $php_fpm_user is exist"
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
package="gcc gcc-c++ libxml2-devel openssl-devel pcre-devel libcurl-devel gd-devel bzip2 bzip2-devel freetype-devel giflib-devel openjpeg-devel readline-devel libedit-devel httpd-devel"
for i in $package
do
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
        if [ "$flag" != "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}


#########################################################
#Variables
#########################################################
export php_base_dir="/usr/local/php"
export php_conf_dir="/usr/local/php/etc"
export php_conf_include="/usr/local/php/etc/php.d"
export build_dir="/usr/local/src"
export php_tar=$1
export php_version=$(echo $php_tar|grep -oP "(?<=php-).*(?=.tar.*)")

#########################################################
#Building & Install
#########################################################
php_install(){
user_group
libs
sleep 1
#########################################################
#Building
#########################################################
libmcrypt=libmcrypt-2.5.7.tar.gz
mhash=mhash-0.9.9.9.tar.gz
mcrypt=mcrypt-2.6.4.tar.gz
#libmcrypt
if [ -f $libmcrypt ];then
	tar -xvf $libmcrypt -C /usr/local/src
	cd /usr/local/src/libmcrypt-*
	./configure && make -j4 && make install
	ldconfig
	cd -
	echo -e "\e[31;1m$libmcrypt\e[0m is installed"
	echo ""
	sleep 1
else
	echo -e "\e[31;1m$libmcrypt\e[0m is not exsit"
	exit 1
fi
#mhash
if [ -f $mhash ];then
	tar -xvf $mhash -C /usr/local/src
	cd /usr/local/src/mhash-*
	./configure && make -j4 && make install
	ldconfig
	cd -
	echo -e "\e[31;1m$mhash\e[0m is installed"
	echo ""
	sleep 1
else
	echo -e "\e[31;1m$mhash\e[0m is not exsit"
	exit 1
fi
#mcrypt
if [ -f $mcrypt ];then
	tar -xvf $mcrypt -C /usr/local/src
	cd /usr/local/src/mcrypt-*
	LD_LIBRARY_PATH=/usr/local/lib ./configure && make -j4 && make install
	ldconfig
	cd -
	echo -e "\e[31;1m$mcrypt\e[0m is installed"
	echo ""
	sleep 1
else
	echo -e "\e[31;1m$mcrypt\e[0m is not exsit"
	exit 1
fi
#php
tar -xvf $php_tar -C $build_dir
cd $build_dir/php-$php_version
./configure \
--prefix=$php_base_dir \
--with-config-file-path=$php_conf_dir \
--with-config-file-scan-dir=$php_conf_include \
--with-fpm-group=$php_fpm_group \
--with-fpm-user=$php_fpm_user \
--enable-inline-optimization \
--enable-pcntl \
--enable-shmop \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--enable-sockets \
--enable-shared \
--enable-opcache \
--enable-bcmath \
--enable-soap \
--enable-zip \
--enable-gd-native-ttf  \
--enable-ftp \
--enable-fpm \
--enable-mbstring \
--enable-calendar \
--enable-dom \
--enable-xml \
--with-pear \
--with-pcre-regex \
--with-curl \
--with-bz2 \
--with-zlib \
--with-gd \
--with-gettext  \
--with-jpeg-dir=/usr/local  \
--with-png-dir=/usr/local  \
--with-iconv-dir=/usr/local  \
--with-freetype-dir=/usr/local  \
--with-libxml-dir=/usr/local  \
--with-readline  \
--with-iconv  \
--with-mcrypt  \
--with-mhash  \
--with-openssl  \
--with-mysql=mysqlnd  \
--with-mysqli=mysqlnd  \
--with-pdo-mysql=mysqlnd  \
--with-apxs2=$(which apxs) \
--disable-debug \
--disable-fileinfo
make -j4 && make -j4 install
if [ $? == 0 ];then
	echo -e "\e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
fi
#########################################################
#bin PATH 
#########################################################
echo "PATH=$php_base_dir/bin:$php_base_dir/sbin:$PATH" >>/etc/profile
source /etc/profile

#########################################################
#Config file
#########################################################
cp -f $php_conf_dir/php-fpm.conf.default $php_conf_dir/php-fpm.conf
sed -i '/127.0.0.1:9000/c listen = /dev/shm/php-fpm.sock' $php_conf_dir/php-fpm.conf
sed -i '/;listen.owner/s/^;//g' $php_conf_dir/php-fpm.conf
sed -i '/;listen.group/s/^;//g' $php_conf_dir/php-fpm.conf
sed -i '/;listen.mode/c listen.mode = 0666' $php_conf_dir/php-fpm.conf
cp -f $build_dir/php-$php_version/php.ini-production $php_conf_dir/php.ini
#for php-7.x
cp -f $php_conf_dir/php-fpm.d/www.conf.default $php_conf_dir/php-fpm.d/www.conf 2>/dev/null 
sed -i '/127.0.0.1:9000/c listen = /dev/shm/php-fpm.sock' $php_conf_dir/php-fpm.d/www.conf 2>/dev/null 
sed -i '/;listen.owner/s/^;//g' $php_conf_dir/php-fpm.d/www.conf 2>/dev/null 
sed -i '/;listen.group/s/^;//g' $php_conf_dir/php-fpm.d/www.conf 2>/dev/null 
sed -i '/;listen.mode/c listen.mode = 0666' $php_conf_dir/php-fpm.d/www.conf 2>/dev/null 


#########################################################
#Check init.d shell script
#########################################################
cp -f $build_dir/php-$php_version/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
#sed -i '71 a chmod 666 /dev/shm/php-fpm.sock &>/dev/null' /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on
echo ""
service php-fpm start
if [ $? == 0 ];then
	echo -e "\e[31;1mphp-fpm started \e[0m \e[32;1msuccessfully!\e[0m"
fi
}

echo "--------------------------------------------"
echo -e "\e[31;1mWether php-fpm is installed or not\e[0m"
echo ""
if [ ! -x /etc/init.d/php-fpm ];then
	echo ""
	echo -e "\e[31;1mInstalling php-fpm\e[0m \e[34;1m... ...\e[0m"
	#function
	php_install
else
	echo -e "\e[32;1mphp-fpm\e[0m is installed"
	service php-fpm status
	exit 0
fi
