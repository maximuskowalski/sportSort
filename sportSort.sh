#!/usr/bin/env bash
# https://github.com/maximuskowalski/sportSort/blob/main/sportSort.sh

# enable during debug and dev
# possible set as a config var
# set -x

set -Eeuo pipefail

IFS=$'\n\t'

#________ STUFF TO DO STILL

### TODO need to add handling for torrents since they will be seeding still
### setup log rotation?
### notification on a manual fix req'd
### clean comments
### clean functions
### add file name collector - DONE - in sort and move function
### change logfile name
### years or seasons
### draw a workings picture
### RENAME FUNCTIONS BETTERER

#________ VARS ( NOW IN CONFIG FILE )

# shellcheck source=/dev/null
source "$(dirname "$0")/sportSort.conf"

#________ PREDEFINED DICTIONARIES AND ARRAYS

# An array containing the names of various sports leagues, used for identifying the type of each file.
# These names are not case-sensitive and may include spaces or periods.
# Note: "NHL.RS" is included as a separate item to match files with a specific naming convention - it may be possible to remove this as date fix functions improve. May be able to use "liga" as term to cover all Spanish La Liga variations.
the_sport_types=("nba" "nfl" "NHL.RS" "nhl" "mlb" "epl" "Spanish.La.Liga" "Spanish La Liga" "la.liga" "La.Liga" "la liga" "Premier.League")

# Dictionary to map sport types to desired names
declare -A sport_name_map=(["epl"]="English Premier League" ["Premier.League"]="English Premier League" ["Premier League"]="English Premier League" ["Spanish La Liga"]="Spanish La Liga" ["la.liga"]="Spanish La Liga" ["La.Liga"]="Spanish La Liga" ["la liga"]="Spanish La Liga" ["Spanish.La.Liga"]="Spanish La Liga" ["nba"]="NBA" ["nfl"]="NFL" ["nhl"]="NHL" ["NHL.RS"]="NHL" ["mlb"]="MLB")

# Dictionary to map NHL team codes to desired names
# CHC is not real but appears in some files
declare -A nhl_team_names_map=(["ANA"]="Anaheim Ducks" ["ARI"]="Arizona Coyotes" ["BOS"]="Boston Bruins" ["BUF"]="Buffalo Sabres" ["CGY"]="Calgary Flames" ["CAR"]="Carolina Hurricanes" ["CHC"]="Carolina Hurricanes" ["CHI"]="Chicago Blackhawks" ["COL"]="Colorado Avalanche" ["CBJ"]="Columbus Blue Jackets" ["DAL"]="Dallas Stars" ["DET"]="Detroit Red Wings" ["EDM"]="Edmonton Oilers" ["FLA"]="Florida Panthers" ["LAK"]="Los Angeles Kings" ["MIN"]="Minnesota Wild" ["MTL"]="Montreal Canadiens" ["NSH"]="Nashville Predators" ["NJD"]="New Jersey Devils" ["NYI"]="New York Islanders" ["NYR"]="New York Rangers" ["OTT"]="Ottawa Senators" ["PHI"]="Philadelphia Flyers" ["PIT"]="Pittsburgh Penguins" ["SJS"]="San Jose Sharks" ["SEA"]="Seattle Kraken" ["STL"]="St. Louis Blues" ["TBL"]="Tampa Bay Lightning" ["TOR"]="Toronto Maple Leafs" ["VAN"]="Vancouver Canucks" ["VGK"]="Vegas Golden Knights" ["WSH"]="Washington Capitals" ["WPG"]="Winnipeg Jets")

###########################
#________ FUNCTIONS
###########################

#________ set up functions to create dirs if not exist

run_setup() {

    # check if script user is root and exit in case of dirty rooter
    if [ "$(id -u)" = 0 ]; then
        echo "Running as root or with sudo is not supported. Exiting."
        exit 1
    fi

    # check if $src_dir and $dst_dir exist exit in case of laziness
    if [ ! -d "$src_dir" ] || [ ! -d "$dst_dir" ]; then
        echo "Error: $src_dir or $dst_dir does not exist"
        exit 1
    fi

    # make sure the logs directory exists
    if [ ! -d "$log_file_dir" ]; then
        mkdir -p "$log_file_dir"
    fi

    # create log files if they don't exist
    [ ! -e "$log_file_dir"/sportSort.log ] && touch "$log_file_dir"/sportSort.log
    [ ! -e "$log_file_dir"/sportSort_filename.log ] && touch "$log_file_dir"/sportSort_filename.log

    # create directories for each sport type
    for sport_type in "${the_sport_types[@]}"; do
        create_year_directory "$sport_type"
        create_manual_year_directory "$sport_type"
    done

}

create_year_directory() {

    local sport_type="$1"
    local year_directory="2022-2023"
    # local year_directory="${current_year}"
    # TODO this will need revising to accommodate other seasons

    # Make sure the destination directory exists
    if [ ! -d "$dst_dir/${sport_name_map[$sport_type]}" ]; then
        mkdir -p "$dst_dir/${sport_name_map[$sport_type]}"
        # need to add check for year once it becomes fluid
        mkdir -p "$dst_dir/${sport_name_map[$sport_type]}/$year_directory"
    fi
}

create_manual_year_directory() {

    local sport_type="$1"
    local year_directory="2022-2023"
    # local year_directory="${current_year}"
    # TODO this will need revising to accommodate other seasons

    # Make sure the destination directory exists
    if [ ! -d "$man_dst_dir/${sport_name_map[$sport_type]}" ]; then
        mkdir -p "$man_dst_dir/${sport_name_map[$sport_type]}"
        # need to add check for year once it becomes fluid
        mkdir -p "$man_dst_dir/${sport_name_map[$sport_type]}/$year_directory"
    fi
}

#________ brain sort decision functions

send_to_sort() {

    # iterate over the sport types
    for sport_type in "${the_sport_types[@]}"; do
        sort_and_move_files "$sport_type"
    done
}

sort_and_move_files() {

    local sport_type="$1"
    local src_dir_pattern="*${sport_type}*"

    # Extract the base file name without the path
    base_file=$(basename "$file")

    echo "sorting_sport_type: $sport_type"

    # shellcheck disable=SC2154
    # use mapfile to assign the output of find to an array - file must be at least 1min old
    mapfile -t files < <(find "$src_dir" -type f -iname "$src_dir_pattern*.mkv" -mmin +1)

    for file in "${files[@]}"; do
        echo "filename: $base_file"
        # use basename to gather names only here
        echo "$base_file" >>"$log_file_dir"/sportSort_filename.log

        if [[ $file =~ S[0-9]{2}E[0-9]{2} ]]; then
            echo "episode_format send: $file" >>"$log_file_dir"/sportSort.log
            episode_format "$file"

        elif [[ $file =~ .*[nN][hH][lL].*[rR][sS].*2023.* ]]; then
            echo "dirtydate send: $file" >>"$log_file_dir"/sportSort.log
            move_nhlrs_dirty_date_files "$file"

        elif [[ $file =~ [nN][hH][lL]-2023-.*@.* ]]; then
            echo "threeletter send: $file" >>"$log_file_dir"/sportSort.log
            rename_nhl_threeletter_files "$file"

        elif [[ ! $file =~ [vV][sS] ]]; then
            echo "no Vs - episode_format send: $file" >>"$log_file_dir"/sportSort.log
            episode_format "$file"

        elif [[ $file =~ [lL][iI][gG][aA] ]]; then
            echo "eslaliga send: $file" >>"$log_file_dir"/sportSort.log
            es_la_liga_problemo_rename "$file"
        else
            echo "mnr send: $file" >>"$log_file_dir"/sportSort.log
            move_and_other_files "$file"
        fi
    done
}

#________ sorter functions

episode_format() {

    # lets strip the stuff we dont want and then pass to a manual intervention directory
    # we could do this for all files that don't pass some test as well and this lets the
    # script be more usable immediately while trying to fix issues.
    # if we outsource the actual move function to it's own thing it could be included in that
    local file="$1"

    local mnof_sporttype=$sport_type
    echo "$mnof_sporttype" >>"$log_file_dir"/sportSort.log

    echo "sport_type is: $sport_type" >>"$log_file_dir"/sportSort.log
    echo "desired name is: ${sport_name_map[$sport_type]}" >>"$log_file_dir"/sportSort.log

    # Extract the base file name without the path
    base_file=$(basename "$file")

    echo "episode_format base_file name: $base_file" >>"$log_file_dir"/sportSort.log

    # strip spaces and ..'s uppercase the sport type
    new_base_file="$(echo "$base_file" |
        sed -e "s/${mnof_sporttype}/${sport_name_map[$sport_type]^^}/Ig" \
            -e 's/ /./g' \
            -e 's/\.\././g')"

    echo "stripped new_base_file name: $new_base_file" >>"$log_file_dir"/sportSort.log

    # Remove unwanted strings from the file name
    clean_base_file="$(remove_strings "$new_base_file")"

    echo "episode remove_strings clean_base_file name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    # Call fix_date to fix the date string in the filename
    # should be no date on these but if it is there we should clean and keep
    # now using this function to strip other invalid files, perhaps rename
    clean_base_file=$(fix_date "$clean_base_file")

    echo "episode fix_date clean_base_file name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    # redo space cleaning and .. in case we get some
    clean_base_file="$(echo "$clean_base_file" |
        sed -e 's/ /./g' \
            -e 's/\.\././g')"

    echo "episode final clean_base_file name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    if [[ "$clean_base_file" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} && "$clean_base_file" =~ (v|V)(s|S) ]]; then
        # check file name has valid date format YYYY-MM-DD and contains "vs"
        file_mover "$file" "$clean_base_file" "${sport_name_map[$sport_type]}"
    else
        # otherwise, move file to the manual intervention dir with new name
        manual_fix "$file" "$clean_base_file" "${sport_name_map[$sport_type]}"
    fi

}

rename_nhl_threeletter_files() {

    local file="$1"

    # Log the NHL team names map
    echo "${nhl_team_names_map[@]}"

    # Extract the base file name without the path
    base_file=$(basename "${file}")

    # Remove unwanted strings from the file name
    new_base_file="$(remove_strings "${base_file}")"
    echo "nhl_threeletter: ${file} was renamed with remove strings as ${new_base_file}" >>"$log_file_dir"/sportSort.log

    # Extract team codes from the file name
    mapfile -t teams < <(basename ${new_base_file} | grep -o '^NHL-[0-9-]\+_\([A-Z]\{3\}\)@[A-Z]\{3\}' | sed -E 's/.*_([A-Z]{3})@([A-Z]{3}).*/\1\n\2/')

    # Log the teams array
    echo "nhl_threeletter: teams ${teams[0]} ${teams[1]}" >>"$log_file_dir"/sportSort.log
    if [ ${#teams[@]} -ne 2 ]; then
        echo "nhl_threeletter: Error: bad number of teams in file name" >>"$log_file_dir"/sportSort.log
        mv "$file" "$man_dst_dir/${sport_name_map[$sport_type]}/2022-2023/$new_base_file"
        return
    fi

    # Use dictionary to look up full team names
    home_team="${nhl_team_names_map[${teams[0]}]}"
    away_team="${nhl_team_names_map[${teams[1]}]}"
    echo "threeletter teams: home_team: $home_team away_team: $away_team " >>"$log_file_dir"/sportSort.log

    # Log the teams array
    echo "${teams[@]}" >>"$log_file_dir"/sportSort.log
    echo "team codes: ${teams[@]}" >>"$log_file_dir"/sportSort.log

    # Create new file name
    new_file="NHL.$(basename "${new_base_file}" | grep -o '^NHL-[0-9-]\+' | sed 's/NHL-//').$(echo "${home_team}" | tr ' ' '.').vs.$(echo "${away_team}" | tr ' ' '.').mkv"

    # Rename and move file
    # TODO use filemover functions.
    mv "${file}" "$dst_dir/${sport_name_map[$sport_type]}/2022-2023/${new_file}"
    echo "3 letter rename: ${file} was sent to ${sport_name_map[$sport_type]} as ${new_file}" >>"$log_file_dir"/sportSort.log

}

move_nhlrs_dirty_date_files() {

    local file="$1"

    # Extract the base file name without the path
    base_file=$(basename "${file}")

    # Remove unwanted strings from the file name
    new_base_file="$(remove_strings "${base_file}")"
    echo "dirty date files: ${file} was renamed with remove strings as ${new_base_file}" >>"$log_file_dir"/sportSort.log

    # Call fix_date_nhl_rs to fix the date string in the filename
    fixed_base_file="$(fix_date_nhl_rs "${new_base_file}")"
    if [[ "$fixed_base_file" != "$new_base_file" ]]; then
        echo "dirty date files: ${new_base_file} was renamed with fix_date_nhl_rs as ${fixed_base_file}" >>"$log_file_dir"/sportSort.log
    fi

    # Make sure no double ..'s and no " "'s
    clean_base_file="$(echo "$fixed_base_file" |
        sed -e 's/ /./g' \
            -e 's/\.\././g')"

    # Move file to the destination dir with new name
    # TODO use filemover functions.
    if [ -f "$dst_dir/${sport_name_map[$sport_type]}/2022-2023/$clean_base_file" ]; then
        rm "$file"
    else
        mv -n "$file" "$dst_dir/${sport_name_map[$sport_type]}/2022-2023/$clean_base_file"
    fi
    echo "Moved $file to $dst_dir/${sport_name_map[$sport_type]}/2022-2023/$clean_base_file" >>"$log_file_dir"/sportSort.log

}

es_la_liga_problemo_rename() {

    local file="$1"

    echo "This file is being passed through es_la_liga_problemo_rename" >>"$log_file_dir"/sportSort.log

    # Extract the base file name without the path
    base_file=$(basename "$file")

    # Log the name of the original file.
    echo "laligaProblemo base_file name: $base_file" >>"$log_file_dir"/sportSort.log

    # Replace "La Liga" with "SPANISH.LA.LIGA" in the file name.
    # Remove spaces and consecutive dots.
    new_base_file="$(echo "$base_file" |
        sed -e 's/\b\(Spanish\.La\.Liga\|La\.Liga\|La\s*Liga\|la\.liga\)\b/SPANISH.LA.LIGA/gI' \
            -e 's/ /./g' \
            -e 's/\.\././g')"

    # Log the new base file name.
    echo "laligaProblemo new_base_file name: $new_base_file" >>"$log_file_dir"/sportSort.log

    # Remove unwanted strings from the file name
    clean_base_file="$(remove_strings "$new_base_file")"
    # Log the file name with unwanted strings removed.
    echo "laligaProblemo strings name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    # Check if the file name matches the pattern for dates as "MM-DD-YYYY".
    # If it does, send it to the "usa_dateriser" function to fix the date format.
    if [[ "$clean_base_file" =~ ([0-9]{1,2})[-.]([0-9]{1,2})[-.]([0-9]{4}) ]]; then
        echo "laligaProblemo file sent to usa_dateriser" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(usa_dateriser "$clean_base_file")

    # Check if the file name matches a pattern where the year appears in the middle of the file name with no MM-DD
    # If it does, send it to the "fix_split_date" function to fix the date format.
    elif [[ "$clean_base_file" =~ ^([^0-9]*[^0-9]{4})([0-9]{4})(.*)\.[^\.]+$ && ! "${BASH_REMATCH[1]}" =~ [0-9]{4}\.$ ]]; then
        echo "laligaProblemo file sent to fix_split_date" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(fix_split_date "$clean_base_file")

    # Check if the file name matches the pattern for consecutive year string "YYYY.YYYY".
    # If it does, send it to the "fix_consecutive_year" function to fix the date format.
    elif [[ "$clean_base_file" =~ ([0-9]{4})\.([0-9]{4}) ]]; then
        echo "laligaProblemo file sent to fix_consecutive_year" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(fix_consecutive_year "$clean_base_file")

    # If the file name doesn't match any of the above patterns, assume that the date is in "DD-MM-YYYY", "DD.MM.YYYY", or "DD MM YYYY" format.
    # Send it to the "fix_date" function to fix the date format.
    else
        echo "laligaProblemo file sent to fix_date" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(fix_date "$clean_base_file")

    fi

    # Log the file name after the date fixing function has been applied.
    echo "laligaProblemo after date fixing function  name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    # move file to the destination dir with new name ( add check for vs? )
    if [[ "$clean_base_file" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        # checks if file name has valid date format YYYY-MM-DD
        file_mover "$file" "$clean_base_file" "${sport_name_map[$sport_type]}"
    else
        # move file to the manual intervention dir with new name
        manual_fix "$file" "$clean_base_file" "${sport_name_map[$sport_type]}"
    fi

}

move_and_other_files() {

    local file="$1"

    # Set mv and other files_sporttype to the current sport_type
    local mnof_sporttype=$sport_type

    # Log the current sport_type
    echo "sport_type is: $sport_type" >>"$log_file_dir"/sportSort.log

    # Log the desired directory name based on the sport_type
    echo "desired name is: ${sport_name_map[$sport_type]}" >>"$log_file_dir"/sportSort.log

    # Extract the base file name without the path
    base_file=$(basename "$file")

    # Log the base file name
    echo "move_and_other_files new_base_file before: $base_file" >>"$log_file_dir"/sportSort.log

    # Replace the sport type portion of the file name with the desired dictionary name
    new_base_file="$(echo "$base_file" |
        sed -e "s/${mnof_sporttype}/${sport_name_map[$sport_type]^^}/Ig" \
            -e 's/ /./g' \
            -e 's/\.\././g')"

    # Remove unwanted strings from the file name
    clean_base_file="$(remove_strings "$new_base_file")"
    echo "move_and_other_files remove_strings name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    # Check if the file name matches the pattern for dates as "MM-DD-YYYY".
    # If it does, send it to the "usa_dateriser" function to fix the date format.
    if [[ "$clean_base_file" =~ ([0-9]{1,2})[-.]([0-9]{1,2})[-.]([0-9]{4}) ]]; then
        echo "move_n_other file sent to usa_dateriser" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(usa_dateriser "$clean_base_file")

    # Check if the file name matches a pattern where the year appears in the middle of the file name with no MM-DD
    # If it does, send it to the "fix_split_date" function to fix the date format.
    elif [[ "$clean_base_file" =~ ^([^0-9]*[^0-9]{4})([0-9]{4})(.*)\.[^\.]+$ && ! "${BASH_REMATCH[1]}" =~ [0-9]{4}\.$ ]]; then
        echo "move_n_other file sent to fix_split_date" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(fix_split_date "$clean_base_file")

    # If the file name doesn't match any of the above patterns, assume that the date is in "DD-MM-YYYY", "DD.MM.YYYY", or "DD MM YYYY" format.
    # Send it to the "fix_date" function to fix the date format.
    else
        echo "move_n_other file sent to fix_date" >>"$log_file_dir"/sportSort.log
        clean_base_file=$(fix_date "$clean_base_file")

    fi

    # Log the file name after the date fixing function has been applied.
    echo "move_and_other_files fix date name: $clean_base_file" >>"$log_file_dir"/sportSort.log

    # Call the file_mover function to move the file to the desired directory with the cleaned up name
    file_mover "$file" "$clean_base_file" "${sport_name_map[$sport_type]}"
}

#________ mover functions

manual_fix() {

    echo "THIS FILE HANDLED BY manual_fix" >>"$log_file_dir"/sportSort.log
    local file="$1"
    echo "manual_fix -  file: $file" >>"$log_file_dir"/sportSort.log
    local clean_name="$2"
    echo "manual_fix -  clean_name: $clean_name" >>"$log_file_dir"/sportSort.log
    local sporttype="$3"
    echo "sporttype -  sporttype: $sporttype" >>"$log_file_dir"/sportSort.log

    # Move file to the destination dir with new name
    if [ -f "$man_dst_dir/${sporttype}/2022-2023/$clean_name" ]; then
        rm "$file"
    else
        mv -n "$file" "$man_dst_dir/${sporttype}/2022-2023/$clean_name"
        msg="Moved $file to $man_dst_dir/$sporttype/2022-2023/$clean_name"
        echo "$msg" >>"$log_file_dir"/sportSort.log
        echo "send to notification: $msg" >>"$log_file_dir"/sportSort.log
        send_notification "$msg"
    fi

}

file_mover() {

    echo "THIS FILE HANDLED BY file_mover" >>"$log_file_dir"/sportSort.log
    local file="$1"
    echo "filemover -  file: $file" >>"$log_file_dir"/sportSort.log
    local clean_name="$2"
    echo "filemover -  clean_name: $clean_name" >>"$log_file_dir"/sportSort.log
    local sporttype="$3"
    echo "sporttype -  sporttype: $sporttype" >>"$log_file_dir"/sportSort.log

    # Move file to the destination dir with new name
    if [ -f "$dst_dir/${sporttype}/2022-2023/$clean_name" ]; then
        rm "$file"
    else
        mv -n "$file" "$dst_dir/${sporttype}/2022-2023/$clean_name"
    fi
    echo "Moved $file to ""$dst_dir"/"${sporttype}"/2022-2023/"$clean_name""" >>"$log_file_dir"/sportSort.log

}

#________ string and date repair functions

remove_strings() {

    local file="$1"

    new_file="$(echo "$file" |
        sed -e 's/720p.HDTV.x264-Sweet-Star//g' \
            -e 's/720p.web.h264//g' \
            -e 's/720pEN30fps//g' \
            -e 's/720pEN60fps//g' \
            -e 's/HZ2.German.720p.HDTV.x264-DoGG//g' \
            -e 's/HZ1.German.720p.HDTV.x264-DoGG//g' \
            -e 's/720p.AHDTV.x264-PLUTONiUM//g' \
            -e 's/sportsnet-//' \
            -e 's/ RS /. /g' \
            -e 's/\.RS\./\./g' \
            -e 's/\.divisional\.round\./. /g' \
            -e 's/Tailgate.Takedown//g' \
            -e 's/720p60_EN_T.3//g' \
            -e 's/720p60_EN_BSSW//g' \
            -e 's/720p60_EN_\(MSG\|BSMW\|ATT-PT\|ATTSN-PT\|ESPN\|TSN.2\|TSN 2\|BSDET\|NBCS-CH\|NBCS-CA\|SN\|BSSC\|NESN\|TSN.3\|ATT-RM\)//g' \
            -e 's/\.720p\.WEB-DL\.AAC20\.H264-StatiQ//g' \
            -e 's/720p\.Home\.Feed\.GC\.WEBRip\.AAC2\.0\.H\.264-BTW//g' \
            -e 's/1080p.WEB.h264-CBFM//g' \
            -e 's/1080p.web.h264//g' \
            -e 's/1080i.HDTV.MPA2.0.H.264-playTV//g' \
            -e 's/\([0-9]\{4\}\)\.\([0-9]\{2\}\)\.\([0-9]\{2\}\)/\1-\2-\3/' \
            -e 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)\./\1./' \
            -e 's/El.Clasico//g' \
            -e 's/ATTSN-PT//g' \
            -e 's/NBCSCH//g' \
            -e 's/.MSG//g' \
            -e 's/.TNT//g' \
            -e 's/.BS//g' \
            -e 's/.TN//g' \
            -e 's/.TSN2//g' \
            -e 's/.SNE//g' \
            -e 's/.ATT//g' \
            -e 's/.NBCSC//g' \
            -e 's/.RootS//g' \
            -e 's/.SN//g' \
            -e 's/\-\-/_/g' \
            -e 's/ /./g' \
            -e 's/\.\.\././g' \
            -e 's/\.\././g' \
            -e 's/\.\././g')"

    echo "$new_file"

}

fix_date() {

    local filename="$1"
    # matches "DD-MM-YYYY", "DD.MM.YYYY", or "DD MM YYYY":
    local regex='([0-9]{1,2})[. _-]([0-9]{1,2})[. _-]([0-9]{4})'
    local sport_regex='(NHL|ENGLISH.PREMIER.LEAGUE|SPANISH.LA.LIGA|NBA|NFL|MLB)'

    if [[ "$filename" =~ $regex ]]; then
        day="${BASH_REMATCH[1]}"
        month="${BASH_REMATCH[2]}"
        year="${BASH_REMATCH[3]}"

        # Construct the new date format
        new_date="${year}-${month}-${day}"

        # Extract the sport type from the filename
        if [[ "$filename" =~ $sport_regex ]]; then
            sport_type="${BASH_REMATCH[1]}"
        fi

        # Extract the match details from the filename
        match="${filename%.*}"
        match="${match##*.}"
        match="${match//vs./vs}"

        # Construct the new file name with the updated date format
        new_filename="${sport_type}.${new_date}.${match}.mkv"

        echo "$new_filename"
    else
        echo "$filename"
    fi
}

fix_split_date() {

    local filename="$1"

    local basename
    basename=$(basename "$filename" .mkv)
    echo "fix_split_date basename: ${basename}" >>"$log_file_dir"/sportSort.log
    local extension="${filename##*.}"
    echo "fix_split_date extension: ${extension}" >>"$log_file_dir"/sportSort.log

    # Extract day and month codes
    local day_month
    day_month=$(echo "$basename" | grep -oE '[0-9]{2}\.[0-9]{2}$')
    echo "fix_split_date day_month: ${day_month}" >>"$log_file_dir"/sportSort.log

    if [[ -z "$day_month" ]]; then
        echo "$filename" # Return original filename if day and month codes not found
        echo "fix_split_date: Returned original filename, day and month codes not found." >>"$log_file_dir"/sportSort.log
        return
    fi

    local day_code="${day_month%%.*}"
    echo "fix_split_date day_code: ${day_code}" >>"$log_file_dir"/sportSort.log
    local month_code="${day_month##*.}"
    echo "fix_split_date month_code: ${month_code}" >>"$log_file_dir"/sportSort.log

    # Extract year in format yyyy
    local year
    year=$(echo "$basename" | grep -oE '\b[0-9]{4}\b')
    echo "fix_split_date year: ${year}" >>"$log_file_dir"/sportSort.log

    # Replace yyyy and dd.mm with yyyy-mm-dd
    local new_basename
    new_basename=$(echo "$basename" | sed "s/\b${year}\b/${year}-${month_code}-${day_code}/" | rev | cut -d "." -f 3- | rev)
    echo "fix_split_date new_basename: ${new_basename}" >>"$log_file_dir"/sportSort.log

    echo "${new_basename}.${extension}"
}

fix_date_nhl_rs() {

    local filename="$1"

    local basename
    basename=$(basename "$filename" .mkv)
    echo "fix_date basename: ${basename}" >>"$log_file_dir"/sportSort.log
    local extension="${filename##*.}"
    echo "fix_date extension: ${extension}" >>"$log_file_dir"/sportSort.log

    # Extract day and month codes
    local day_month
    day_month=$(echo "$basename" | grep -oE '[0-9]{2}\.[0-9]{2}$')
    echo "fix_date day_month: ${day_month}" >>"$log_file_dir"/sportSort.log

    if [[ -z "$day_month" ]]; then
        echo "$filename" # Return original filename if day and month codes not found
        echo "fix_date: Returned original filename, day and month codes not found." >>"$log_file_dir"/sportSort.log
        return
    fi

    local day_code="${day_month%%.*}"
    echo "fix_date day_code: ${day_code}" >>"$log_file_dir"/sportSort.log
    local month_code="${day_month##*.}"
    echo "fix_date month_code: ${month_code}" >>"$log_file_dir"/sportSort.log

    # Extract year in format yyyy
    local year
    year=$(echo "$basename" | grep -oE '\b[0-9]{4}\b')
    echo "fix_date year: ${year}" >>"$log_file_dir"/sportSort.log

    # Replace yyyy and dd.mm with yyyy-mm-dd
    local new_basename
    new_basename=$(echo "$basename" | sed "s/\b${year}\b/${year}-${month_code}-${day_code}/" | rev | cut -d "." -f 3- | rev)
    echo "fix_date new_basename: ${new_basename}" >>"$log_file_dir"/sportSort.log

    echo "${new_basename}.${extension}"
}

usa_dateriser() {

    local filename="$1"
    local sport_type_regex="(NHL|ENGLISH\.PREMIER\.LEAGUE|SPANISH\.LA\.LIGA|NBA|NFL|MLB)"
    local sport_type=""
    local date_regex='([0-9]{4}).([0-9]{1,2}).([0-9]{1,2})'
    local date_str=""
    local match_info=""

    # Extract the sport type from the filename
    if [[ "$filename" =~ $sport_type_regex ]]; then
        sport_type="${BASH_REMATCH[1]}"
    fi

    # Log the extracted sport type
    echo "Sport Type = $sport_type" >>"$log_file_dir"/sportSort.log

    # Now extract the date and set it as a variable. Then format it correctly as yyyy-mm-dd

    # Extract the date string from the file name using regex
    if [[ "$filename" =~ ([0-9]{1,2})[-\.]([0-9]{1,2})[-\.]([0-9]{4}) ]]; then
        date_str="${BASH_REMATCH[0]}"
        year="${BASH_REMATCH[3]}"
        month="${BASH_REMATCH[2]}"
        day="${BASH_REMATCH[1]}"

        # Construct the new date format
        new_date="${year}-${month}-${day}"
        echo "New date = $new_date" >>"$log_file_dir"/sportSort.log
    fi

    # Log the extracted date string
    echo "Date string = $date_str" >>"$log_file_dir"/sportSort.log

    # Extract the match info from the filename
    match_info=$(echo "$filename" | sed -E "s/^$sport_type\.//; s/\.$date_str\.mkv$//")
    echo "Match info = $match_info" >>"$log_file_dir"/sportSort.log

    # Construct the new file name with the updated date format
    new_filename="${sport_type}.${new_date}.${match_info}.mkv"

    echo "usa_dateriser: new base file name: $new_filename" >>"$log_file_dir"/sportSort.log

    echo "$new_filename"

}

fix_consecutive_year() {

    local filename="$1"
    local new_filename
    new_filename="$(echo "$filename" | sed -E 's/([0-9]{4})\.([0-9]{4})/\1-\2/g')"
    echo "$new_filename"
}

#________ notifications

send_notification() {
    local msg="$1"
    # check value of "${webhook_url}", if it is "discord://12345678901234567890/abcdefghijklmnopqrstuvwxyz" then the notification should not be sent and this function exited.
    if [ "${webhook_url}" = "discord://12345678901234567890/abcdefghijklmnopqrstuvwxyz" ]; then
        echo "Notification not sent as webhook URL is invalid: ${webhook_url}" >>"$log_file_dir"/sportSort.log
        return 0
    else
        echo "Notification sent: $msg" >>"$log_file_dir"/sportSort.log
        apprise "${webhook_url}" --title "sportSort" --body "${msg}"
        return $?
    fi

}

#________ clean up after each run

cleanup() {

    # Remove any .nfo files within the source directory
    find "$src_dir" -name "*.nfo" -delete
    # Remove any empty directories within the source directory
    find "$src_dir" -mindepth 1 -type d -empty -delete
}

#________ dev only function

log_clean() {

    echo "NewRun" >"$log_file_dir"/sportSort.log
}

#________ set list

run_setup
# log_clean # enable for testing only
send_to_sort
cleanup
