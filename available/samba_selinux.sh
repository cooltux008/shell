########################################
#!/bin/bash
#To share samba
########################################

DIR="/mnt/ISO/linux"

#开启ntfs共享samba
flag=$(ls -dZ $DIR|cut -d: -f3)
([ $flag == "fusefs_t" ] && setsebool -P samba_share_fusefs=1) || chcon -t samba_share_t $DIR


#开启samba用户家目录功能，匿名可写功能，
for i in allow_smbd_anon_write samba_enable_home_dirs use_samba_home_dirs 
do
	flag=$(getsebool $i|awk '{print $3}')
	[ $flag == "off" ] && setsebool -P $i=1
done
