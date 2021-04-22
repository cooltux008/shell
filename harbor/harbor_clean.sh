#!/bin/bash
HARBOR_API="http://192.168.56.200"
HARBOR_USER="admin"
HARBOR_PASS="Harbor12345"
HARBOR_DATA="/harbor/data"
PRO="$1"

# clean tags
rm_tags()
{
    echo "软删除 ${rp}/${t}"
    curl -X DELETE -H 'Accept: text/plain' -u ${HARBOR_USER}:${HARBOR_PASS} "${HARBOR_API}/api/repositories/${rp}/tags/${t}"

}

# garbage collect
garbage_collect()
{
   cd ${HARBOR_DATA}
   docker-compose -f docker-compose.yml stop
   docker run -it --name gc --rm --volumes-from registry vmware/registry:2.6.2-photon garbage-collect /etc/registry/config.yml
   docker-compose -f docker-compose.yml start
}


# project id
PROJECT_ID=$(curl -s -X GET --header 'Accept: application/json' "${HARBOR_API}/api/projects"|grep -w -B 2 "${PRO}" |grep "project_id"|awk -F '[:, ]' '{print $7}')
echo ${PROJECT_ID}

#  repositories
REPOS=$(curl -s -X GET --header 'Accept: application/json' "${HARBOR_API}/api/repositories?project_id=${PROJECT_ID}"|grep "name"|awk -F '"' '{print $4}')

# clean
#for rp in ${REPOS}
#do
#    echo ${rp}
#
#    TAGS=$(curl -s -X GET --header 'Accept: application/json' "${HARBOR_API}/api/repositories/${rp}/tags"|grep \"name\"|awk -F '"' '{print $4}'|sort -r |awk 'NR > 9 {print $1}')
#
#    for t in ${TAGS}
#    do
#        echo ${t}
#        rm_tags
#    done
#done
