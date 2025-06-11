#!/bin/bash

status=$(curl -s http://localhost/nginx_status)

active_connections=$(echo "$status" | awk '/Active connections:/{print $3}')

accepts=$(echo "$status" | sed -n '3p' | awk '{print $1}')
handled=$(echo "$status" | sed -n '3p' | awk '{print $2}')
requests=$(echo "$status" | sed -n '3p' | awk '{print $3}')

reading=$(echo "$status" | awk '/Reading:/{print $2}')
writing=$(echo "$status" | awk '/Reading:/{print $4}') 
waiting=$(echo "$status" | awk '/Reading:/{print $6}')

# 输出提取的指标值
echo "Active Connections: $active_connections"
echo "Accepts: $accepts"
echo "Handled: $handled"
echo "Requests: $requests"
echo "Reading: $reading"
echo "Writing: $writing"
echo "Waiting: $waiting"

# zhiyan
/usr/local/zhiyan/agent/bin/report_tool -app_mark nginx_monitor_test -calc_method 0 -instance_mark 11.179.95.28 -tag_set "ip=11.179.95.28&interface=upload" -metric_val "waiting=$waiting&writing=$writing&reading=$reading&active_connections=$active_connections&accepts=$accepts&handled=$handled&requests=$requests"

