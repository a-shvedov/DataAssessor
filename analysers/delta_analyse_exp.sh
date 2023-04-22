#!/bin/bash
set -euo pipefail

#determination of temporary deviations that fell into the failover logs;

#user_opts:
FLBACKUP='y' #бэкап входного файла вклчючен по
#def_opts:

while getopts ":i:p" opt; do

case $opt in
    i)
      inputfile=$OPTARG
      ;;
	p)
      PATTERN_MODE='y' && read -t 30 -p "Run with <-p> - write pattern string:" -e -i "" PATTERN_MODE_string
      ;;

    \?)
      printf "\n${desc}\nВведена неподдерживаемая опция: -${OPTARG}\nДоступны: -i [входной файл] -p [паттерн]\n" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
	esac
done

if [ "$FLBACKUP" == "y" ]; then echo 'FLBACKUP=on - backuping input file' 
	if [[ -f "$inputfile" ]]; then previous_inputfile=$inputfile && cp "$inputfile" "${inputfile}.deltabak"; 
else echo "FLBACKUP=off"; 
fi
fi

checkers(){

rexist(){
if [[ ! -f "$inputfile" ]]; then echo "Error: input file $inputfile not exist" >&2
  exit 1
fi
}
rsize(){
if [[ ! -s "$inputfile" ]]; then echo "Error: input file $inputfile is empty" >&2
  exit 1
fi
}

rfile(){
if [[ ! -f "$inputfile" || ! -r "$inputfile" ]]; then echo "Error: input file $inputfile is not readable" >&2
  exit 1
fi
}

debug_plugin_prepairng(){
if (( $(cat $inputfile | grep -E '[0-9]{10}' | head -n 1 | wc -l) == "1" )); then echo "Preparing input log..." && sed -i 's/[0-9]\{10\}//g' $inputfile; else :; fi
}

rformat(){
if (( $(cat $inputfile | grep -E '[0-9]{2}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}' | head -n 1 | wc -l) == "1" )); then :; 
else echo "Error: input file <$inputfile> have no correct timestamp format" >&2
  exit 1
fi
}

rexist_local_output(){
local_output=`pwd`/$(basename $inputfile).list
if test -f "$local_output"; then > "$local_output"; else touch "$local_output"; fi
}

rperiods(){
config_fl="/opt/uvk/NV/etc/config.ini"
if (( $(cat ${inputfile} | grep -o "message_dispatch_period" | head -n 1 | wc -l) == "1" )); 
then echo "found in file" ;
	else
		if (( $(cat ${config_fl} | grep -o "message_dispatch_period" | head -n 1 | wc -l) == "1" ));
			then echo "found in config" ;
				else echo "Not found  params in default locations"
fi
fi
}

rexist
rsize
rfile
debug_plugin_prepairng
rformat
rexist_local_output
#rperiods
}
checkers



function pattern_mode(){
if (( $(echo $PATTERN_MODE_string | grep -E "[[:alnum:]]" | head -n 1 | wc -l) == "1" ));
then echo 'PATTERN_MODE=on - pattern grepping' && cat ${inputfile} | grep -E "$(echo $PATTERN_MODE_string)" > /tmp/new_input
inputfile="/tmp/new_input" 
else echo "Set up pattern before using this script or suppress  - exit" ;
exit 1
inputfile="/tmp/new_input" 
fi
} ; if [ "$PATTERN_MODE" == "y" ]; then pattern_mode; else echo "Selecting all stings"; fi


function main(){
echo $(date +"%T.%3N") "Sorting now..."
function sub_prep() {
tmp_uuid=$(uuidgen)
	cat ${inputfile} | awk -F " " '{print $2}' | sed 's/[.:]//g' | uniq > /tmp/$tmp_uuid
	sed -i -E '/^[0-9]{9}$/!d;s/ //g' /tmp/$tmp_uuid	#band-aid-sol

while read -r line; do
	array+=("$line")
done < "/tmp/$tmp_uuid"
}
sub_prep

prev=${array[0]} #инициализируем для отслеживания предыдущего значения

sum=0 #инициализируем переменную для отслеживания средней разницы между значениями
count=0

for value in "${array[@]}"; do
	diff=$(( 10#$value - 10#$prev ))  #определяем разницу между значениями
	sum=$(( sum + diff )) #добавляем разницу к сумме, увеличиваем счетчик
	count=$(( count + 1 ))
	prev=$value #обновляем предыдущее значение
done

if [ $sum -ne 0 ]; then #005 - доп.проверка корректности входного файла
if [ $count -ne 0 ]; then #006

average=$(( sum / count )) #определяем среднее значение
prev=${array[0]}  #перебираем массив для определения отличных значений
for value in "${array[@]}"; do
	diff=$(( 10#$value - 10#$prev )) #определяем разницу
	if (( diff > average*2 )); then #eсли разница больше средней дельты, вывести значение

prep_tail(){
  if (( diff > 999 )); then
	subtract_tail_prev=$(( 1000 - 10#$(echo $prev | cut -c 7-10))) ; # определяем пороговую разницу для предыдущего значения +
	subtract_tail_value=$(echo 10#${value} | cut -c 8-10) ; # `: value too great for base (error token is "09")` - костыль в виде переноса значения 9-10 при двузначном значении - внести исправление; OK - #оболочка пытается интерпретировать 08 как восьмеричное число, поскольку оно начинается с нуля
	sum_tails=$(( 10#${subtract_tail_prev#0} + 10#${subtract_tail_value#0} )) ;
fi
}
prep_tail
function sub_sep() {
	local input_string=$1
	local formatted_string=${input_string:0:2}:${input_string:2:2}:${input_string:4:2}
	formatted_string=${formatted_string}.${input_string:6}
	echo "$formatted_string"
}
export -f sub_sep

formatted_string_value=$(sub_sep "$value")
formatted_string_prev=$(sub_sep "$prev")
	if (( diff > 999 )); 
		then : ;
	else
	echo "Strange value found: $formatted_string_value (previous value: <$formatted_string_prev> | difference: <$diff>)" >> ${local_output}; #добавить вывод номера строки с содержимым?
fi

fi
	prev=$value
done

else echo "Error sum" #005
fi #005
fi #006

result=$(cat "$local_output" | grep "difference" | wc -l)

if [[ "$result" -gt 1 ]]; then
    echo "diff found ($result)"
    elif [[ "$result" -gt 50 ]]; then
        echo "Result is greater than 50"
else :
fi

if [[ "$result" -gt 1 ]]; then 
	echo "$(date +"%T.%3N") Difference value found ($result) - collecting to <$local_output>";
	    elif [[ "$result" -gt 10 ]]; then
			echo "Difference value found ($result) - probably we have unstable connection between sides"
	echo "value is "$formatted_string_value
	else #007
	echo "Probably we have normally consistent log: <$local_output>";
	end_time=$(date +%s)
	elapsed_time=$(( $end_time - $start_time ))
	echo $(date +"%T.%3N") "Elapsed time: $elapsed_time seconds"
fi

echo $(date +"%T.%3N") "Extracting uniq differences:"
function short_summ(){
	differences=$(grep -o 'difference: <.*>' $local_output | awk -F '<' '{print $2}' | awk -F '>' '{print $1}')
IFS=$'\n' unique_differences=($(echo "$differences" | sort -u))
