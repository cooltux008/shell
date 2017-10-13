#!/bin/bash
read -p "Directory:" dir
read -p "source format:(png or bmp ...)" sf
read -p "object format:(xpm or ...)" of
read -p "geometry:(800x600...)" go
read -p "colors:(16 ...)" co
for i in $(ls *.$sf $dir)
	do
		convert $i -geometry  $go -colors $co  ${i%.*}.$of
	done
echo "Done"
