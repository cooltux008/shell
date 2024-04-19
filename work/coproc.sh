#!/bin/bash
#例一：简单命令使用
#简单命令使用不能通过NAME指定协进程的名字，此时进程的名字统一为：COPROC。
coproc tail -3 /etc/passwd
echo $COPROC_PID
exec 0<&${COPROC[0]}-
cat

#例二：复杂命令使用
#此时可以使用NAME参数指定协进程名称，并根据名称产生的相关变量获得协进程pid和描述符。

coproc _cat { tail -3 /etc/passwd; }
echo $_cat_PID
exec 0<&${_cat[0]}-
cat

#例三：更复杂的命令以及输入输出使用
#协进程的标准输入描述符为：NAME[1]，标准输出描述符为：NAME[0]。

coproc print_username {
	while read string
	do
		[ "$string" = "END" ] && break
		echo $string | awk -F: '{print $1}'
	done
}

echo "aaa:bbb:ccc" 1>&${print_username[1]}
echo ok

read -u ${print_username[0]} username

echo $username

cat /etc/passwd >&${print_username[1]}
echo END >&${print_username[1]}

while read -u ${print_username[0]} username
do
	echo $username
done
