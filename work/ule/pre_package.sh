#!/bin/bash
MAIN_PATH="/data/postmall/deploy"
SRC_PATH="${MAIN_PATH}/src/maven/jenkins"
TIMER_SRC_PATH="${MAIN_PATH}/src/timer"
LOG_PATH="$MAIN_PATH/logs/maven"
SHELL_PATH="/data/postmall/deploy/shell/maven"

if [ $# -eq 5 ];then
	AppEnv=$1
	ServerType=$2
	ModuleName=$3
	AppName=$4
	AppSvnVersion=$5
	AppMetaPath=$SRC_PATH/$ServerType/$ModuleName/$AppName/src/main/conf/$AppEnv
else
	DMID=$1
	python $SHELL_PATH/timer_python.py $DMID
	. $SHELL_PATH/timer_python.list

	AppEnv=$DEPLOY_ENV
	ServerType="timer"
	ModuleName=$MODULE
	AppName=$APP
	AppSvnVersion=$VERSION_NUMBER
	AppMetaPath=$TIMER_SRC_PATH/$TIMER_DIR/conf/$AppEnv
fi
application_metadata() {
	if [ -d $AppMetaPath ];then
		AppMeta=$AppMetaPath/applicationMetadata.properties 
		echo "[$(date +%F-%H-%M-%S.%N)] [Info] $AppMetaPath"|tee -a $LOG_PATH/pre_package_ok.log.$(date +%Y%m) 
	else
		echo "[$(date +%F-%H-%M-%S.%N)] [Error] $AppMetaPath"|tee -a $LOG_PATH/pre_package_error.log.$(date +%Y%m)
	fi
	if [ -n "$AppMeta" ];then
		cat >$AppMeta<<EOF
ModuleName=$ModuleName
AppType=$ServerType
AppEnv=$AppEnv
AppName=$AppName
AppId=${ModuleName}-${AppName}
AppSvnVersion=$AppSvnVersion
EOF
	fi
}

application_metadata

