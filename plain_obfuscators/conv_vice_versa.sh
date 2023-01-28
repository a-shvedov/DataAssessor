#!/bin/bash
#reverses each word and writes the reversed words to a new file

start_time=$(date +%s)
if [[ -z "$1" ]]; then echo "Err: set target file"; exit 1; else file=$1 ; fi
if [[ "$1" == *.sh ]]; then echo "War: you trying prepare <*.sh> file - check target or comment this checker"; exit 1; fi
echo "Started at `date`"

while read -r line; do
  for word in ${line}; do
    rev_word=""
    for ((i=${#word}-1; i>=0; i--)); do
      rev_word+=${word:$i:1}
    done
    printf "${rev_word} "
  done
  printf "\n"
done < "$1" > conv_$(basename ${1})

end_time=$(date +%s)
duration=$(( ${end_time} - ${start_time} ))
echo "Elapsed time: ${duration}sec"
