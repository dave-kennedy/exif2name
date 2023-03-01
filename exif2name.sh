#!/usr/bin/env bash

if ! command -v exif > /dev/null 2>&1; then
    echo "Error: exif is not installed"
    exit 1
fi

usage="Usage: ${0##*/} [--dry-run | -n] [directory]"

if [ "$1" = --help -o "$1" = -h ]; then
    echo "$usage"
    exit 0
fi

if [ "$1" = --dry-run -o "$1" = -n ]; then
    dry_run=true
    shift
else
    dry_run=false
fi

if [ -z "$1" ]; then
    cwd=.
elif [ -d "$1" ]; then
    cwd="${1%/}"
    shift
else
    echo "Error: $1 is not a directory"
    exit 1
fi

if [ -n "$1" ]; then
    echo "$usage"
    exit 0
fi

rename_count=0
skip_count=0

for file in "$cwd"/*; do
    if [ -d "$file" ]; then
        echo "$file skipped because it is a directory"
        let skip_count++
        continue
    fi

    ext="${file##*\.}"

    if [ "${ext,,}" != jpg -a "${ext,,}" != jpeg ]; then
        echo "$file skipped because it is not a JPG or JPEG file"
        let skip_count++
        continue
    fi

    exif_date_time_orig="$(exif --no-fixup -mt DateTimeOriginal "$file" 2>/dev/null)"
    exif_date_time="$(exif --no-fixup -mt DateTime "$file" 2>/dev/null)"
    created_date_time="$(stat -c %w "$file")"
    created_date_time="${created_date_time%\.*}"
    modified_date_time="$(stat -c %y "$file")"
    modified_date_time="${modified_date_time%\.*}"
    selected_option=
    selected_date_time=

    echo
    echo "$file"
    echo "0) Skip"
    echo "1) EXIF data and time (original): $exif_date_time_orig"
    echo "2) EXIF date and time: $exif_date_time"
    echo "3) File created: $created_date_time"
    echo "4) File last modified: $modified_date_time"
    echo "5) Enter manually"

    while ! [ "$selected_option" -ge 0 -a "$selected_option" -le 5 ] 2>/dev/null; do
        read -p "Select an option (0-5): " selected_option
    done

    if [ "$selected_option" -eq 0 ]; then
        echo "$file skipped by user"
        let skip_count++
        continue
    fi

    if [ "$selected_option" -eq 1 ]; then
        selected_date_time="$exif_date_time_orig"
    elif [ "$selected_option" -eq 2 ]; then
        selected_date_time="$exif_date_time"
    elif [ "$selected_option" -eq 3 ]; then
        selected_date_time="$created_date_time"
    elif [ "$selected_option" -eq 4 ]; then
        selected_date_time="$modified_date_time"
    elif [ "$selected_option" -eq 5 ]; then
        while true; do
            read -p "Enter date and time (%Y-%m-%d %M:%H:%S): " selected_date_time

            case "$selected_date_time" in
                [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\ [0-2][0-9]:[0-5][0-9]:[0-5][0-9])
                    break;;
            esac
        done
    fi

    formatted_date_time="${selected_date_time//:/-}"
    formatted_date_time="${formatted_date_time// /_}"
    new_file="$cwd/$formatted_date_time.$ext"

    if [ "$file" = "$new_file" ]; then
        echo "$file skipped because its name is already correct"
        let skip_count++
        continue
    fi

    # BUG: this doesn't work in dry run if more than one file would have its
    # named changed to the same thing
    n=0

    while [ -f "$new_file" ]; do
        let n++
        new_file="$cwd/$formatted_date_time"_"$n.$ext"
    done

    if [ "$dry_run" = false ]; then
        mv "$file" "$new_file"
        echo "$file renamed to $new_file"
        let rename_count++
    else
        echo "$file would be renamed to $new_file"
        let rename_count++
    fi
done

echo

if [ "$dry_run" = false ]; then
    echo "$rename_count files renamed, $skip_count files skipped"
else
    echo "$rename_count files would be renamed, $skip_count files would be skipped"
fi

