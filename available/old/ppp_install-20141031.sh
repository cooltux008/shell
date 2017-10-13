#################################################################
#!/bin/bash
#To install ppp pptp from yum automaticlly on CentOS
#Made by LiuJun, liujun_live@msn.com ,  2014-10-11
#################################################################

#Source function library.
. /etc/init.d/functions

#Export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

####################
#安装拔号软件ppp pptp
####################
echo "-----------------------------------------"
echo -e "\e[35;1mInstall ppp pptp\e[0m"
echo "-----------------------------------------"
sleep 1
packages="ppp pptp"
for pack in $packages
do
	flag=$(rpm -qa|grep $pack)
	if [  "$flag" == "" ];then
		yum -y install $pack 2>/dev/null
		else
			echo -e "\e[31;1m$pack\e[0m is \e[32;1minstalled\e[0m"
	fi
done

echo ""
echo ""
echo ""

####################
#配置拔号
####################
#后期维护,只需修改如下对应变量即可
vpn_server=10.162.51.165
vpn_user=test
vpn_password=a12345ASD
vpn_flag=vpn

echo "-----------------------------------------"
echo -e "\e[35;1mConfiguring vpn\e[0m"
echo "-----------------------------------------"
sleep 1
echo "$vpn_user $vpn_flag $vpn_password *" >/etc/ppp/chap-secrets
echo -e "Adding \e[31;1m$vpn_flag\e[0m to /etc/ppp/chap-secrets"
sleep 1

cat >/etc/ppp/peers/$vpn_flag <<HERE
pty "pptp $vpn_server --nolaunchpppd"
debug
nodetach
logfd 2
noproxyarp
ipparam $vpn_flag
remotename $vpn_flag
name $vpn_user
require-mppe-128
nobsdcomp
nodeflate
lock
noauth
refuse-eap
refuse-chap
refuse-mschap
HERE

cat >/etc/ppp/options <<HERE
require-mppe
require-mppe-128
mppe-stateful
HERE


echo -e "Adding auth_info to \e[31;1m$vpn_server\e[0m to /etc/ppp/peers/\e[31;1m$vpn_flag\e[0m"
echo ""
echo -e "Configuration \e[32;1msuccessfully!\e[0m"
