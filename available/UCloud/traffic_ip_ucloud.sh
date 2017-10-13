##################################################
#!/bin/env bash
#To recode IP traffic data
#Made by liujun,jlive.liu@ucloud.cn,2015-03-31
##################################################

#Check nginx source file 
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mfoo.data\e[0m"
	exit 1
fi
source_data=$1
new_data=$(pwd)/new_data.data

awk 'BEGIN {printf "IP\t\t\tTimestamp\t\t\tTraffic\n------------------------------------------------------------------------\n"}
 {"date -d @"$2|getline time;print $1"\t\t"time"\t"$3}
 END {printf "------------------------------------------------------------------------\n"}' $source_data|tee $new_data
 echo -e "\e[32;1m$new_data\e[0m is \e[31;1mcreated\e[0m."
