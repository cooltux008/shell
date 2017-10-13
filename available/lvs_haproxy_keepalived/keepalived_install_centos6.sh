############################################
#!/bin/bash
#To install keepalived automatically
#Made by liujun,2014/08/15
############################################
#Define system environment PATH
export PATH=$PATH
#Source function library
. /etc/rc.d/init.d/functions

#Define Keepalived Version
Keepalived_Version=1.2.13
Install_Directory=/usr/local/src
#Install the build-essential
PACKAGE="kernel-devel gcc openssl-devel popt-devel libnl-devel net-snmp-devel"
for i in $PACKAGE
do
	FLAG=$(rpm -qa|grep -w $i)
	if [ "$FLAG" == "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done

echo -e "\n"
echo -e "... ...\n"
sleep 1
echo -e "... ...\n"
echo -e "\n"


#Build and install
tar -xvf keepalived-$Keepalived_Version.tar.gz -C /usr/local/src
cd /usr/local/src/keepalived-$Keepalived_Version
./configure  \
--prefix=/usr \
--sysconf=/etc \
--with-kernel-dir=/usr/src/kernels/$(uname -r) \
--enable-snmp \
--enable-sha1 
make && make install



echo -e "\n"
echo -e "\e[31;1mkeepalived\e[0m is \e[32;1minstalled\e[0m"
echo -e "\n"

#Autostart on init 3/5
#cp $Install_Directory/keepalived-$Keepalived_Version/keepalived/etc/init.d/keepalived.init /etc/rc.d/rc3.d/S99keepalived
#cp $Install_Directory/keepalived-$Keepalived_Version/keepalived/etc/init.d/keepalived.init /etc/rc.d/rc5.d/S99keepalived
chkconfig keepalived on
chkconfig --list keepalived

###################################################
##########################
#Build keepalived.conf
##########################

#Define E-mail & Smtp_Server
Mail1=
Mail2=
Mail3=

Smtp_Server=

#Define keepalived "MASTER" or "BACKUP"
State_Flag=MASTER
State_Flag_Priority=100
#State_Flag=BACKUP
#State_Flag_Priority=80

#Define Virtual Server IP & Listen Port
VIP1=192.168.10.100
VIP1_Listen_Port=80
VIP2=
VIP2_Listen_Port=

#Define Real Server IP & Listen Port
VIP1_RIP1=192.168.10.11
VIP1_RIP1_Listen_Port=80
VIP1_RIP2=192.168.10.12
VIP1_RIP2_Listen_Port=80
VIP1_RIP3=
VIP1_RIP3_Listen_Port=

VIP2_RIP1=
VIP2_RIP1_Listen_Port=
VIP2_RIP2=
VIP2_RIP2_Listen_Port=
VIP2_RIP3=
VIP2_RIP3_Listen_Port=

#Define Weight
Weight_VIP1_RIP1=1
Weight_VIP1_RIP2=2
Weight_VIP1_RIP3=3
       
Weight_VIP2_RIP1=
Weight_VIP2_RIP2=
Weight_VIP2_RIP3=

#Define Schedule & Model
Schedule_VIP1=wlc
Mode_VIP1=DR

Schedule_VIP2=
Mode_VIP2=

mv /etc/keepalived/keepalived.conf{,.bak}
cat >/etc/keepalived/keepalived.conf <<HERE
! Configuration File for keepalived

global_defs {
   notification_email {
     ${Mail1:-acassen@firewall.loc}
     ${Mail2:-failover@firewall.loc}
     ${Mail3:-sysadmin@firewall.loc}
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server ${Smtp_Server:-192.168.200.1}
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state $State_Flag
    interface eth0
    virtual_router_id 51
    priority $State_Flag_Priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $VIP1
        $VIP2
    }
}

virtual_server $VIP1 $VIP1_Listen_Port {
    delay_loop 6
    lb_algo $Schedule_VIP1
    lb_kind $Mode_VIP1
    nat_mask 255.255.255.0
    persistence_timeout 50
    protocol TCP

    real_server $VIP1_RIP1 $VIP1_RIP1_Listen_Port {
        weight $Weight_VIP1_RIP1
	TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
    real_server $VIP1_RIP2 $VIP1_RIP2_Listen_Port {
        weight $Weight_VIP1_RIP2
	TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
!    real_server $VIP1_RIP3 $VIP1_RIP3_Listen_Port {
!        weight $Weight_VIP1_RIP3
!	TCP_CHECK {
!            connect_timeout 3
!            nb_get_retry 3
!            delay_before_retry 3
!        }
!    }

}

!virtual_server $VIP2 $VIP2_Listen_Port {
!    delay_loop 6
!    lb_algo $Schedule_VIP2
!    lb_kind $Mode_VIP2
!    nat_mask 255.255.255.0
!    persistence_timeout 50
!    protocol TCP
!
!    real_server $VIP2_RIP1 $VIP2_RIP1_Listen_Port {
!        weight $Weight_VIP2_RIP1
!	TCP_CHECK {
!            connect_timeout 3
!            nb_get_retry 3
!            delay_before_retry 3
!        }
!    }
!    real_server $VIP2_RIP2 $VIP2_RIP2_Listen_Port {
!        weight $Weight_VIP2_RIP2
!	TCP_CHECK {
!            connect_timeout 3
!            nb_get_retry 3
!            delay_before_retry 3
!        }
!    }
!    real_server $VIP2_RIP3 $VIP1_RIP3_Listen_Port {
!        weight $Weight_VIP2_RIP3
!	TCP_CHECK {
!            connect_timeout 3
!            nb_get_retry 3
!            delay_before_retry 3
!        }
!    }
!}

HERE

echo -e "\n"
/etc/init.d/keepalived start
sleep 1
echo -e "\n"
/etc/init.d/keepalived restart

###################################################
