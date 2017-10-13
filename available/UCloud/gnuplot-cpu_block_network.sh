##################################################################
#/bin/env bash
#To ananyze cpu load & block I/O in a priod of time
#Made by liujun,jlive.liu@ucloud.cn,2015-04-03
##################################################################

date=$1
start_time="00:00:00"
end_time="23:59:00"


#sysstat & gnuplot ?
flag_sysstat=$(which sar 2>/dev/null)
flag_gnuplot=$(which gnuplot 2>/dev/null)
if [ "$flag_sysstat" == "" ];then
        echo -e "\e[31;1mError\e[0m, No \e[32;1msysstat\e[0m"
	exit 1
fi
if [ "$flag_gnuplot" == "" ];then
        echo -e "\e[31;1mError\e[0m, No \e[32;1mgnuplot\e[0m"
	exit 1
fi

#$1?
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mfoo.txt or sar_date(eg,01)\e[0m"
	exit 1
fi


picture_cpu_load=$PWD/${date}_cpu_load.png
picture_cpu_useage=$PWD/${date}_cpu_useage.png
picture_block=$PWD/${date}_block.png
picture_network=$PWD/${date}_network.png

gnuplot_cpu_load=/tmp/${date}_gnuplot_cpu_load.txt
gnuplot_cpu_useage=/tmp/${date}_gnuplot_cpu_useage.txt
gnuplot_block=/tmp/${date}_gnuplot_block.txt
gnuplot_network=/tmp/${date}_gnuplot_network.txt

data_cpu_load=/tmp/${date}_data_cpu_load.txt
data_cpu_useage=/tmp/${date}_data_cpu_useage.txt
data_block=/tmp/${date}_data_block.txt
data_network=/tmp/${date}_data_network.txt

#delete_tmp_data
delete_tmp_data(){
for data in $gnuplot_cpu_load $gnuplot_cpu_useage $gnuplot_block $gnuplot_network $data_cpu_load $data_cpu_useage $data_block $data_network
do
	rm -rf $data 2>/dev/null
done
}

#Data
sar_data_centos(){
if [ -f $date ];then
	sar_data_file="$date"
	else
	sar_data_file="/var/log/sa/sa$date"
fi
if [ ! -f $sar_data_file ];then
	echo -e "Error, No \e[31;1m$sar_data_file\e[0m"
	delete_tmp_data
	exit 1
fi
if [ "$start_time" == "" ] && [ "$end_time" == "" ];then
LANG=C sar -q  -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_load
LANG=C sar -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_useage
LANG=C sar -b  -f $sar_data_file|egrep -v "Linux|^$|bread|Average"|awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5*512/1024"\t"$6*512/1024}' >$data_block
LANG=C sar -n DEV  -f $sar_data_file|egrep -v "Linux|^$|bread|Average|lo|IFACE" >$data_network
	elif [ ! "$start_time" == "" ] && [ ! "$end_time" == "" ];then
	LANG=C sar -q -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_load
	LANG=C sar -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_useage
	LANG=C sar -b -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|bread|Average"|awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5*512/1024"\t"$6*512/1024}' >$data_block
	LANG=C sar -n DEV -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|bread|Average|lo|IFACE" >$data_network
		else
			echo -e 'Error,please enter \e[31;1m"start_time" & "end_time\e[0m"(eg,22:30:00)'
			delete_tmp_data
			exit 1
fi
}
sar_data_ubuntu(){
if [ -f $date ];then
	sar_data_file="$date"
	else
	sar_data_file="/var/log/sysstat/sa$date"
fi
if [ ! -f $sar_data_file ];then
	echo -e "Error, No \e[31;1m$sar_data_file\e[0m"
	exit 1
fi
if [ "$start_time" == "" ] && [ "$end_time" == "" ];then
LANG=C sar -q  -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_load
LANG=C sar -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_useage
LANG=C sar -b  -f $sar_data_file|egrep -v "Linux|^$|bread|Average"|awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5*512/1024"\t"$6*512/1024}' >$data_block
LANG=C sar -n DEV  -f $sar_data_file|egrep -v "Linux|^$|bread|Average|lo|IFACE" >$data_network
	elif [ ! "$start_time" == "" ] && [ ! "$end_time" == "" ];then
	LANG=C sar -q -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_load
	LANG=C sar -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|runq-sz|Average" >$data_cpu_useage
	LANG=C sar -b -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|bread|Average"|awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5*512/1024"\t"$6*512/1024}' >$data_block
	LANG=C sar -n DEV -s $start_time -e $end_time -f $sar_data_file|egrep -v "Linux|^$|bread|Average|lo|IFACE" >$data_network
		else
			echo -e 'Error,please enter \e[31;1m"start_time" & "end_time\e[0m"(eg,22:30:00)'
			delete_tmp_data
			exit 1
fi
}

gnuplot_data(){
#Picture
#CPU_load(1,5,15)
cat >$gnuplot_cpu_load <<HERE
set xdata time 
set timefmt '%H:%M:%S' 
set xlabel 'Time' 
set format x '%H:%M:%S' 
set ylabel 'CPU Load(1,5,15)' 
set yrange [0:] 
set xtics rotate
set terminal png enhanced 
set output "$picture_cpu_load" 
plot "$data_cpu_load" using 1:4 title '1-min' with lines,\
"$data_cpu_load" using 1:5 title '5-min' with lines,\
"$data_cpu_load" using 1:6 title '15-min' with lines 

HERE
#CPU_useage(user%,system%,idle%)
cat >$gnuplot_cpu_useage <<HERE
set xdata time 
set timefmt '%H:%M:%S' 
set xlabel 'Time' 
set format x '%H:%M:%S' 
set ylabel 'CPU Useage(%)' 
set yrange [0:] 
set xtics rotate
set terminal png enhanced 
set output "$picture_cpu_useage" 
plot "$data_cpu_useage" using 1:3 title 'user%' with lines,\
"$data_cpu_useage" using 1:5 title 'system%' with lines
HERE

#Block(bread/s,bwrtn/s)
cat >$gnuplot_block <<HERE
set xdata time 
set timefmt '%H:%M:%S' 
set xlabel 'Time' 
set format x '%H:%M:%S' 
set ylabel 'Block IO(KB)'
set yrange [0:] 
set xtics rotate
set terminal png enhanced 
set output "$picture_block" 
plot "$data_block" using 1:5 title 'bread/s' with lines,\
"$data_block" using 1:6 title 'bwrtn/s' with lines 
HERE

#Network(rxpck/s   txpck/s)
cat >$gnuplot_network <<HERE
set xdata time 
set timefmt '%H:%M:%S' 
set xlabel 'Time' 
set format x '%H:%M:%S' 
set ylabel 'Network'
set yrange [0:] 
set xtics rotate
set terminal png enhanced 
set output "$picture_network" 
plot "$data_network" using 1:3 title 'rxpck/s' with lines,\
"$data_network" using 1:4 title 'txpck/s' with lines 
HERE
}

pictrue(){
#Create pictures
gnuplot $gnuplot_cpu_load 2>/dev/null 
echo -e "\e[32;1m$picture_cpu_load\e[0m is \e[31;1mcreated\e[0m"
gnuplot $gnuplot_cpu_useage 2>/dev/null 
echo -e "\e[32;1m$picture_cpu_useage\e[0m is \e[31;1mcreated\e[0m"
gnuplot $gnuplot_block 2>/dev/null 
echo -e "\e[32;1m$picture_block\e[0m is \e[31;1mcreated\e[0m"
gnuplot $gnuplot_network 2>/dev/null 
echo -e "\e[32;1m$picture_network\e[0m is \e[31;1mcreated\e[0m"
}


##Function

#sar_data_ubuntu
sar_data_centos

gnuplot_data
pictrue

delete_tmp_data
