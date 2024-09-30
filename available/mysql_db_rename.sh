#!/bin/bash

host=
port=
user=
pass=
while read line; do
    src_db=$(echo ${line} | awk -F, '{print $1}')
    dest_db=$(echo ${line} | awk -F, '{print $2}')
    src_tables=$(mysql -u "${user}" -p"${pass}" -h "${host}" -P "${port}" ${src_db} -e "show tables\G" | awk -F: '{print $2}' | grep -v '^$')
    dest_tables=$(mysql -u "${user}" -p"${pass}" -h "${host}" -P "${port}" ${dest_db} -e "show tables\G" | awk -F: '{print $2}' | grep -v '^$')
    for tb in ${src_tables}; do
        echo mysql -u "${user}" -p"${pass}" -h "${host}" -P "${port}" -e "RENAME TABLE ${src_db}.${tb} TO ${src_db}.${tb}_20240930" | tee -a ${src_db}.txt
        #mysql -u "${user}" -p"${pass}" -h "${host}" -P "${port}" -e "RENAME TABLE ${src_db}.${tb} TO ${src_db}.${tb}_20240930"
    done
    for tb in ${dest_tables}; do
        echo mysql -u "${user}" -p"${pass}" -h "${host}" -P "${port}" -e "RENAME TABLE ${dest_db}.${tb} TO ${src_db}.${tb}" | tee -a ${dest_db}.txt
        #mysql -u "${user}" -p"${pass}" -h "${host}" -P "${port}" -e "RENAME TABLE ${dest_db}.${tb} TO ${src_db}.${tb}"
    done

done <db.txt
