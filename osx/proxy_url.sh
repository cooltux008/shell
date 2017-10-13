#!/bin/sh
export STATE=$1
if [ $# -eq 1 ];then
    if [ "$STATE" == "on" -o "$STATE" == "off" ];then
	sudo networksetup -setautoproxyurl WI-FI $HTTP_PROXY_URL
	sudo networksetup -setautoproxystate WI-FI $STATE
    else
	echo "Usage:$0 <on|off>"
	exit 1
    fi
else
    echo "Usage:$0 <on|off>"
    exit 1
fi
