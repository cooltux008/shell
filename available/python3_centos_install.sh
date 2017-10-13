#################################################################
#!/bin/bash
#To install python3 from tarbar automaticlly on CentOS
#Made by LiuJun, liujun_live@sina.com ,  2014-10-11
#################################################################

#Variables
export package="gcc gcc-c++ readline-devel openssl-devel zlib zlib-devel sqlite-devel bzip2-devel"
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
echo ""

#ENV
build_dir=/usr/local/src
python3_base_dir=/opt/python3
python3_edition=3.5.2
url_python3=https://www.python.org/ftp/python/$python3_edition/Python-$python3_edition.tgz
python3=$(basename $url_python3)


#download python3 & extend
cd $build_dir
if [ ! -f $python3 ];then
	echo -e "\e[34;1mdownloading $python3\e[0m"
	curl -L $url_python3 --retry 3 -o $python3
else
	echo -e "$build_dir/\e[31;1m$python3\e[0m is \e[32;1mexist!\e[0m"
fi

#install python3
echo "-----------------------------------------"
echo -e "\e[35;1mInstalling python-\e[0m\e[31;1m$python3_edition\e[0m"
echo "-----------------------------------------"
sleep 1
if [ -z $(which python3 2>/dev/null) ];then
	rm -rf Python-$python3_edition 
	tar -xvf $python3
	cd Python-$python3_edition
	./configure --prefix=$python3_base_dir
	sed -i 's/#zlib zlibmodule.c/zlib zlibmodule.c/g' Modules/Setup &>/dev/null
	make -j4 && make -j4 install
	cd ..
	echo ""
fi

#check python3
flag=$($python3_base_dir/bin/python3 -V 2>/dev/null)
if [ ! "$flag" == "" ];then
	echo -e "\e[31;1m$flag\e[0m is installed \e[32;1msuccessfully!\e[0m"
else
	echo -e "\e[31;1mError!\e[0m"
fi

#PATH
echo "export PATH=$python3_base_dir/bin:\$PATH" >>/etc/profile
source /etc/profile

#MAN
cp -a $python3_base_dir/share/man/* /usr/local/share/man/
