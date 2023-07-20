pid=$1
echo -e "PID\tPPID\tCMD"
if [ ! -d "/proc/$pid" ]; then
    echo -ne ''
    exit 0
fi

function get_ppid()
{
    ps -o ppid= -p $1
}

pids[0]=$pid
i=1
while [ $pid != 0 ];
do
    ppid=`get_ppid $pid`
    if [ $ppid != 0 ];then
        pids[$i]=$ppid
    fi
    pid=$ppid
    i+=1
done
read -ra newpids <<< $(echo ${pids[*]} | tr ' ' '\n' | tac | tr '\n' ' ')
for ((i=0; i<=${#newpids[@]}-1; i++))
do
    pid=$(ps --no-headers -o pid -p ${newpids[$i]}|tr -d " ")
    ppid=$(ps --no-headers -o ppid -p ${newpids[$i]}|tr -d " ")
    cmd=$(ps --no-headers -o cmd -p ${newpids[$i]})
    echo -e "$pid\t$ppid\t$cmd"
done

