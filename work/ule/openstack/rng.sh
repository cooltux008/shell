#!/bin/bash
for host in $(cat host.txt)
do
	echo $host
	ssh $host 'flag=$(ps -ef|grep rngd|grep -v grep);[ -z "$flag" ] && (modprobe tpm-rng;echo tpm-rng >> /etc/modules;service rng-tools restart)' 2>/dev/null
done
