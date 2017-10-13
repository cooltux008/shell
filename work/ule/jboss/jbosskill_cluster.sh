#!/bin/bash

if [ $# -lt 3 ]

then
echo "Usage: $0 projectname ip port"
exit 0;

fi

domainname=$1

domainip=$2

port=$3

partitionname=$4

mcastip=$5

nodeid=$6

ps -ef |grep java |grep -w ${domainname}|grep -v grep|awk '{print $2}'|xargs kill -9
netstat -anp|grep $port|grep LISTEN|awk '{print  $7}'|awk -F/ '{print  $1}'|xargs kill -9

sleep 7

 

JBOSS_HOME="/data/jboss"

DOMAIN_IP="$domainip"

DOMAIN_NAME="$domainname"

JBOSS_REDIRECT_LOG=/data/logs/jboss/${DOMAIN_NAME}.log

 

export JAVA_HOME=/usr/local/jdk1

export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

export PATH=.:$PATH:$JAVA_HOME/bin

export CTOC_PATH="${JBOSS_HOME}/server/${DOMAIN_NAME}/conf"

 

echo

echo "################################################################################"

echo "#                             Starting Jboss"

echo "# domain ip   is: ${DOMAIN_IP}"

echo "# domain name is: ${DOMAIN_NAME}"

echo "# redirecting output to: tail -fn100 ${JBOSS_REDIRECT_LOG}.`date +'%Y%m%d'`"

echo "################################################################################"

echo

 

if [ -d "${JBOSS_HOME}/server/${DOMAIN_NAME}/tmp" ]

then

rm -fr ${JBOSS_HOME}/server/${DOMAIN_NAME}/tmp/*

fi

 

PROCESS=`ps -ef|grep java|grep '\<$domainname\>'$|grep -v zabbix|wc -l`



if [ "$PROCESS" = "0" ]

then
if  [ "$port" = "1100" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-default 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &


elif  [ "$port" = "1200" ];

then


sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-01 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &


elif [ "$port" = "1300" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-02 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "1400" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-03 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "1500" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-04 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "1600" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-05 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "1700" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-06 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "1800" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-07 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "1900" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-08 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "2000" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-09 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

elif [ "$port" = "2100" ];

then

sh ${JBOSS_HOME}/bin/run.sh  -g ${partitionname} -u ${mcastip} -b ${DOMAIN_IP} -c ${DOMAIN_NAME} -Djboss.messaging.ServerPeerID=${nodeid} -Djboss.service.binding.set=ports-10 2>&1 | /usr/sbin/rotatelogs ${JBOSS_REDIRECT_LOG}.%Y%m%d 86400 480 &

else

    echo "ERROR!!!! WRONG parameter ! PLEASE CHECK YOUR SCRIPT!"

fi

fi

