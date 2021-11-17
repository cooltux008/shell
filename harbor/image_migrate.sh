#!/bin/bash

DEST_DOMAIN="yourdomain.com"
SRC_REGISTRY_DATA_DIR="/opt/registry"
HARBOR_USER="admin"
HARBOR_PASS="cleverPWD@sq.2021"

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


#create repo
create_repo() {
all_repos=$(ls ${SKOPEO_DIR})
for repo in ${all_repos}; do
	if [ -f ${SKOPEO_DIR}/${repo}/manifest.json ];then
		repo="root"
	fi
	result=$(curl -k -u "${HARBOR_USER}:${HARBOR_PASS}" -X GET -H "Content-Type: application/json" "https://${DEST_DOMAIN}/api/v2.0/projects/${repo}" 2>/dev/null)
	if [ "echo ${result}|grep -w errors" = "" ];then
		cat > createproject.json <<EOF
{ "project_name": "${repo}", "public": true }
EOF
	curl -k -u "${HARBOR_USER}:${HARBOR_PASS}" -X POST -H "Content-Type: application/json" "https://${DEST_DOMAIN}/api/v2.0/projects" -d @createproject.json
	fi
	index=$[$index+1]
done
}


#skopeo sync dir to harbor
image_sync() {
#statistic all images
all_repos=$(ls ${SKOPEO_DIR})
images_count=0
for repo in ${all_repos}
do
	images_in_repo=$(find ${SKOPEO_DIR}/${repo}/* -type d|wc -l)
	images_count=$[${images_count}+${images_in_repo}]
done

index=1
for repo in ${all_repos}; do
	echo [${index}/${images_count}]
	if [ -f ${SKOPEO_DIR}/${repo}/manifest.json ];then
		dest_repo=${DEST_DOMAIN}/root
	else
		dest_repo=${DEST_DOMAIN}/${repo}
	fi


        docker run -i --rm \
                -v ${SKOPEO_DIR}:${SKOPEO_DIR} \
                -v /etc/hosts:/etc/hosts \
                ananace/skopeo:latest sync \
                --dest-tls-verify=false \
                --dest-creds=${HARBOR_USER}:${HARBOR_PASS} \
                --src=dir \
                --dest=docker \
		$@ \
                ${SKOPEO_DIR}/${repo} ${dest_repo}

	index=$[$index+1]
done
}

#run
skopeo_dir_gen
create_repo
image_sync $@
