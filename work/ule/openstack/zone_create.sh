#!/bin/bash
#https://docs.openstack.org/nova/latest/user/aggregates.html
for host in $(cat zone.txt)
do
	name=$(echo $host|awk -F'CT' '{print $1}')_local
	domain=$(echo $host|awk -F. '{print $1}')
	nova aggregate-create $name $domain
	nova aggregate-add-host $name $host
done
