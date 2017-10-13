#################################################################
#!/bin/bash
#To analyse fping_log
#Made by LiuJun, liujun_live@msn.com ,  2015-05-01
#################################################################

#Export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

#Define hosts related variables
hosts_list=/root/iplist
log=fping_2015-05-04.log

#Define fping function
#fping_analyse(){
#}
#for log in $(ls fping_*.log)
#do
	for ip in $(cat $hosts_list)
	do
		loss_count=$(grep -w $ip $log|awk '{print $1" "$2" "$NF}'|grep -v 100%|wc -l)
		noloss_count=$(grep -w $ip $log|awk '{print $1" "$2" "$NF}'|grep 100%|wc -l)
		loss
		exit 1
	done
#done 
