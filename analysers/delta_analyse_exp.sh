#!/bin/bash

#determination of temporary deviations that fell into the failover logs;
#implemented using the Kronecker delta function

set -e

start_time=$(date +%s)

if [[ "$1" != "-i" ]]; then
    echo "Error: use -i flag to targeting file before running the script"
    exit 1
fi

while getopts ":i:" opt; do

  case $opt in
    i)
      inputfile=$OPTARG
      ;;
    \?)
      echo "Invalid option (supporing only <-i>): -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done

checkers(){

rsize(){
rtargetword(){
cat $1 | grep failover
}
#rtargetword
if [[ ! -s "$inputfile" ]]; then echo "Error: input file $inputfile is empty" >&2
  exit 1
fi
}

rfile(){
if [[ ! -f "$inputfile" || ! -r "$inputfile" ]]; then echo "Error: input file $inputfile is not readable" >&2
  exit 1
fi
}

rformat(){
if [[ $(cat "$inputfile"  | awk -F " " '{print $2}' | sed 's/[.:]//g' | head -n 1 | wc -l) -gt 0 ]] ; then :
else echo "Error: input file $inputfile is not in the correct format" >&2
  exit 1
fi
}

rexist_local_output(){
local_output=`pwd`/$(basename $inputfile).list
if test -f $local_output; then echo "" > $local_output; else touch $local_output; fi
}

rsize
rfile
rformat
rexist_local_output
}
checkers

function main(){
echo $(date +"%T.%3N") "Sorting now..."
function sub_prep() {
tmp_uuid=$(uuidgen)
	cat ${inputfile} | awk -F " " '{print $2}' | sed 's/[.:]//g' | uniq > /tmp/$tmp_uuid

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

average=$(( sum / count )) #определяем среднее значение

prev=${array[0]}  #перебираем массив для определения отличных значений
for value in "${array[@]}"; do
	diff=$(( 10#$value - 10#$prev )) #определяем разницу
	if (( diff > average*2 )); then #eсли разница больше средней дельты, вывести значение


prep_tail(){
  if (( diff > 999 )); then
	subtract_tail_prev=$(( 1000 - 10#$(echo $prev | cut -c 7-10))) ; # определяем пороговую разницу для предыдущего значения +
	subtract_tail_value=$(echo 10#${value} | cut -c 8-10) ;
	sum_tails=$(( ${subtract_tail_prev#0} + ${subtract_tail_value#0} )) ;
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
	echo "Strange value found: $formatted_string_value (previous value: <$formatted_string_prev> | difference: <$diff>)" >> ${local_output};
fi

fi
	prev=$value
	
done

result=$(cat "$local_output" | grep "difference" | wc -l)

if [ "$result" -gt 1 ]; then
    echo "diff found ($result)"
    elif [ "$result" -gt 50 ]; then
        echo "Result is greater than 50"
else
    echo "normal"
fi


if [ "$result" -gt 1 ]; then 
	echo "$(date +"%T.%3N") Difference value found ($result) - collecting to <$local_output>";
	    elif [ "$result" -gt 50 ]; then
			echo "Difference value found ($result) - probably we have unstable connection between sides"
	else echo "Probably we have normally consistent or empty log: <$local_output> is empty";
	end_time=$(date +%s)
	elapsed_time=$(( $end_time - $start_time ))
	echo $(date +"%T.%3N") "Elapsed time: $elapsed_time seconds"
	exit 1
fi

echo $(date +"%T.%3N") "Extracting uniq differences:"
function short_summ(){
	differences=$(grep -o 'difference: <.*>' $local_output | awk -F '<' '{print $2}' | awk -F '>' '{print $1}')
IFS=$'\n' unique_differences=($(echo "$differences" | sort -u))
unset IFS
for i in "${unique_differences[@]}"; do
    full_line=$(grep -o -m1 ".*difference: <$i>.*" $local_output)
	strange_value_time=$(echo "$full_line" | awk '{print $4}')
	print_msg=$(cat $inputfile | grep $strange_value_time | head -n 1)
    echo "
	$full_line	
	$print_msg
	"
done
}
short_summ
}

main

end_time=$(date +%s)
elapsed_time=$(( $end_time - $start_time ))
if [[ "$elapsed_time" -lt 1 ]]; then
    echo "Elapsed time: less than 1 sec"
	else
echo $(date +"%T.%3N") "Elapsed time: $elapsed_time seconds"
fi
