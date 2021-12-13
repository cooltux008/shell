#!/bin/bash
SRC_REGISTRY=src.repo.com
DEST_REGISTRY=dest.repo.com:5000
SRC_USER=hello
SRC_PASSWORD=hello

for IMAGE in `cat byte.txt`
do
DEST_REPO=`echo ${IMAGE} | awk -F'/' '{print $1}'`
docker run -i --rm \
    -v /etc/hosts:/etc/hosts \
    ananace/skopeo:latest sync \
    --dest-tls-verify=false \
    --src-creds=${SRC_USER}:${SRC_PASSWORD} \
    --src=docker \
    --dest=docker \
    ${SRC_REGISTRY}/${IMAGE} ${DEST_REGISTRY}/${DEST_REPO}
done
