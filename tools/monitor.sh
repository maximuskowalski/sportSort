#!/usr/bin/env bash
# this is a small utility I used to grab file names for testing purposes
# it just runs in the background

# Set the source and destination directories
src_dir="/mnt/local/downloads/nzbget/completed/TV_Sport"
dst_dir="/home/$USER/logs"

# Check if the log file exists and create it if it doesn't
if [ ! -f $dst_dir/sportscopyNames.log ]; then
    touch $dst_dir/sportscopyNames.log
fi

# Monitor the source directory recursively
while true; do
    inotifywait -m -r -e create -e moved_to $src_dir |
        while read file; do
            if [[ "$file" == *.mkv ]]; then
                echo "$file" >>$dst_dir/sportscopyNames.log
                echo "File found: $file"
            fi
        done
done
