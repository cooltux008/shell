########################################################
#!/bin/bash
#To transfer email files to spl
#chmod u+x /home/mule/jlive/email2spl.sh
#1 3,9 * * * /home/mule/jlive/email2spl.sh
########################################################

spl_ftp_server=
spl_ftp_port=
spl_ftp_user=
spl_ftp_password=
spl_ftp_dst_dir=/
src_dir=/opt/mule/archive/email/out/zip
src_dir_backup=/opt/mule/archive/email/out/emailbackup
log_file=/home/mule/jlive/log/email2ftp_$(date +%Y%m%d).log

upload_sh=/home/mule/jlive/upload2spl.sh

diff_local_tmp=/home/mule/jlive/local_tmp.txt
diff_local=/home/mule/jlive/local.txt
diff_remote_tmp=/home/mule/jlive/remote_tmp.txt
diff_remote=/home/mule/jlive/remote.txt

##kill ftp process leaved
kill -9 $(ps -ef|grep 'ftp -vn'|grep -v 'grep'|awk '{print $2}') 2>/dev/null

##for upload
cat >$upload_sh <<jlive
ftp -vn<<HERE
open $spl_ftp_server $spl_ftp_port
user $spl_ftp_user $spl_ftp_password
binary 
prompt off  
cd $spl_ftp_dst_dir
mput *.zip
close 
bye 
HERE
jlive

##execute upload
echo -e "\e[34;1m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"|tee -a $log_file
echo -e "\e[35;1m$(date)\e[0m"|tee -a $log_file
echo ""|tee -a $log_file
ping -c 3 -W 3 $spl_ftp_server|tee -a $log_file
ping -c 3 -W 3 $spl_ftp_server|tee -a $log_file
echo ""|tee -a $log_file
echo -e "\e[33;1m=================\e[31;1mLocal  File\e[33;1m==================\e[0m"|tee -a $log_file
cd $src_dir
ls -l *.zip 2>/dev/null|tee $diff_local_tmp|tee -a $log_file

end_echo() {
echo -e "\e[35;1m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"|tee -a $log_file
echo ""|tee -a $log_file
echo ""|tee -a $log_file
echo ""|tee -a $log_file
}
if [ "$(find $src_dir -name "*.zip")" != "" ];then
	echo -e "\e[33;1m=================\e[32;1mRemote File\e[33;1m==================\e[0m"|tee -a $log_file
	sh $upload_sh|tee $diff_remote_tmp|tee -a $log_file
	end_echo
else
	echo -e "\e[31;1mNothing\e[0m in \e[34;1m$src_dir\e[0m"|tee -a $log_file
	rm -rf $diff_local $diff_local_tmp $diff_remote $diff_remote_tmp
	end_echo
	exit 0
fi

##backup
cat $diff_local_tmp|grep -E '\.zip$'|awk '{print $NF}'|sort -u >$diff_local
cat $diff_remote_tmp 2>/dev/null|grep -E '\.zip$'|awk '{print $NF}'|sort -u >$diff_remote
[ "$(diff $diff_local $diff_remote)" == "" ] && mv -fv $src_dir/*.zip $src_dir_backup 2>/dev/null || echo -e "\e[31;1mError\e[0m"|tee -a $log_file

##logrotate
rm -rf $diff_local $diff_local_tmp $diff_remote $diff_remote_tmp
rm -rf /home/mule/jlive/log/email2ftp_$(date +%Y%m%d --date="30 days ago").log
