#!/bin/bash
#Made by liujun, 20160927, liujun02@tomstaff.com

[ $# -ne 2 -a $# -ne 1 ] && echo -e "\e[33;1mUsage\e[0m: bash \e[32;1m$0\e[0m \e[31;1mSOA/pcsCoDas\e[0m \e[36;1mbeta|prd\e[0m" && exit 1

iplist_dir=/data/postmall/deploy/iplist/maven
repo_dir=/data/postmall/deploy/repository/maven
kw_text=/data/postmall/deploy/text/maven/tomcat_update.txt
kw_tmp=$1
kw=$(echo $1|tr -s '/' '#')
env=$2

tomcat_str=$(egrep -w "^${kw}#.*${env:-beta}" $kw_text)
tomcat_str_kw=$(echo $tomcat_str|awk -F'#' '{print $5}')
tomcat_iplist=$(find $iplist_dir -maxdepth 1 -type f -name "*.txt"|grep $(echo $kw|sed 's/#/_/g')_${env:-beta}_tomcat)
[ ! -z $tomcat_str ] && echo $tomcat_str|egrep --color=auto "$kw|tomcat[0-9]+" || exit 3
[ ! -z $tomcat_iplist ] && echo $tomcat_iplist|egrep --color=auto "${env:-beta}" || exit 3
echo -e "\e[32;1m$(cat $tomcat_iplist)\e[0m"
echo ""


#war 
echo "-------------"
echo -e "\e[1;31mwar info\e[0m"
echo "-------------"
tomcat_war_dir=/data/postmall/tomcat/$(echo $tomcat_str|cut -d'#' -f4)
echo "ssh web@$(cat $tomcat_iplist|head -n1) ls -l $tomcat_war_dir/$(echo $kw|cut -d'#' -f2).war"
tomcat_war_version=$(ssh web@$(cat $tomcat_iplist|head -n1) ls -l $tomcat_war_dir/$(echo $kw|cut -d'#' -f2).war|awk '{print $NF}')
echo -e "\e[35;1m$tomcat_war_version\e[0m"
echo ""

#jdbc
echo "-------------"
echo -e "\e[1;31mJDBC info\e[0m"
echo "-------------"
echo "ssh web@$(cat $tomcat_iplist|head -n1) cat $tomcat_war_dir/$(echo $kw|cut -d'#' -f2)/WEB-INF/classes/db.properties"
ssh web@$(cat $tomcat_iplist|head -n1) cat $tomcat_war_dir/$(echo $kw|cut -d'#' -f2)/WEB-INF/classes/{jdbc.properties,db.properties}
echo ""

#restart
echo "-------------"
echo -e "\e[1;31mrestart info\e[0m"
echo "-------------"
for ip in $(cat $tomcat_iplist)
do
	flag=$(ssh web@$ip ls t$(echo $tomcat_str_kw|tr -d 'tomcat')_restart.sh 2>/dev/null)
	[ ! -z $flag ] && echo -e "ssh web@\e[34;1m$ip\e[0m bash \e[31;1mt$(echo $tomcat_str_kw|tr -d 'tomcat')_restart.sh\e[0m"
done
echo ""

#archive
echo "-------------"
echo -e "\e[1;31marchive info\e[0m"
echo "-------------"
echo "ls $repo_dir/${env:-beta}/$(echo $kw|cut -d'#' -f1)/$(echo $kw|cut -d'#' -f2)"
ls $repo_dir/${env:-beta}/$(echo $kw|cut -d'#' -f1)/$(echo $kw|cut -d'#' -f2)
