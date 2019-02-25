#!/bin/bash
export res=$(grep -w 'Pss' /proc/$(pidof dockerd)/smaps|awk '{total+=$2}; END {print total}')
if [[ $res -ge 5242880 ]];then
        echo docker_mem=0
else
        echo docker_mem=1
fi
