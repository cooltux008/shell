#!/bin/bash
SRC_REGISTRY=src.repo.com
DEST_REGISTRY=dest.repo.com:5000
SRC_USER=hello
SRC_PASSWORD=hello

while read image 
do
TARGET_REPO=$(echo ${IMAGE}|awk -F'/' '{print $2}')
docker run -i --rm \
    -v /etc/hosts:/etc/hosts \
    ananace/skopeo:latest sync \
    --dest-tls-verify=false \
    --src-creds=${SRC_USER}:${SRC_PASSWORD} \
    --src=docker \
    --dest=docker \
    ${IMAGE} ${DEST_REGISTRY}/${TARGET_REPO}
done < byte.txt
