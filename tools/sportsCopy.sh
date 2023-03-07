#!/usr/bin/env bash
# This is the original script kept only for origin purposes.

# Set  source and destination directories
src_dir="/mnt/local/downloads/nzbget/completed/TV_Sport"
dst_dir="/mnt/unionfs/Media/tv/Sport"

# Create dictionary to map sport types to desired names
declare -A sport_name_map
sport_name_map=(["epl"]="English Premier League" ["la.liga"]="Spanish La Liga" ["nba"]="NBA" ["nfl"]="NFL" ["nhl"]="NHL" ["mlb"]="MLB")

create_year_directory() {
  local sport_type="$1"
  local year_directory="2022-2023"
  mkdir -p "$dst_dir/${sport_name_map[$sport_type]}/$year_directory"
}

move_and_rename() {
  local sport_type="$1"

  local src_dir_pattern="*${sport_type}*"

  # Make sure destination exists
  if [ ! -d "$dst_dir/${sport_name_map[$sport_type]}" ]; then
    mkdir -p "$dst_dir/${sport_name_map[$sport_type]}"
    create_year_directory "$sport_type"
  fi

  # Find all files in source dir that match pattern and are at least 2 mins old
  files=$(find "$src_dir" -type f -iname "$src_dir_pattern*.mkv")
  for file in $files; do
    if [ $(find "$file" -mmin +2) ]; then
      # Extract base file name without the path
      base_file=$(basename "$file")
      # Replace the first part of file name and format the date
      new_base_file="$(echo $base_file | sed "s/sportsnet-${sport_type}/${sport_name_map[$sport_type]^^}/g" | sed 's/\([0-9]\{4\}\)\.\([0-9]\{2\}\)\.\([0-9]\{2\}\)/\1-\2-\3/' | sed 's/\.1080p\.web\.h264//' | sed 's/\.720p\.web\.h264//')"
      # Move file to destination dir with the new name
      mv -n "$file" "$dst_dir/${sport_name_map[$sport_type]}/2022-2023/$new_base_file"
      echo "Moved $file to $dst_dir/${sport_name_map[$sport_type]}/2022-2023/$new_base_file"
    fi
  done
}

cleanup() {
  # Remove any .nfo files within the source directory
  find "$src_dir" -name "*.nfo" -delete
  # Remove any empty directories within the source directory
  find "$src_dir" -type d -empty -delete
}

move_and_rename "nba"
move_and_rename "nfl"
move_and_rename "nhl"
move_and_rename "mlb"
move_and_rename "epl"
move_and_rename "la.liga"
cleanup
