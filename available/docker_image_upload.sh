#!/bin/bash
registry=
local_images=$(docker images|egrep -v 'REPOSITORY|130'|awk '{print $1":"$2}')
for image in $local_images
do
	docker tag $image $registry/${image#*/}
	docker push $registry/${image#*/}
done
