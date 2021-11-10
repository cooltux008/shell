#!/bin/bash
while read image 
do
		target_repo=$(echo $image|awk -F'/' '{print $2}')
        docker run -i --rm \
                -v /etc/hosts:/etc/hosts \
                ananace/skopeo:latest sync \
                --dest-tls-verify=false \
                --src=docker \
                --dest=docker \
				$image 180.184.64.76/$target_repo
done < byte.txt
