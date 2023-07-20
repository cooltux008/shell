#!/bin/bash
> pidlist
for pid in $(ps -ef|grep myapp|grep -v grep|awk '{print $2}')
do
    limit=$(grep "Max open files" /proc/$pid/limits|awk '{print $4}')
    fact=$[$(ls /proc/$pid/fd/ -l|wc -l)-1]
    if [ $fact -ge $limit ];then
        echo $pid >> pidlist
    fi
done

