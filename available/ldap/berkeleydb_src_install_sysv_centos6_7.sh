###########################################################################
#!/bin/bash
#To install and configure berkeleydb from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2016-05-12
###########################################################################

#########################################################
#Check source file 
#########################################################
if [ $# -ne 1 ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mdb-x.x.x\e[0m"
	exit 1
fi

#########################################################
#Install dependent libs
#########################################################
dependent_libs(){
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
}


#########################################################
#Variables
#########################################################
export berkeleydb_base_dir="/opt/berkeleydb"
export build_dir="/usr/local/src"
export berkeleydb_tar=$1
export berkeleydb_version=$(echo $berkeleydb_tar|grep -oP "(?<=db-).*(?=.tar.*)")

#########################################################
#Building & Install
#########################################################
berkeleydb_install() {
if [ ! -f $berkeleydb_base_dir/bin/db_recover ];then
	if [ ! -f $berkeleydb_tar ];then
		echo -e "\e[31;1mError\e[0m ($berkeleydb_tar)"
		exit 1
	fi

	dependent_libs

	tar -xvf $berkeleydb_tar -C $build_dir
	cd $build_dir/db-$berkeleydb_version/build_unix
	../dist/configure --prefix=$berkeleydb_base_dir
	make -j4 && make -j4 install
	ln -s $berkeleydb_base_dir/include/* /usr/include/ 2>/dev/null
	ln -s $berkeleydb_base_dir/lib/* /usr/local/lib64/ 2>/dev/null
	echo "$berkeleydb_base_dir/lib" >/etc/ld.so.conf.d/BerkeleyDB.conf
	ldconfig -f /etc/ld.so.conf
	cd - >/dev/null
	echo -e "\e[32;1mBerkeleyDB\e[0m is installed on \e[34;1m$berkeleydb_base_dir\e[0m"
	echo ""

	rpmdb --rebuilddb
else
	echo -e "\e[32;1m$berkeleydb_base_dir/bin/db_recover\e[0m is exist"
fi
}

#Main
berkeleydb_install
