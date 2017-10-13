##########################################
#!/bin/sh
#To split log based on time
##########################################

if [ -z $1 ];then
	echo -e "\e[32;1mUsage:\e[0m \e[33;1m$0\e[0m \e[31;1maccess_log\e[0m"
	exit 2
fi

start_time="05/Jun/2016:00:00"
end_time="05/Jun/2016:23:59"
log_file=$1
log_splited=$2

if [ -f $log_file ];then
	split_start_line=$(grep -n "$start_time" $log_file|head -n1|cut -d: -f1)
	split_end_line=$(grep -n "$end_time" $log_file|tail -n1|cut -d: -f1)
	sed -n "$split_start_line,${split_end_line:-$(wc -l <$log_file)} p" $log_file > ${log_splited:-$PWD/log_splited.log}
	echo -e "\e[34;1mThe splited log is\e[0m \e[32;1m${log_splited:-$PWD/log_splited.log}\e[0m"
else
	echo -e "\e[31;1m$log_file\e[0m \e[34;1mNot found\e[0m "
	exit 2
fi
