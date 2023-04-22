#!/bin/bash
set -e

start_time=$(date +%s)

desc='
Определение временных отклонений, попавших в логи форматного файла;

Основные возвращаемые значения:
1.1 корректный файл лога <+delta_analyse_draft -i test_it2_test.log>:
"""
FLBACKUP=on - backuping input file
Selecting all stings
17:43:50.992 Sorting now...
diff found (3)
17:43:50.999 Difference value found (3) - collecting to </home/user/Desktop/example_xac.log.list>
17:43:50.999 Extracting uniq differences:

	Strange value found: 13:51:13.874 (previous value: <13:51:13.642> | difference: <232>)	
	10/01/23 13:51:13.874 xxxxx_xxxx.XXX <--- Xxxxx xxxx xxxxx() x1(78033873) - x2(78033641) = xx_xxxxx(232). xxxxxx xxxxxxxx xxxxxxxxxx_xxxxxx (120500)xx
	

	Strange value found: 13:51:13.640 (previous value: <13:51:13.258> | difference: <382>)	
	10/01/23 13:51:13.640 xxxxx_xxxx.XXX <--- Xxxxx xxxx xxxxx() x1(78033639) - x2(78033257) = xx_xxxxx(382). xxxxxx xxxxxxxx xxxxxxxxxx_xxxxxx (120500)xx
	

	Strange value found: 13:51:13.140 (previous value: <13:51:12.702> | difference: <438>)	
	10/01/23 13:51:13.140 xxxxx_xxxx.XXX <--- Xxxxx xxxx xxxxx() x1(78033139) - x2(78032701) = xx_xxxxx(438). xxxxxx xxxxxxxx xxxxxxxxxx_xxxxxx (120500)xx
	
PATTERN_MODE=off
Average: <77>

"""
1.2 корректный файл лога <+delta_analyse_draft -i test_plugin_2030.log.6 -p> с параметром "-p":
"""
Run with <-p> - write pattern string:Awake
call:<PATTERN_MODE>
15:21:42.002 Sorting now...
15:21:42.289 Elapsed time: 6 seconds
15:21:42.289 Extracting uniq differences:

	Strange value found: 18:31:09.583 (previous value: <18:31:09.469> | difference: <114>)	
	 06/04/23 18:31:09.583 test.WAR <--- Awake () t1(184043775) - t2(184043774) = poll(1)(1500)ms
	
Search pattern:<Awake>
Average: <21>
Summary message type:<.WAR>

15:21:42.488 Elapsed time: 6 seconds
"""
2. неформатный файл <+delta_analyse_draft -i test.log.4.list>:
	Error: input file </home/../test.log.4.list> have no correct timestamp format
	
3. отсутсвующий файл: <+delta_analyse_draft -i test.log.4.liss>:
	Error: input file test.log.4.liss not exist
	
4. пустой файл: <+delta_analyse_draft -i test.log.4.lis>:
	Error: input file test.log.4.lis is empty
	
5. отсутствие ключа: <./delta_analyse_exp.sh test.log.4.list>
	Error: use -i flag to targeting file before running the script
'

#user_opts:
FLBACKUP='y' #бэкап входного файла вклчючен по умолчанию - полезно для сохранинии исходного лога (например, после воздействия ф-ции debug_plugin_prepairng)
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
				else echo "Not found <message_dispatch_period> params in default locations"
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
else echo "Set up pattern before using this script or suppress <PATTERN_MODE> - exit" ;
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
#	else 
	echo "value is "$formatted_string_value
#	if [[ ! $formatted_string_value =~ ^[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,3}\.[0-9]$ ]]; then : #есть ложноположительные срабатывания, внести измения, чтобы не зависеть от результата возврата $result="007"
	else #007
	echo "Probably we have normally consistent log: <$local_output>";
	end_time=$(date +%s)
	elapsed_time=$(( $end_time - $start_time ))
	echo $(date +"%T.%3N") "Elapsed time: $elapsed_time seconds"
fi
#fi #007

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


main #вызов основного блока ф-ций

#далее доп.блок - ф-ции на будущее
short_stat(){
if [ "$PATTERN_MODE" == "y" ]; then printf "Search pattern:"; printf "<${PATTERN_MODE_string}>" | grep "[[:alnum:]]" --colour=always; else echo "PATTERN_MODE=off"; fi
echo "Average: <${average}>" | grep "[[:digit:]]" --colour=always
dbg_type=$(cat "$inputfile" | grep -E -o ".[A-Z]{3}" | grep -E -o ".TRC||.DBG||.INF||.WAR||.ERR" | sort -u | grep ".[[:alnum:]]" --colour=always)
if [[ $dbg_type =~ ^(\.TRC\.|DBG\.|\.INF\.|\.WAR\.|\.ERR\.)$ ]]; 
then :
else printf "Summary message type:"; printf "<$dbg_type>\n\n"
fi
}

short_stat
if [ "$FLBACKUP" == "y" ]; then echo 'FLBACKUP=on - reverting input file' 
	if [[ -f "${previous_inputfile}.deltabak" ]]; then mv "${previous_inputfile}.deltabak" "$previous_inputfile";
	else mv "${previous_inputfile}.deltabak" "$inputfile"; fi; fi

end_time=$(date +%s)
elapsed_time=$(( $end_time - $start_time ))
if [[ "$elapsed_time" -lt 1 ]]; then
    echo "Elapsed time: less than 1 sec"
	else
echo $(date +"%T.%3N") "Elapsed time: $elapsed_time seconds"
fi
