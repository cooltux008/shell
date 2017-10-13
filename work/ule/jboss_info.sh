#!/bin/bash
#Made by liujun, 20160927, liujun02@tomstaff.com

[ $# -ne 2 -a $# -ne 1 ] && echo -e "\e[33;1mUsage\e[0m: bash \e[32;1m$0\e[0m \e[31;1mulePaymentGateway/gatewayService\e[0m \e[36;1mbeta|prd\e[0m" && exit 1

iplist_dir=/data/postmall/deploy/iplist/maven
repo_dir=/data/postmall/deploy/repository/maven
kw_text=/data/postmall/deploy/text/maven/jboss_update.txt
kw_tmp=$1
kw=$(echo $1|tr -s '/' '#')
env=$2

jboss_str=$(egrep -w "^${kw}#.*${env:-beta}" $kw_text)
jboss_iplist=$(find $iplist_dir -maxdepth 1 -type f -name "*.txt"|grep $(echo $kw|sed 's/#/_/g')_${env:-beta_jboss})
jboss_kw_restart_shell=$(echo $kw|awk -F'#' '{print $1}')
[ ! -z $jboss_str ] && echo $jboss_str|egrep --color=auto "$kw|jboss[0-9]" || exit 3
[ ! -z $jboss_iplist ] && echo -e "$jboss_iplist"|egrep --color=auto ${env:-beta} || exit 3
echo -e "\e[32;1m$(cat $jboss_iplist)\e[0m"
echo ""


#ear
echo "-------------"
echo -e "\e[1;31mear info\e[0m"
echo "-------------"
jboss_ear_dir=/data/jboss/server/$(echo $kw|cut -d'#' -f1)/deploy
echo "ssh web@$(cat $jboss_iplist|head -n1) ls -l $jboss_ear_dir/$(echo $kw|cut -d'#' -f2).ear"
jboss_ear_version=$(ssh web@$(cat $jboss_iplist|head -n1) ls -l $jboss_ear_dir/$(echo $kw|cut -d'#' -f2).ear|awk '{print $NF}')
echo -e "\e[35;1m$jboss_ear_version\e[0m"
echo ""

#jdbc
echo "-------------"
echo -e "\e[1;31mJDBC info\e[0m"
echo "-------------"
echo "ssh web@$(cat $jboss_iplist|head -n1) grep '<connection-url>' $jboss_ear_dir/*.xml"
ssh web@$(cat $jboss_iplist|head -n1) "grep \"<connection-url>\" $jboss_ear_dir/*.xml"
echo ""

#restart
echo "-------------"
echo -e "\e[1;31mrestart info\e[0m"
echo "-------------"
for ip in $(cat $jboss_iplist)
do
	flag=$(ssh web@$ip ls jboss_$(echo $jboss_str|cut -d'#' -f1)_restart.sh 2>/dev/null)
	[ ! -z $flag ] && echo -e "ssh web@\e[34;1m$ip\e[0m bash \e[31;1mjboss_$(echo $jboss_str|cut -d'#' -f1)_restart.sh\e[0m"
done
echo ""

#archive
echo "-------------"
echo -e "\e[1;31marchive info\e[0m"
echo "-------------"
echo "ls $repo_dir/${env:-beta}/$(echo $kw|cut -d'#' -f1)/$(echo $kw|cut -d'#' -f2)"
ls $repo_dir/${env:-beta}/$(echo $kw|cut -d'#' -f1)/$(echo $kw|cut -d'#' -f2)
