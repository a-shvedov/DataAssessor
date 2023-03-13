#!/bin/bash

dir_to_sort="./dir_to_sort"
dir_to_out="./dir_to_out"

glob(){
extensions=($(find "$dir_to_sort" -type f | awk -F '.' '{print $NF}' | sort -u))

for ext in "${extensions[@]}"; do
  mkdir -p ${dir_to_out}/${ext}
  echo ${dir_to_out}/${ext}
  find "$dir_to_sort" -type f -name "*.${ext}" | while read filename; do
    base=$(basename "$filename" ".$ext")
    new_name="${base}-${EPOCHSECONDS}.${ext}"
    echo $new_name
    cp "$filename" "${dir_to_out}/${ext}/${new_name}"
done
done
}

head(){
for file in ${dir_to_sort}/*; do
    if [ -f "$file" ]; then
        filetype=$(file -b "$file" | awk '{print $1}')
        mkdir -p ${dir_to_out}/${filetype}
        mv "$file" ${dir_to_out}/${filetype}/
    else echo "fl not found: $file"; fi
done
}

#glob
#head
