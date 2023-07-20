#!/bin/bash

pid=$1

echo -e "PID\tPPID\tCMD"
if [ ! -d "/proc/$pid" ]; then
    echo -ne ''
    exit 0
fi

function get_ppid()
{
    grep 'PPid:' /proc/$1/status | awk '{print $2}'
}

function main()
{
    while [ $pid != 0 ];
    do
        ppid=`get_ppid $pid`
        cmdline=`cat /proc/$pid/cmdline`
        if [ "$cmdline" != "" ]; then
            echo -e "$pid\t$ppid\t`tr '\0' ' ' < /proc/$pid/cmdline`" | sed 's/[[:space:]]*$//'
        else
            name=`cat /proc/$pid/status | grep Name | awk '{print substr($2, 1, 15)}'`
            echo -e "$pid\t$ppid\t[$name]"
        fi
        pid="$ppid"
    done
}

main | tac

