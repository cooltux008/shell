###########################################################################
#!/bin/bash
#To install and configure openldap from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2016-05-12
###########################################################################
#:<<TEST_SYNTAX
#########################################################
#Check source file 
#########################################################
if [ $# -ne 1 ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mopenldap-x.x.x\e[0m"
	exit 1
fi

#########################################################
#Variables
#########################################################
export openldap_user=openldap
export openldap_group=openldap
export package="gcc gcc-c++ unzip gzip bzip2 openssl-devel cyrus-sasl-devel krb5-devel tcp_wrappers-devel libtool-ltdl-devel openslp-devel unixODBC-devel mysql-devel libdb-devel"

#export berkeleydb_base_dir="/opt/berkeleydb"

export openldap_base_dir="/opt/openldap"
export openldap_conf_file="$openldap_base_dir/etc/openldap/slapd.conf"
export openldap_log_dir="$openldap_base_dir/var/logs"

export build_dir="/usr/local/src"
export openldap_tar=$1
export openldap_version=$(echo $openldap_tar|grep -oP "(?<=openldap-).*(?=.tgz|.tbz2|.tar.gz|.tar.bz2)")

export suffix='"dc=example,dc=com"'
export rootdn='"cn=Manager,dc=example,dc=com"'
export rootpw="secret"

#########################################################
#Check user & group 
#########################################################
user_group(){
user_flag=$(cat /etc/passwd|cut -d: -f1 |grep $openldap_user)
group_flag=$(cat /etc/group|cut -d: -f1 |grep $openldap_group)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m\n"
if [ "$group_flag" = "" ];then
	groupadd -r $openldap_group 
	echo -e "Group \e[32;1m$openldap_group\e[0m is \e[33;1madded\e[0m"
else 
	echo -e "Group \e[32;1m$openldap_group\e[0m is \e[31;1mexist\e[0m"
fi

if [ "$user_flag" = "" ];then
	useradd -m -r $openldap_user -g $openldap_group -s /sbin/nologin
	echo -e "User \e[32;1m$openldap_user\e[0m is \e[33;1madded\e[0m"
else
	echo -e "User \e[32;1m$openldap_user\e[0m is \e[31;1mexist\e[0m"
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
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
	if [ "$flag" != "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}


#########################################################
#Building & Install
#########################################################
berkeleydb_install(){
if [ -z "$berkeleydb_base_dir" ];then
	rhel_version=$(uname -r|awk -F'-' '{print $1}')
	if [ "$rhel_version" == "3.10.0" ];then
		flag=$(rpm -q compat-db|grep "not installed")
		[ "$flag" != "" ] && yum -y install compat-db || echo -e "\e[32;1mcompat-db\e[0m is installed"
		ln -s /usr/include/db4.*/* /usr/include/ 2>/dev/null
	elif [ "$rhel_version" == "2.6.32" ];then
		flag=$(rpm -qa|grep -w db4-devel|grep -v bzip2-libs)
		[ "$flag" == "" ] && yum -y install db4-devel || echo -e "\e[32;1mdb4-devel\e[0m is installed"
	fi
fi
echo -e "BerkeleyDB \e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
sleep 1
}

openldap_install(){
tar -xvf $openldap_tar -C $build_dir
cd $build_dir/openldap-$openldap_version
./configure --prefix=$openldap_base_dir \
--enable-slapd \
--enable-dynacl  \
--enable-aci     \
--enable-cleartext \
--enable-crypt   \
--enable-lmpasswd \
--enable-spasswd \
--enable-modules \
--enable-rewrite \
--enable-rlookups \
--enable-slapi \
--enable-wrappers \
--enable-backends \
--enable-ndb=no \
--enable-perl=no \
--enable-overlays
make -j4 && make -j4 install
 
cp -a $openldap_base_dir/share/man/* /usr/share/man/
ln -s $openldap_base_dir/bin/* /usr/local/bin 2>/dev/null
ln -s $openldap_base_dir/sbin/* /usr/local/sbin 2>/dev/null
$openldap_base_dir/libexec/slapd
[ $? -eq 0 ] && echo -e "OpenLDAP \e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
cd - >/dev/null
}

#########################################################
#Config file
#########################################################
openldap_config(){
cat >$openldap_conf_file <<HERE
include $openldap_base_dir/etc/openldap/schema/core.schema
include $openldap_base_dir/etc/openldap/schema/collective.schema
include $openldap_base_dir/etc/openldap/schema/corba.schema
include $openldap_base_dir/etc/openldap/schema/cosine.schema
include $openldap_base_dir/etc/openldap/schema/duaconf.schema
include $openldap_base_dir/etc/openldap/schema/dyngroup.schema
include $openldap_base_dir/etc/openldap/schema/inetorgperson.schema
include $openldap_base_dir/etc/openldap/schema/java.schema
include $openldap_base_dir/etc/openldap/schema/misc.schema
include $openldap_base_dir/etc/openldap/schema/nis.schema
include $openldap_base_dir/etc/openldap/schema/openldap.schema
include $openldap_base_dir/etc/openldap/schema/ppolicy.schema
include $openldap_base_dir/etc/openldap/schema/pmi.schema

pidfile $openldap_base_dir/var/run/slapd.pid
argsfile $openldap_base_dir/var/run/slapd.args

loglevel 256
logfile  $openldap_log_dir/slapd.log

database mdb
maxsize 1073741824
suffix $suffix
rootdn $rootdn
rootpw $rootpw
directory $openldap_base_dir/var/openldap-data
index objectClass eq

#TLSCACertificateFile  $openldap_base_dir/etc/ca.perm
#TLSCertificateFile    $openldap_base_dir/etc/openldap.crt
#TLSCertificateKeyFile $openldap_base_dir/etc/openldap.key
HERE
mkdir -p $openldap_base_dir/etc/openldap/slapd.d 
$openldap_base_dir/sbin/slaptest -f $openldap_conf_file -F $openldap_base_dir/etc/openldap/slapd.d
[ $? -eq 0 ] && echo -e "\e[31;1mCreate $openldap_conf_file \e[0m \e[32;1msuccessfully!\e[0m" || (echo -e "Init \e[31;1merror\e[0m";exit 1)
}

#########################################################
#Check init.d shell script
#########################################################
openldap_init_script(){
echo ""
mv slapd /etc/init.d
chmod +x /etc/init.d/slapd
chkconfig slapd on
echo ""
chown -R $openldap_user: $openldap_base_dir
service slapd restart
service slapd status
if [ $? == 0 ];then
	echo -e "\e[31;1mOpenLDAP started \e[0m \e[32;1msuccessfully!\e[0m"
fi
}


#########################################################
#Check logrotate for openldap
#########################################################
openldap_logrotate(){
mkdir -p $openldap_log_dir
cat >/etc/rsyslog.d/slapd.conf <<HERE
local4.* $openldap_log_dir/slapd.log
HERE
cat >/etc/logrotate.d/slapd <<HERE
$openldap_log_dir/*log {
	missingok
	compress
	notifempty
	daily
	rotate 5
	create 0600 root root
}
HERE
service rsyslog restart
}

#########################################################
#Main
#########################################################
if [ ! -f $openldap_tar ];then
	echo -e "\e[31;1mError\e[0m ($openldap_tar)"
	exit 1
fi
echo "--------------------------------------------"
echo -e "\e[31;1mWether openldap is installed or not\e[0m"
if [ ! -x /etc/init.d/slapd ];then
	echo -e "\n\e[31;1mInstalling openldap\e[0m \e[34;1m... ...\e[0m"
	user_group
	berkeleydb_install
	dependent_libs
	openldap_install
	openldap_config
	openldap_logrotate
	openldap_init_script
else
	echo -e "\n\e[32;1mOpenLDAP\e[0m is installed on \e[34;1m$openldap_base_dir\e[0m"
	service slapd status
	exit 0
fi
