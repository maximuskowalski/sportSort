#!/usr/bin/env bash
# tool to create empty files for sorting and testing
# create files from list

# ./filemaker.sh file_list.txt

if [ $# -eq 0 ]; then
    echo "No input file specified"
    exit 1
fi

input_file=$1

while read filename; do
    touch "$filename"
done <"$input_file"
