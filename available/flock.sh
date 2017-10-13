#!/bin/bash
# flock -xn .lock -c 'cat'

#exec <>$0
{
	flock -n 8
	if [ $? -eq 1 ];then
		echo fail
		exit
	fi
	echo $$
	for i in $(seq 10)
	do
		echo $i
		sleep 1
	done
} 8<>$0
