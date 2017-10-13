#!/bin/bash
# 作   者: garrylin
# 时   间: 2016-6-6
# 版   本: 1.0.1
# 用   途: 主要负责prd环境的Maven方式部署search_sphinx
TOPDIR="/data/postmall"
DEPLOYDIR="$TOPDIR/deploy"
SEARCHTEXT="$DEPLOYDIR/text/maven/search_sphinx_update.txt"
IPLISTDIR="$DEPLOYDIR/iplist/maven"
LOGDIR="$DEPLOYDIR/logs/maven"
JENKINSDIR="$DEPLOYDIR/repository/maven/jenkins"
REPOSITORYDIR="$TOPDIR/repository"
SEARCHDIR="$TOPDIR/search"
TIMERDIR="$TOPDIR/timer"
DEPLOYLOG=$LOGDIR/${SERVER}_search_sphinx_deploy.log
VERSIONLOG=$LOGDIR/Version_record.txt
ENVRIONMENT="prd"
SERVER="tomcat"
MODULE=$1
APP=$2
FILE=$3

[ -z $MODULE -o -z $APP -o -z $FILE ] && echo "args error";exit 1 

checkVersion(){
	lastVersion=$(grep -E "[[:space:]]*$MODULE[[:space:]]*$APP[[:space:]]*$ENVRIONMENT[[:space:]]*$SERVER[[:space:]]*" $DEPLOYLOG|tail -n1|awk '{print $6}'|awk -F"." '{print $(NF-1)}')
	currentVersion=$(echo $FILE |awk -F"." '{print $(NF-1)}')
	[ $lastVersion -gt $currentVersion ] && [ ! -z $lastVersion ] && (echo "服务器上次更新版本高于本次更新版本，请注意!";status="backcode") || status="deploy"
}

logger(){
	if [ -f $VERSIONLOG ];then
		logFormat=$(date +%Y%m%d-%T)
		echo "$logFormat=======================" >> $VERSIONLOG
		echo "上次最后版本: $(grep "$MODULE	 $APP   $ENVRIONMENT   $SERVER"  $DEPLOYLOG|tail -n1)" >> $VERSIONLOG
		echo "本次更新版本：$logFormat	  $MODULE	 $APP   $ENVRIONMENT   $SERVER $APP  $status" >> $VERSIONLOG
		echo "$logFormat=======================" >> $VERSIONLOG

		echo "$logFormat	  $MODULE	 $APP   $ENVRIONMENT   $SERVER   $APP  $status" >> $DEPLOYLOG
		echo "$logFormat	  $MODULE	 $APP   $ENVRIONMENT   $SERVER   $FILE $status" >> $DEPLOYLOG
	else
		touch $DEPLOYLOG
		echo "log file:$DEPLOYLOG"
	fi
}

alert(){
	[ -z $FILE ] && echo -e "\033[31m ERROR : FILE 不能为空\n\033[0m"; exit 1
	checkVersion
	logger
}

search_tomcat(){
	tomcatRoot=$(grep $APP $SEARCHTEXT|awk -F'#' '{print $3}')
	tomcatChild=$(echo $tomcatRoot|awk -F'webapps_' '{print $2}'|awk -F'_t' '{print $1}')
	tomcatRestart="/home/web/$(echo $tomcatRoot|awk -F'_' '{print $NF}')_restart.sh"
	if [ "$tomcatRoot" != "betaprd" ];then
		alert
		for TARGET in $(cat $IPLISTDIR/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$REPOSITORYDIR/$tomcatChild/
			ssh -q $TARGET "rm -rf $TOPDIR/$SERVER/$tomcatRoot/{$APP,$APP.war};ln -snf $REPOSITORYDIR/$tomcatChild/$FILE $TOPDIR/$SERVER/$tomcatRoot/$APP.war;bash $tomcatRestart &>/dev/null &"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
			sleep 8
		done
	fi
}

search_jar(){
case $APP in
	cse.Interface)
		for TARGET in $(cat $IPLISTDIR/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			alert
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$REPOSITORYDIR/$APP/
			if [ $TARGET == "172.24.136.36" ] || [ $TARGET =="172.24.136.37" ] || [ $TARGET == "172.24.136.38" ];then
				ssh -q $TARGET "rm -rf $SEARCHDIR/$APP/$APP.jar;ln -snf $REPOSITORYDIR/$APP/$FILE $SEARCHDIR/$APP/$APP.jar"
			elif [ $TARGET == "172.25.152.31" ] || \
				[ $TARGET == "172.25.152.32" ] || \
				[ $TARGET == "172.25.152.33" ] || \
				[ $TARGET == "172.25.152.34" ] || \
				[ $TARGET == "172.25.152.35" ];then
				ssh -q $TARGET "rm -rf $SEARCHDIR/$APP/$APP.jar;ln -snf $REPOSITORYDIR/$APP/$FILE $SEARCHDIR/$APP/$APP.jar;bash ${APP}_restart.sh >/dev/null"

				ssh -q $TARGET "rm -rf $SEARCHDIR/${APP}_9030/$APP.jar;ln -snf $REPOSITORYDIR/$APP/$FILE $SEARCHDIR/${APP}_9030/$APP.jar;bash ${APP}_restart_9030.sh >/dev/null"
			elif [ $TARGET == "172.25.152.41" ] || \
				[ $TARGET == "172.25.152.42" ] || \
				[ $TARGET == "172.25.152.43" ] || \
				[ $TARGET == "172.25.152.44" ] || \
				[ $TARGET == "172.25.152.45" ];then
				ssh -q $TARGET "rm -rf $SEARCHDIR/${APP}_2/$APP.jar;ln -snf $REPOSITORYDIR/$APP/$FILE $SEARCHDIR/${APP}_2/$APP.jar;bash ${APP}_2_restart.sh >/dev/null"
				ssh -q $TARGET "rm -rf $SEARCHDIR/${APP}_3/$APP.jar;ln -snf $REPOSITORYDIR/$APP/$FILE $SEARCHDIR/${APP}_3/$APP.jar;bash ${APP}_3_restart.sh >/dev/null"
			fi
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.DataSyncCenter2)
		for TARGET in $(cat $IPLISTDIR/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			alert
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$REPOSITORYDIR/cse.DataSyncCenter/lib/
			ssh -q $TARGET "rm -rf $SEARCHDIR/cse.DataSyncCenter/lib/$APP.jar;ln -snf $REPOSITORYDIR/cse.DataSyncCenter/lib/$FILE $SEARCHDIR/cse.DataSyncCenter/lib/$APP.jar;bash ${APP}_restart.sh >/dev/null &"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.plugin.*)
		APPDIR="cse.DataSyncCenter/plugins"
		alert
		for TARGET in $(cat $IPLISTDIR/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$REPOSITORYDIR/$APPDIR/
			ssh -q $TARGET "rm -fr $SEARCHDIR/$APPDIR/$APP.jar;ln -snf $REPOSITORYDIR/$APPDIR/$FILE $SEARCHDIR/$APPDIR/$APP.jar;bash cse.DataSyncCenter2_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;
	*)
		for TARGET in $(cat $IPLISTDIR/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			alert
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$REPOSITORYDIR/$APP/
			ssh -q $TARGET "rm -rf $SEARCHDIR/$APP/$APP.jar;ln -snf $REPOSITORYDIR/$APP/$FILE $SEARCHDIR/$APP/$APP.jar;bash ${APP}_restart.sh >/dev/null &"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;
esac
}

search_timer(){
case $APP in
	crawlerToolbox)
		alert
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}_timer.txt)
		do
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$TIMERDIR/$APP/
			ssh -q $TARGET "rm -rf $TIMERDIR/$APP/$APP.jar;ln -snf $TIMERDIR/$APP/$FILE $TIMERDIR/$APP/$APP.jar;bash killcrawlertoolbox.sh;sleep 8;bash allstart.sh"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	crawler)
		alert
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}_timer.txt)
		do
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$TIMERDIR/$APP/
			ssh -q $TARGET "rm -rf $TIMERDIR/$APP/$APP.jar;ln -snf $TIMERDIR/$APP/$FILE $TIMERDIR/$APP/$APP.jar;bash killcrawlertoolbox.sh;sleep 8;/usr/local/jdk/bin/java -jar /d$TIMERDIR/$APP/$APP.jar -k startService &"  2>/dev/null > /dev/null &
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;
esac
}

search_conf(){
case $APP in
	cse.Interface.conf)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			if [ $TARGET == "172.25.152.41" ] || \
			   [ $TARGET == "172.25.152.42" ] || \
			   [ $TARGET == "172.25.152.43" ] || \
			   [ $TARGET == "172.25.152.44" ] || \
			   [ $TARGET == "172.25.152.45" ];then
				ssh -q $TARGET "cd $SEARCHDIR/cse.Interface_2/conf/;tar jcf $SEARCHDIR/cse.Interface_2/interface.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
				rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/standby.ule.cse/* $TARGET:$SEARCHDIR/cse.Interface_2/conf/
				ssh -q $TARGET "bash cse.Interface_2_restart.sh &>/dev/null"
			else
				ssh -q $TARGET "cd $SEARCHDIR/cse.Interface/conf/;tar jcf $SEARCHDIR/cse.Interface/interface.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
				rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/ule.cse/* $TARGET:$SEARCHDIR/cse.Interface/conf/
				ssh -q $TARGET "bash cse.Interface_restart.sh &>/dev/null"
			fi
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done	
		;;

	cse.Interface.conf.bi)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Interface_3/conf/;tar jcf $SEARCHDIR/cse.Interface_3/Interface.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Interface.conf/$ENVRIONMENT/ule.bi/* $TARGET:$SEARCHDIR/cse.Interface_3/conf/
			ssh -q $TARGET "bash cse.Interface_3_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Interface.conf.vps.order)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Interface/conf/;tar jcf $SEARCHDIR/cse.Interface/Interface.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Interface.conf/$ENVRIONMENT/vps.order.ule.cse/* $TARGET:$SEARCHDIR/cse.Interface/conf/
			ssh -q $TARGET "bash cse.Interface_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done	
		;;

	cse.Interface.conf.vps)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Interface_9030/conf/;tar jcf $SEARCHDIR/cse.Interface_9030/Interface.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Interface.conf/$ENVRIONMENT/vps.ule.cse/* $TARGET:$SEARCHDIR/cse.Interface_9030/conf/
			ssh -q $TARGET "bash cse.Interface_restart_9030.sh > /dev/null" >/dev/null > /dev/null
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.DataSyncCenter2.conf)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.DataSyncCenter/conf/;tar jcf $SEARCHDIR/cse.DataSyncCenter/DataSyncCenter2.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/* $TARGET:$SEARCHDIR/cse.DataSyncCenter/conf/
			ssh -q $TARGET "bash cse.DataSyncCenter2_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	dict)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/elasticsearch_1/config/mmseg/;tar jcf $SEARCHDIR/elasticsearch_1/config/mmseg/dict.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/* $TARGET:$SEARCHDIR/elasticsearch_1/config/mmseg/
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.DataSyncCenter2.conf.vps)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.DataSyncCenter/conf/;tar jcf $SEARCHDIR/cse.DataSyncCenter/DataSyncCenter2.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/* $TARGET:$SEARCHDIR/cse.DataSyncCenter/conf/
			ssh -q $TARGET "bash cse.DataSyncCenter2_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Indexer.conf)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh $TARGET "cd $SEARCHDIR/cse.Indexer/conf/;tar jcf $SEARCHDIR/cse.Indexer/indexer.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			if [ $TARGET == "172.25.152.42" ];then
				   rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/standby.ule.cse/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			else
				   rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/ule.cse/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			fi
			ssh  $TARGET "bash cse.Indexer_restart.sh > /dev/null" >/dev/null > /dev/null
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Indexer.conf.bi)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Indexer/conf/;tar jcf $SEARCHDIR/cse.Indexer/indexer.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Indexer.conf/$ENVRIONMENT/ule.bi/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			ssh -q $TARGET "bash cse.Indexer_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Indexer.conf.mall)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Indexer/conf/;tar jcf $SEARCHDIR/cse.Indexer/indexer.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			if [ $TARGET == "172.24.139.55" ];then
				rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Indexer.conf/$ENVRIONMENT/ule.mall/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			else
				rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Indexer.conf/$ENVRIONMENT/standby.ule.mall/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			fi
			ssh -q $TARGET "bash cse.Indexer_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Indexer.conf.vps.order)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Indexer/conf/;tar jcf $SEARCHDIR/cse.Indexer/indexer.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			ssh -q $TARGET "bash cse.Indexer_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Indexer.conf.vps)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Indexer/conf/;tar jcf $SEARCHDIR/cse.Indexer/indexer.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/cse.Indexer.conf/$ENVRIONMENT/vps.ule.cse/* $TARGET:$SEARCHDIR/cse.Indexer/conf/
			ssh -q $TARGET "sh cse.Indexer_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;

	cse.Monitor.conf)
		for TARGET in $(cat ${IPLISTDIR}/${MODULE}_${APP}_${ENVRIONMENT}.txt)
		do
			ssh -q $TARGET "cd $SEARCHDIR/cse.Monitor/conf/;tar jcf $SEARCHDIR/cse.Monitor/indexer.$(date +%F%H%M).tar.gz --exclude *.tar.gz *"
			rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$ENVRIONMENT/* $TARGET:$SEARCHDIR/cse.Monitor/conf/
			ssh -q $TARGET "sh cse.Monitor_restart.sh &>/dev/null"
			echo -e "\033[32;1;5m**************** restart $ENVRIONMENT Update $TARGET ****************\033[0m\n"
		done
		;;
esac
}

# Main
if [ $APP == "cse.client" ] || [ $APP == "listingSearchAPIClient_HK" ] || [ $APP == "listingSearchAPIClient_CN" ] || [ $APP == "wordTools" ];then
	echo -e "\033[32;1;5m此项目只需要打包就行了，生产也一样\033[0m\n"
	exit   
elif [ $APP == "listingSearchAPI_CN" ] || [ $APP == "cloudsearchconsole" ] || [ $APP == "itemSearchAPI_CN" ];then
	search_tomcat
elif [ $APP == "recommendEngine" ] || \
	[ $APP == "seToolBox" ] || \
	[ $APP == "cse.Interface" ] || \
	[ $APP == "cse.DataSyncCenter2" ] || \
	[ $APP == "cse.plugin.cms" ] || \
	[ $APP == "cse.plugin.psbc" ] || \
	[ $APP == "cse.plugin.risk" ] || \
	[ $APP == "cse.plugin.vps" ] || \
	[ $APP == "cse.plugin.yqz" ] || \
	[ $APP == "cse.plugin.yzg.order" ] || \
	[ $APP == "cse.plugin.point" ] || \
	[ $APP == "cse.plugin.purchase" ] || \
	[ $APP == "cse.plugin.shoppingorder" ] || \
	[ $APP == "cse.plugin.ulemall" ] || \
	[ $APP == "cse.plugin.ws" ] || \
	[ $APP == "cse.plugin.yzg" ] || \
	[ $APP == "cse.plugin.store" ] || \
	[ $APP == "cse.plugin.merchant.license" ] || \
	[ $APP == "cse.plugin.bihotsale" ] || \
	[ $APP == "cse.plugin.cloudSuggest" ] || \
	[ $APP == "cse.plugin.address" ] || \
	[ $APP == "cse.plugin.dg" ] || \
	[ $APP == "cse.plugin.lifeService" ] || \
	[ $APP == "cse.plugin.hotel" ] || \
	[ $APP == "cse.plugin.monitor" ] || \
	[ $APP == "cse.plugin.comment" ] || \
	[ $APP == "cse.plugin.order" ] || \
	[ $APP == "cse.plugin.merchantinfo" ] || \
	[ $APP == "cse.plugin.userMessage" ] || \
	[ $APP == "cse.Indexer" ] || \
	[ $APP == "cse.Monitor" ] || \
	[ $APP == "ulemall.DataSyncCenter" ] || \
	[ $APP == "cse.plugin.wallet" ] || \
	[ $APP == "cse.plugin.shoppingorderitem" ] || \
	[ $APP == "cse.plugin.finance" ] || \
	[ $App == "cse.plugin.merdataindex4settlement" ] || \
	[ $App == "cse.plugin.merdataindex4merchant" ] || \
	[ $App == "cse.plugin.returnregisterinfo" ];then
	search_jar
#elif [ $APP == "cse.plugin.wallet" ];then
#	APPDIR=="cse.DataSyncCenter/plugins"
#	rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/$FILE $TARGET:$REPOSITORYDIR/$APPDIR/
#	cd $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/
#	wget http://maven.beta.ulechina.tom.com/artifactory/repo/com/ule/item/ejb/ule.itemEJB/$ENVRIONMENT-1.0.4/ule.itemEJB-$ENVRIONMENT-1.0.4-client.jar
#	wget http://maven.beta.ulechina.tom.com/artifactory/repo/com/ule/store/ejb/ule.storeEJB/$ENVRIONMENT-1.0.3/ule.storeEJB-$ENVRIONMENT-1.0.3-client.jar
#	rsync -avz --progress $JENKINSDIR/$ENVRIONMENT/$MODULE/$APP/*-client.jar $TARGET:$SEARCHDIR/$APPDIR/
#	search_jar
elif [ $APP == "crawlerToolbox" ] || [ $APP == "crawler" ];then
	search_timer
elif [ $APP == "cse.Interface.conf" ] || \
	[ $APP == "cse.Interface.conf.vps.order" ] || \
	[ $APP == "cse.DataSyncCenter2.conf" ] || \
	[ $APP == "cse.DataSyncCenter2.conf.vps" ] || \
	[ $APP == "cse.Indexer.conf" ] || \
	[ $APP == "cse.Indexer.conf.vps.order" ] || \
	[ $APP == "cse.Monitor.conf" ] || \
	[ $APP == "cse.Indexer.conf.vps" ] || \
	[ $APP == "cse.Indexer.conf.bi" ] || \
	[ $APP == "cse.Indexer.conf.mall" ] || \
	[ $APP == "cse.Interface.conf.vps" ] || \
	[ $APP == "dict" ];then
	search_conf
fi
