#############################################
#!/bin/bash
#############################################

#To check whether the depended packages ware installed
echo "-----------------------------------------------"
echo -e "To check \e[31;7msoftware's dependency\e[0m"
echo "-----------------------------------------------"
echo ""

PACKAGE="
SUNWarc SUNWbtool SUNWhea SUNWlibC SUNWlibms SUNWsprot SUNWtoo SUNWi1of SUNWi1cs SUNWi15cs SUNWxwfnt SUNWcsl"

for i in $PACKAGE
do

	pkginfo -i $i >/dev/null
	if [ "$?" = "0" ];then
		echo -e "$i is \e[32;1minstalled\e[0m"
		echo ""
	else
		echo -e "$i is \e[31;1mnot\e[0m \e[32;1minstalled\e[0m"
		echo -e "\e[31;1minstalling\e[0m \e[32;1m$i\e[0m"
		read -p "Please input ${i}'s dir: "
		pkgadd -d $REPLY $i
		echo ""
		echo -e "$i is \e[32;1minstalled\e[0m"
	fi
done


echo "***********************************************"

sleep 1
clear



echo ""
echo "-----------------------------------------------"
echo -e "To \e[31;7mcheck again\e[0m"
echo "-----------------------------------------------"
echo ""
#To check again
for i in $PACKAGE
do
	pkginfo -i $i >/dev/null
	if [ "$?" = "0" ];then
		echo -e "\e[35;1m$i\e[0m is \e[32;4minstalled\e[0m"
	fi
done
echo ""
echo "***********************************************"


#To prepare groups
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check \e[31;7mgroups\e[0m '\e[32;7moinstall, dba, oper, asmadmin, asmdba, asmoper\e[0m'"
echo "-----------------------------------------------"
echo ""
if [ "$(grep -w oinstall /etc/group)" = "" ];then
	/usr/sbin/groupadd -g 501 oinstall
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
	echo -e "add user--->\e[31;1moracle\e[0m"
	/usr/sbin/useradd -u 502 -g oinstall -G dba,asmdba,oper -d /export/home/oracle -m -s /usr/bin/bash -c "Oracle Software Owner" -k /etc/skel oracle
	passwd -r files oracle
	chown -R oracle:dba /export/home/oracle
	
else 
	echo -e "\e[31;1moracle\e[0m is exist"
fi

if [ "$(grep -w grid /etc/passwd)" = "" ];then
	echo -e "add user--->\e[31;1mgrid\e[0m"
	/usr/sbin/useradd -u 503 -g oinstall -G asmadmin,asmdba,asmoper,dba -d /export/home/grid -m -s /usr/bin/bash -c "Grid Infrastructure Owner" -k /etc/skel grid
	passwd -r files grid
	chown -R grid:asmdba /export/home/grid
	
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
if [ "$(grep -w project.max-shm  /etc/project)" = "" ];then
	echo -e "\e[32;1mlimiting\e[0m "
	for USER in oracle grid
	do
		PROJECT_ID=$(id -p grid|cut -d'(' -f4|tr -d ')')
		projmod -sK "project.max-sem-ids=(privileged,100,deny)" $PROJECT_ID
		projmod -sK "process.max-sem-nsems=(privileged,256,deny)" $PROJECT_ID
		projmod -sK "project.max-shm-memory=(privileged,4294967295,deny)" $PROJECT_ID
		projmod -sK "project.max-shm-ids=(privileged,100,deny)" $PROJECT_ID
	done
else	
##############process##############
	echo -e "A \e[32;1mlimit\e[0m is \e[31;1mexist\e[0m"
	echo ""
	for USER in oracle grid
	do
		PROJECT_ID=$(id -p grid|cut -d'(' -f4|tr -d ')')

		for VAR in "project.max-sem-ids" "project.max-shm-memory" "project.max-shm-ids"
		do
			prctl -n $VAR -i project $PROJECT_ID
		done
		
	done
##############process##############
	for USER in oracle grid
        do
                PROJECT_ID=$(id -p grid|cut -d'(' -f4|tr -d ')')

                for VAR in "process.max-sem-nsems"
                do
                        prctl -n $VAR -i process $PROJECT_ID
                done
                
        done
fi
echo "***********************************************"
sleep 1


#To check kernel parameters
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To check \e[31;7mkernel parameters\e[0m"
echo "-----------------------------------------------"
echo ""
if [ "$(grep -w oracle /etc/system)" = "" ];then
	echo  -e "\e[32;1mkernel parameters\e[0m is \e[31;1mdebugging\e[0m"
	echo "
#For oracle
set noexec_user_stack=1 
set semsys:seminfo_semmni=100 
set semsys:seminfo_semmns=1024 
set semsys:seminfo_semmsl=256 
set semsys:seminfo_semvmx=23767 
set shmsys:shminfo_shmmax=4294967295 
set shmsys:shminfo_shmmin=1 
set shmsys:shminfo_shmmni=100 
set shmsys:shminfo_shmset=10" >>/etc/system
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

#Configuring the oracle User's Environment
echo ""
echo ""
echo ""
echo "-----------------------------------------------"
echo -e "To configuring the oracle User's \e[31;7mEnvironment\e[0m"
echo "-----------------------------------------------"
echo ""
if [ "$(grep ORACLE /export/home/oracle/.profile)" = "" ];then
	export ORACLE_BASE=$ORACLE_DIR
	echo "
#Oracle env
export ORACLE_BASE=$ORACLE_DIR
export ORACLE_SID=orcl
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
export PATH=\$ORACLE_HOME/bin:\$PATH
export PS1='\[\e[35;1m\]\u\[\e[36;1m\]@\[\e[33;1m\]\h\[\e[34;1m\]:\[\e[31;1m\]\W\[\e[32;1;5m\]\$\[\e[0m'
export EDITOR=vi">>/export/home/oracle/.profile
	echo -e "\e[31;1mOracle\e[0m configure done"
	echo ""
else
	echo -e "\e[31;1mOracle\e[0m has being configured, \e[32;1mdo nothing\e[0m"
	echo ""
fi

if [ "$(grep ORACLE /export/home/grid/.profile)" = "" ];then
	export ORACLE_BASE=$GRID_DIR
	echo "
#Oracle env
export ORACLE_BASE=$GRID_DIR
export ORACLE_SID=+ASM
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
export PATH=\$ORACLE_HOME/bin:\$PATH
export PS1='\[\e[35;1m\]\u\[\e[36;1m\]@\[\e[33;1m\]\h\[\e[34;1m\]:\[\e[31;1m\]\W\[\e[32;1;5m\]\$\[\e[0m'
export EDITOR=vi">>/export/home/grid/.profile
	echo -e "\e[31;1mgrid\e[0m configure done"
	echo ""
else
	echo -e "\e[31;1mgrid\e[0m has being configured, \e[32;1mdo nothing\e[0m"
	echo ""
fi
echo "***********************************************"
