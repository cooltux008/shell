#####################################################
#!/bin/bash
#To batch convert pictures 
#Made by liujun, liujun_live@msn.com, 20140820
#####################################################
# Source function library.
. /etc/init.d/functions
#Export PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

#Define variables
Format_From=jpg           #原格式,png|bmp|gif,不要加.
Format_To=gif            #目标格式,png|bmp|gif,不要加.
Directory_From=/tmp       #原目录绝对路径
Directory_To=/tmp/test         #目标目录绝对路径
Size=			#指定目标尺寸大小1024x768
Pictures=$(ls $Directory_From/*.$Format_From)  #所有待转的图片

#Create the target directory
if [ ! -d "$Directory_To" ];then
	mkdir -p $Directory_To
fi


for picture in $Pictures
do
	BaseName=$(basename $picture)
	if [ "$Size" == "" ];then
	convert $Directory_From/$BaseName $Directory_To/${BaseName%.*}.$Format_To
	echo -e "\e[31;1m$Directory_From/$BaseName\e[0m \e[34;1m======>\e[0m \e[32;1m$Directory_To/${BaseName%.*}.$Format_To\e[0m"
	else
		convert -resize $Size $Directory_From/$BaseName $Directory_To/${BaseName%.*}.$Format_To
		echo -e "\e[31;1m$Directory_From/$BaseName\e[0m \e[34;1m======>\e[0m \e[35;1m$Size\e[0m \e[32;1m$Directory_To/${BaseName%.*}.$Format_To\e[0m"
	fi

done
echo -e "\n"
echo -e "Converting \e[32;1msucessfully!\e[0m"
exit 0
