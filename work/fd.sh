#!/bin/bash

# example 1
#打开3号fd用来输入，关联文件为/etc/passwd
exec 3< /etc/passwd
#让3号描述符成为标准输入
exec 0<&3
#此时cat的输入将是/etc/passwd，会在屏幕上显示出/etc/passwd的内容。
cat

#关闭3号描述符。
exec 3>&-

# example 2
#打开3号和4号描述符作为输出，并且分别关联文件。
exec 3> /tmp/stdout

exec 4> /tmp/stderr

#将标准输入关联到3号描述符，关闭原来的1号fd。
exec 1>&3-
#将标准报错关联到4号描述符，关闭原来的2号fd。
exec 2>&4-

#这个find命令的所有正常输出都会写到/tmp/stdout文件中，错误输出都会写到/tmp/stderr文件中。
find /etc/ -name "passwd"

#关闭两个描述符。
exec 3>&-
exec 4>&-
