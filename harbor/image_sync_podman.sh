#!/bin/bash
SRC_REGISTRY=registry.cn-hangzhou.aliyuncs.com/google_containers
DEST_REGISTRY=mirrors.tencent.com/infosec-devops

ARCH=amd64
for IMAGE in $(cat byte.txt); do
    podman pull $SRC_REGISTRY/$IMAGE --arch $ARCH
    podman tag $SRC_REGISTRY/$IMAGE $DEST_REGISTRY/$IMAGE
    podman push $DEST_REGISTRY/$IMAGE
done
