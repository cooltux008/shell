#!/bin/sh

if [ $# -eq 1 ];then
    export STATE=$1
    if [ "$STATE" == "on" -o "$STATE" == "off" ];then
	export DEVICE=$(networksetup -listallnetworkservices | head -n 2 | tail -n 1)
	sudo networksetup -setwebproxy WI-FI $HTTP_PROXY_IP $HTTP_PROXY_PORT $STATE "$USER" "$PASSWORD" 2>/dev/null
	sudo networksetup -setwebproxystate WI-FI $STATE
	sudo networksetup -setsecurewebproxy WI-FI $HTTPS_PROXY_IP $HTTPS_PROXY_PORT $STATE "$USER" "$PASSWORD" 2>/dev/null
	sudo networksetup -setsecurewebproxystate WI-FI $STATE
    else
	echo "Usage:$0 <on|off>"
	exit 1
    fi
else
    echo "Usage:$0 <on|off>"
    exit 1
fi
