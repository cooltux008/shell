#!/bin/bash

maven_path=$1
package_name=$2
Module=$3
App=$4

TAR(){
    rm -f ${package_name}
    jar -cvfm  ${package_name} ./META-INF/MANIFEST.MF  *
    cp ${maven_path}/temp/${package_name} ${maven_path}
    rm -rf ${maven_path}/temp
}

SED(){
    if [ ${Module} = "search_sphinx" -a "${App}" = "cse.DataSyncCenter" ];then
        sed  -i 's/RISK20150129CTL/SAs23SAsd2/g' ${maven_path}/new.xml
        sed  -i 's/ULEAPP_SCMALL_HB_USER/ULEAPP_SCMALL_HB/g' ${maven_path}/new.xml
        sed  -i 's/ULEAPP_SCMALL_HB_PWD/47DF4B9GFd/g' ${maven_path}/new.xml
        sed  -i 's/ule_cms_pwd/uleappcms_2015!/g' ${maven_path}/new.xml
        sed  -i 's/wqb123_ule_password/ap.p201.5pul.l/g' ${maven_path}/new.xml
    fi

    if [ ${Module} = "search_sphinx" -a "${App}" = "recommendEngine" ];then
        sed  -i 's/ULETMP_LOCK160430/uleapp_shopbasket_rec/g' ${maven_path}/new.xml
        sed  -i 's/lock.app.16TMP#/shop.16REC.20hs/g' ${maven_path}/new.xml
    fi

    if [ ${Module} = "search_sphinx" -a "${App}" = "listingSearchAPI" ];then
        sed  -i 's/openfire/uleapp_openfire/g' ${maven_path}/new.xml
        sed  -i 's/uChat123/Psfiea36!x2/g' ${maven_path}/new.xml
    fi
}

rm -rf ${maven_path}/temp
mkdir -p  ${maven_path}/temp

if [ -e ${maven_path}/${package_name} ];then
    cp ${maven_path}/${package_name} ${maven_path}/temp
    cd ${maven_path}/temp
    jar -xf ${package_name}
    if [ ${App} = "listingSearchAPI" -o ${App} = "recommendEngine" ];then
        if [ -e WEB-INF/classes/config.properties ];then
            cd WEB-INF/classes
            cat config.properties >${maven_path}/new.xml
            SED
            mv ${maven_path}/new.xml ${maven_path}/temp/WEB-INF/classes/config.properties
            chmod 600 ${maven_path}/temp/WEB-INF/classes/config.properties
            cd ../../
        else
           for conf in conf.properties config.properties
           do
               if [ -e $conf ];then
                    cat $conf >${maven_path}/new.xml
                    SED
                    mv ${maven_path}/new.xml ${maven_path}/temp/$conf
                    chmod 600 ${maven_path}/temp/$conf
                    echo -e "$conf replaced"
               fi
           done
        fi
    fi
    TAR
else
    echo -e "can not find file ${package_name}\n"
fi
