#################################################################
#!/bin/bash
#To install cronolog from tarbar automaticlly on CentOS
#Made by LiuJun, liujun_live@msn.com ,  2014-10-13
#################################################################

#Source function library.
. /etc/init.d/functions

#Export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

####################
#准备系统环境
####################

#通过yum升级所有可用更新
echo "-----------------------------------------"
echo -e "\e[35;1mSystem update\e[0m"
echo "-----------------------------------------"
sleep 1
#yum -y update 2>/dev/null
echo ""
echo ""

#准备编译工具及依赖库
echo "-----------------------------------------"
echo -e "\e[35;1mInstall development tools\e[0m"
echo "-----------------------------------------"
sleep 1
#yum -y groupinstall "Development Tools" 2>/dev/null
yum -y install gcc gcc-c++ automake autoconf zlib zlib-devel 2>/dev/null
echo ""
echo ""

####################
#安装Cronolog
####################
#进入到临时安装目录
cd /usr/local/src

#下载tar包
#程序版本号，后期维护只需必版本号即可
Cronolog_edition=1.6.2
#程序URL路径
URL_cronolog=http://cronolog.org/download/cronolog-$Cronolog_edition.tar.gz
#程序包完整名,如:Python-3.4.1.tar.xz
Cronolog=$(basename $URL_cronolog)

echo ""
echo ""
echo "-----------------------------------------"
echo -e "\e[35;1mDownloading cronolog\e[0m"
echo "-----------------------------------------"
sleep 1
if [ ! -f $Cronolog ];then
	wget --tries=3 --no-check-certificate $URL_cronolog
else
	echo -e "/usr/local/src/\e[31;1m$Cronolog\e[0m is \e[32;1mexist!\e[0m"
fi
sleep 2
echo ""
echo ""

#安装cronolog
echo "-----------------------------------------"
echo -e "\e[35;1mInstalling cronolog-\e[0m\e[31;1m$Cronolog_edition\e[0m"
echo "-----------------------------------------"
sleep 1

if [ ! -x /usr/local/sbin/cronolog ];then
	rm -rf Cronolog-$Cronolog_edition &>/dev/null
	tar -xvf $Cronolog
	cd cronolog-$Cronolog_edition
	./configure && make && make install
	cd ..
	echo ""
fi
#检查cronolog是否安装成功
Flag=$(cronolog -V 2>&1)
if [ ! "$Flag" == "" ];then
	echo -e "\e[31;1m$Flag\e[0m is installed \e[32;1msuccessfully!\e[0m"
else
	echo -e "\e[31;1mError!\e[0m"
fi
echo ""
echo ""
