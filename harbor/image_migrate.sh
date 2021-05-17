#!/bin/bash

DEST_DOMAIN="yourdomain.com"
SRC_REGISTRY_DATA_DIR="/harbor/data/registry"

#registry 存储的 blob 目录 | repositories 目录 | skopeo 目录
BLOB_DIR="${SRC_REGISTRY_DATA_DIR}/docker/registry/v2/blobs/sha256"
REPO_DIR="${SRC_REGISTRY_DATA_DIR}/docker/registry/v2/repositories"
SKOPEO_DIR="${SRC_REGISTRY_DATA_DIR}/skopeo"

cd ${SRC_REGISTRY_DATA_DIR}


#一个 tag 对应一个 current 目录
skopeo_dir_gen() {
for image in $(find ${REPO_DIR} -type d -name "current")
do
	##---manifest.json---##
	#根据镜像的 tag 提取镜像的名字
	name=$(echo ${image} | awk -F"(.*repositories/)|(/_manifests/tags/)|(/current)" '{print $1,$2":"$3}'|tr -d ' ')
	link=$(cat ${image}/link | awk -F':' '{print $2}')
	manifest="${BLOB_DIR}/${link:0:2}/${link}/data"
	#硬链manifest.json
	mkdir -p "${SKOPEO_DIR}/${name}"
	ln -f ${manifest} ${SKOPEO_DIR}/${name}/manifest.json

	##---layer/images config---##
	#匹配 sha256 值，排序去重
	layers=$(grep -Eo "\b[a-f0-9]{64}\b" ${manifest} | sort -u)
	for layer in ${layers}
	do
		#硬链 registry 存储目录里的镜像 layer 和 images config 到 skopeo dir 目录
		ln -f ${BLOB_DIR}/${layer:0:2}/${layer}/data ${SKOPEO_DIR}/${name}/${layer}
	done
done
}


#skopeo sync dir to harbor
image_sync() {
for project in $(ls ${SKOPEO_DIR}); do
	docker run -i --rm \
		-v ${SKOPEO_DIR}:${SKOPEO_DIR} \
		-v /etc/hosts:/etc/hosts \
		ananace/skopeo:latest sync \
		--dest-tls-verify=false \
		--dest-creds=admin:Harbor12345 \
		--src=dir \
		--dest=docker \
		${SKOPEO_DIR}/${project} ${DEST_DOMAIN}/${project}
done
}

#run
skopeo_dir_gen
image_sync
