#################################################################
#!/bin/bash
#To ping hosts on list
#Made by LiuJun, liujun_live@msn.com ,  2015-05-01
#################################################################

#Export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

#Check files are exist whether or not
if [ -z $1 ] || [ ! -f $1 ];then
	echo -e "\e[36;1mUsage:\e[0m \e[32;1m$0\e[0m \e[31;1miplist\e[0m"
	exit 1
fi

#Define hosts related variables
hosts_list=$1

#Define fping function
fping_(){
	fping -c1 -A -b40 -Q1 -r2 -f $hosts_list 2>&1|awk -v date_flag=$(date +"%F-%H:%M:%S") '{print date_flag" "$0}' 
}

while true
do
	ping_log=/root/fping_$(date +%F).log
	fping_ &>>$ping_log
	echo "" >>$ping_log
	sleep 5
done
