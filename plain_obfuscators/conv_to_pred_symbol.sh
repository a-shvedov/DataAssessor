#!/bin/bash
#convert to predefined character (x/X, for example)

start_time=$(date +%s)
if [[ -z "$1" ]]; then echo "Err: set target file"; exit 1; else file=$1 ; fi
if [[ "$1" == *.sh ]]; then echo "War: you trying prepare .sh file - check target or comment this checker"; exit 1; fi
echo "Started at `date`"
while read -r line; do
  for ((i=0; i<${#line}; i++)); do
    if [[ ${line:$i:1} =~ [A-Z] ]]; then
      printf "X"
    elif [[ ${line:$i:1} =~ [a-z] ]]; then
      printf "x"
    else
      printf "${line:$i:1}"
    fi
  done
  printf "\n"
done < "$1" > conv_$(basename ${1}) 

end_time=$(date +%s)
duration=$(( $end_time - $start_time ))
echo "Elapsed time: ${duration}sec"
