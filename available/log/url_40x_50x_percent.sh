#!/bin/bash
#statistic 40x,50x

last_mo=$(date --date="-8 days" +%Y_%m_%d)
last_tu=$(date --date="-7 days" +%Y_%m_%d) 
last_we=$(date --date="-6 days" +%Y_%m_%d)
last_th=$(date --date="-5 days" +%Y_%m_%d) 
last_fr=$(date --date="-4 days" +%Y_%m_%d) 
last_sa=$(date --date="-3 days" +%Y_%m_%d)
last_su=$(date --date="-2 days" +%Y_%m_%d)
#init_date=
#last_mo=$(date --date="$[${init_date:=$(date +%Y%m%d)}-8]" +%Y_%m_%d)
#last_tu=$(date --date="$[${init_date:=$(date +%Y%m%d)}-7]" +%Y_%m_%d) 
#last_we=$(date --date="$[${init_date:=$(date +%Y%m%d)}-6]" +%Y_%m_%d)
#last_th=$(date --date="$[${init_date:=$(date +%Y%m%d)}-5]" +%Y_%m_%d) 
#last_fr=$(date --date="$[${init_date:=$(date +%Y%m%d)}-4]" +%Y_%m_%d) 
#last_sa=$(date --date="$[${init_date:=$(date +%Y%m%d)}-3]" +%Y_%m_%d)
#last_su=$(date --date="$[${init_date:=$(date +%Y%m%d)}-2]" +%Y_%m_%d)


url_40x_50x=/var/tmp/40x50x
rm -rf $url_40x_50x
date_url_count(){
echo -e "\e[34;1mDate\t404\t40x\t50x\tTotal\e[0m"
echo -e "\e[32;1m------------------------------------------------------\e[0m"
for date in $last_mo $last_tu $last_we $last_th $last_fr $last_sa $last_su
do
	log=/opt/IBM/httpconf/httplogs/${date}_access_log
	count_url_40x_50x="$(awk '{if($9==404)count_404++;if($9 ~ 40 && $9!=404)count_40x++;if($9 ~ 50)count_50x++;total++} END {print count_404"\t"count_40x"\t"count_50x++"\t"total}' $log)"
	echo "$date $count_url_40x_50x"|tee -a $url_40x_50x
done
}
week_url_count(){
echo -e "\e[34;1mDate\t404(%)\t40x(%)\t50x(%)\e[0m"
echo -e "\e[32;1m------------------------------------------------------\e[0m"
awk '{print $1,($2/$5)*100,($3/$5)*100,($4/$5)*100}' $url_40x_50x
echo -e "\e[31;1mLast Week\e[0m \e[32;1m$(awk '{sum_404+=$2;sum_40x+=$3;sum_50x+=$4;sum_total+=$5} END {print (sum_404/sum_total)*100"\t"(sum_40x/sum_total)*100"\t"(sum_50x/sum_total)*100}' $url_40x_50x)\e[0m"
}

date_url_count
echo ""
week_url_count
