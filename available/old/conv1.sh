#!/bin/bash
echo -e "请按下列格式输入图片所在\\033[31;1m目录\\e[0m \\e[32;1m源格式\\033[0m \\e[33;1m目标格式\\e[0m \\e[34;1m分辨率\\e[0m \\e[35;1m色彩深度\\e[0m"
echo ""
echo "/home/test png xpm 640x480 16"
echo ""
read -p "You input:" input

dir=$(echo $input|gawk '{print $1}')
sf=$(echo $input|gawk '{print $2}')
of=$(echo $input|gawk '{print $3}')
ge=$(echo $input|gawk '{print $4}')
co=$(echo $input|gawk '{print $5}')

echo "Please wait a moment"
cd $dir
for i in $(ls *.$sf)
	do
		convert $i -geometry $ge -colors $co ${i%.*}.$of|xargs gzip -f
	done
echo "Done"
