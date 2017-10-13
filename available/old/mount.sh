for i in $(echo $(seq 8 25))
	do
		if [ ! -b /dev/loop$i ];
			then mknod /dev/loop$i b 7 $i
		fi
	done

#################################################################################
#win7
mount -o loop /mnt/ISO/win7/cn_windows_7_ultimate_with_sp1_x64_dvd_u_677408.iso /smb/win7_x64 		
mount -o loop /mnt/ISO/win7/cn_windows_7_ultimate_x86_dvd_x15-65907.iso /smb/win7_x86 	
mount -o loop /mnt/ISO/win7/cn_windows_server_2008_r2_standard_enterprise_datacenter_and_web_with_sp1_vl_build_x64_dvd_617396.iso /smb/win2008r2 	

#win8
mount -o loop /mnt/ISO/win8/cn_windows_8_enterprise_x64_dvd_917570.iso /smb/win8e_x64  	
mount -o loop /mnt/ISO/win8/cn_windows_8_enterprise_x86_dvd_917682.iso /smb/win8e_x86  	
mount -o loop /mnt/ISO/win8/windows_server2012_x64.iso /smb/win2012  	

#winXP
mount -o loop /mnt/ISO/XP/YLMF_WinXP_Y2014.iso   /smb/xp_ghost
mount -o loop /mnt/ISO/XP/XP_Pro_SP3_purge.iso   /smb/xp_purge

#################################################################################


#################################################################################
#Centos6
mount -o loop /mnt/ISO/linux/centos/CentOS-6.5-x86_64-bin-DVD1.iso /var/www/pub/ftp/centos6_1     
mount -o loop /mnt/ISO/linux/centos/CentOS-6.5-x86_64-bin-DVD2.iso /var/www/pub/ftp/centos6_2     

#Ubuntu12.04 
mount -o loop /mnt/ISO/linux/ubuntu/ubuntu-12.04-server-amd64.iso  /var/www/pub/ftp/ubuntu12.04     

#Kubuntu12.04 
mount -o loop /mnt/ISO/linux/ubuntu/kubuntu-12.04-dvd-amd64.iso	/var/www/pub/ftp/kubuntu12.04     

#Debian6.0 
mount -o loop /mnt/ISO/linux/debian/debian-6.0.6-amd64-DVD-1.iso   /var/www/pub/ftp/debian6.0     

#Red Hat Enterprise Server 6 
mount -o loop /mnt/ISO/linux/redhat/rhel-server-6.2-x86_64-dvd.iso   /var/www/pub/ftp/rhel6     

#Red Hat Enterprise Server 5 
mount -o loop /mnt/ISO/linux/redhat/rhel-server-5.8-x86_64-dvd.iso	/var/www/pub/ftp/rhel5_x64 	

#linuxMINT 13 
#mount -o loop /mnt/ISO/linux/mint13_mate_cinnamon_x64.iso    /var/www/pub/ftp/mint     

#BT5 
mount -o loop 	/mnt/ISO/linux/BT5R3-KDE-64.iso /var/www/pub/ftp/bt5     

#Arch linux 
#mount -o loop /mnt/ISO/linux/archlinux-2012.12.01-dual.iso     /var/www/pub/ftp/arch     

#Free BSD 9.0 
#mount -o loop /mnt/ISO/linux/freebsd/FreeBSD-9.0-RELEASE-amd64-dvd1.iso /var/www/pub/ftp/freebsd     
