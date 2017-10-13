#############################################
#!/bin/bash
#############################################

#To check whether the depended packages ware installed
echo "-----------------------------------------------"
echo -e "To check \e[31;7msoftware's dependency\e[0m"
echo "-----------------------------------------------"
echo ""

PACKAGE="binutils
compat-libstdc++-33
compat-libstdc++-33.i686
elfutils-libelf
elfutils-libelf-devel
elfutils-libelf-devel-static
gcc
gcc-c++
glibc
glibc-common
glibc-devel
glibc-devel.i686
glibc-headers
kernel-headers
ksh
libcap-devel
libcap-devel.i686
libaio
libaio.i686
libaio-devel
libaio-devel.i686
libgcc
libgcc.i686
libgomp
libstdc++
libstdc++.i686
libstdc++-devel
make
sysstat"

for i in $PACKAGE
do
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
	if [ "$flag" != "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done

echo "***********************************************"

sleep 1
clear

sleep 3
clear
#To install unixODBC
echo "-----------------------------------------------"
echo -e "To check \e[35;7munixODBC\e[0m"
echo "-----------------------------------------------"
echo ""
ODBC="unixODBC unixODBC-devel unixODBC.i686 unixODBC-devel.i686"
for i in $ODBC
do
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
	if [ "$flag" != "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
echo "***********************************************"
sleep 1

#To prepare groups
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check \e[31;7mgroups\e[0m '\e[32;7moinstall, dba, oper, asmadmin, asmdba, asmoper\e[0m'"
echo "-----------------------------------------------"
echo ""
if [ "$(grep -w oinstall /etc/group)" = "" ];then
	/usr/sbin/groupadd oinstall
	echo -e "add group--->\e[31;1moinstall\e[0m"
else 
	echo -e "\e[31;1moinstall\e[0m is exist"
fi

if [ "$(grep -w dba /etc/group)" = "" ];then
	/usr/sbin/groupadd -g 502 dba
	echo -e "add group--->\e[31;1mdba\e[0m"
else 
	echo -e "\e[31;1mdba\e[0m is exist"
fi

if [ "$(grep -w oper /etc/group)" = "" ];then
	/usr/sbin/groupadd -g 503 oper
	echo -e "add group--->\e[31;1moper\e[0m"
else 
	echo -e "\e[31;1moper\e[0m is exist"
fi

if [ "$(grep -w asmadmin /etc/group)" = "" ];then
	/usr/sbin/groupadd -g 504 asmadmin
	echo -e "add group--->\e[31;1masmadmin\e[0m"
else 
	echo -e "\e[31;1masmadmin\e[0m is exist"
fi

if [ "$(grep -w asmoper /etc/group)" = "" ];then
	/usr/sbin/groupadd -g 505 asmoper
	echo -e "add group--->\e[31;1masmoper\e[0m"
else 
	echo -e "\e[31;1masmoper\e[0m is exist"
fi

if [ "$(grep -w asmdba /etc/group)" = "" ];then
	/usr/sbin/groupadd -g 506 asmdba
	echo -e "add group--->\e[31;1masmdba\e[0m"
else 
	echo -e "\e[31;1masmdba\e[0m is exist"
fi

echo "***********************************************"

#To add users
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check \e[31;7musers\e[0m '\e[32;7moracle, grid\e[0m'"
echo "-----------------------------------------------"
echo ""
if [ "$(grep -w oracle /etc/passwd)" = "" ];then
	/usr/sbin/useradd -u 502 -g oinstall -G dba,asmdba,oper oracle
	echo oracle|passwd --stdin oracle
	
	echo -e "add user--->\e[31;1moracle\e[0m"
else 
	echo -e "\e[31;1moracle\e[0m is exist"
fi

if [ "$(grep -w grid /etc/passwd)" = "" ];then
	/usr/sbin/useradd -u 503 -g oinstall -G asmadmin,asmdba,asmoper,dba grid
	echo oracle|passwd --stdin grid
	
	echo -e "add user--->\e[31;1mgrid\e[0m"
else 
	echo -e "\e[31;1mgrid\e[0m is exist"
fi

echo "***********************************************"

#To check resource limits
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check \e[31;7mlimits\e[0m"
echo "-----------------------------------------------"
echo ""
if [ "$(grep -w oracle /etc/security/limits.conf)" = "" ];then
	echo "
	#For oracle
	oracle            soft    nproc   2047
	oracle            hard    nproc   16384
	oracle            soft    nofile  1024
	oracle            hard    nofile  65536
	oracle            soft    stack   10240

	grid              soft    nproc   2047
	grid              hard    nproc   16384
	grid              soft    nofile  1024
	grid              hard    nofile  65536
	grid              soft    stack   10240">>/etc/security/limits.conf
else	
	echo -e "A \e[32;1mlimit\e[0m is \e[31;1mexist\e[0m"
fi
echo "***********************************************"

#To check kernel parameters
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check \e[31;7mkernel parameters\e[0m"
echo "-----------------------------------------------"
echo ""
if [ "$(grep net.core.wmem_max /etc/sysctl.conf)" = "" ];then
echo "
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4294967295
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576">>/etc/sysctl.conf
/sbin/sysctl -p
else
	echo  -e "The \e[32;1mkernel parameters\e[0m has been \e[31;1mdebuged\e[0m"
fi
echo "***********************************************"

#To create related directorys
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check oracle & grid \e[31;7mdirectories\e[0m"
echo "-----------------------------------------------"
echo ""
ORACLE_DIR=/u01/app/oracle
if [ ! -e "$ORACLE_DIR" ];then
	mkdir -p $ORACLE_DIR
	chown -R oracle:oinstall $ORACLE_DIR
	chmod -R 775 $ORACLE_DIR
	echo -e "Created \e[31;1m$ORACLE_DIR\e[0m"
elif [ -e "$ORACLE_DIR" ] && [ -f "$ORACLE_DIR" ];then
	rm -rf $ORACLE_DIR
	mkdir -p $ORACLE_DIR
	chown -R oracle:oinstall $ORACLE_DIR
	chmod -R 775 $ORACLE_DIR
	echo -e "Created \e[31;1m$ORACLE_DIR\e[0m"
else
	echo -e "\e[31;1m$ORACLE_DIR\e[0m is exist"
fi

GRID_DIR=/u01/app/grid
if [ ! -e "$GRID_DIR" ];then
	mkdir -p $GRID_DIR
	chown -R grid:oinstall $GRID_DIR
	chmod -R 775 $GRID_DIR
	echo -e "Created \e[31;1m$GRID_DIR\e[0m"
elif [ -e "$GRID_DIR" ] && [ -f "$GRID_DIR" ];then
	rm -rf $GRID_DIR
	mkdir -p $GRID_DIR
	chown -R grid:oinstall $GRID_DIR
	chmod -R 775 $GRID_DIR
	echo -e "Created \e[31;1m$GRID_DIR\e[0m"
else
	echo -e "\e[31;1m$GRID_DIR\e[0m is exist"
fi
echo "***********************************************"


ORAINVENTORY_DIR=/u01/app/oraInventory
if [ ! -e "$ORAINVENTORY_DIR" ];then
        mkdir -p $ORAINVENTORY_DIR
        chown -R grid:oinstall $ORAINVENTORY_DIR
        chmod -R 775 $ORAINVENTORY_DIR
        echo -e "Created \e[31;1m$ORAINVENTORY_DIR\e[0m"
elif [ -e "$ORAINVENTORY_DIR" ] && [ -f "$ORAINVENTORY_DIR" ];then
        rm -rf $ORAINVENTORY_DIR
        mkdir -p $ORAINVENTORY_DIR
        chown -R grid:oinstall $ORAINVENTORY_DIR
        chmod -R 775 $ORAINVENTORY_DIR
        echo -e "Created \e[31;1m$ORAINVENTORY_DIR\e[0m"
else
        echo -e "\e[31;1m$ORAINVENTORY_DIR\e[0m is exist"
fi
echo "***********************************************"
#Configuring the oracle User's Environment
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To configuring the oracle User's \e[31;7mEnvironment\e[0m"
echo "-----------------------------------------------"
echo ""
if [ "$(grep ORACLE /home/oracle/.bash_profile)" = "" ];then
	export ORACLE_BASE=$ORACLE_DIR
	echo "
#Oracle env
export ORACLE_BASE=$ORACLE_DIR
export ORACLE_SID=orcl
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
export PATH=\$ORACLE_HOME/bin:\$PATH
export EDITOR=vi">>/home/oracle/.bash_profile
	echo -e "\e[31;1mOracle\e[0m configure done"
	echo ""
else
	echo -e "\e[31;1mOracle\e[0m has being configured, \e[32;1mdo nothing\e[0m"
	echo ""
fi

if [ "$(grep ORACLE /home/grid/.bash_profile)" = "" ];then
	export ORACLE_BASE=$GRID_DIR
	echo "
#Oracle env
export ORACLE_BASE=$GRID_DIR
export ORACLE_SID=+ASM
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
export PATH=\$ORACLE_HOME/bin:\$PATH
export EDITOR=vi">>/home/grid/.bash_profile
	echo -e "\e[31;1mgrid\e[0m configure done"
	echo ""
else
	echo -e "\e[31;1mgrid\e[0m has being configured, \e[32;1mdo nothing\e[0m"
	echo ""
fi
echo "***********************************************"
