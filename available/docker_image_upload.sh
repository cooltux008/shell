#!/bin/bash
registry=192.168.130.1:5000
local_images=$(docker images|grep -v REPOSITORY|awk '{print $1":"$2}')
for image in $local_images
do
	docker tag $image $registry/$image
	docker push $registry/$image
done
