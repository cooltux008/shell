#!/bin/bash
#To diff version and export
#############################################

hotfix_date=$1
svn_url=
svn_user=
svn_password=
svn_dump_dir=
svn_hotfix_dir=
prd_deploy_dir=
hotfix_latest=$(ls -r $svn_dump_dir/ReleaseFiles 2>/dev/null|head -n1)

for dir in $svn_dump_dir $svn_hotfix_dir $prd_deploy_dir
do
	if [ ! -d $dir ];then
		mkdir -p $dir
	fi
done

svn_checkout(){
cd $svn_dump_dir
echo -e "\e[31;1mCheckOut\e[0m \e[34;1m${hotfix_date:-$hotfix_latest}\e[0m"
svn co $svn_url --username "$svn_user" --password $svn_password --non-interactive --trust-server-cert 
svn update $(basename $svn_url) --username "$svn_user" --password $svn_password --non-interactive --trust-server-cert
echo -e "\e[32;1mDone\e[0m"
}
svn_package(){
echo -e "\e[31;1mPackage\e[0m"
deploy_suffix=${hotfix_date:-$hotfix_latest}_$(date +%Y%m%d%H%M%S)
cp -a $svn_dump_dir/ReleaseFiles/${hotfix_date:-$hotfix_latest} $svn_hotfix_dir
cd $svn_hotfix_dir/${hotfix_date:-$hotfix_latest}
find  -maxdepth 1 -type d|grep -v ".svn"|sed '/^.$/d'|sed 's#./##g' >$svn_hotfix_dir/hotfix_dirs.txt
rm -rf $svn_hotfix_dir/tmp
mkdir -p $svn_hotfix_dir/tmp
for dir in $(cat $svn_hotfix_dir/hotfix_dirs.txt)
do
	if [ -n "$dir" ];then
		cp -a $svn_hotfix_dir/${hotfix_date:-$hotfix_latest}/$dir $svn_hotfix_dir/tmp
	fi
done
find $svn_hotfix_dir/tmp -type d -name "*.svn" -exec rm -rf {} \; &>/dev/null
if [ -d $svn_hotfix_dir/tmp/WebSphereCommerceServerExtensionsLogic ];then
	cp -f /root/work/arvato/stage/WebSphereCommerceServerExtensionsLogic.jar $svn_hotfix_dir/tmp/WebSphereCommerceServerExtensionsLogic
	cd $svn_hotfix_dir/tmp/WebSphereCommerceServerExtensionsLogic
	zip -ru WebSphereCommerceServerExtensionsLogic.jar * &>/dev/null
	mv WebSphereCommerceServerExtensionsLogic.jar $svn_hotfix_dir/tmp
	cd $svn_hotfix_dir/tmp
	rm -rf $svn_hotfix_dir/tmp/WebSphereCommerceServerExtensionsLogic
fi
cd $svn_hotfix_dir/tmp
zip -r $prd_deploy_dir/$deploy_suffix.zip * &>/dev/null
echo -e "\e[34;1mThe deploy file is \e[0m$prd_deploy_dir/\e[31;1m$deploy_suffix.zip\e[0m"
rm -rf $svn_hotfix_dir/${hotfix_date:-$hotfix_latest}
}

#main
svn_checkout
svn_package
