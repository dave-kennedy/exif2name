#!/bin/bash

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
        echo "$file skipped - unknown extension"
        let skip_count++
        continue
    fi

    exif_dto="$(exif -mt DateTimeOriginal "$file" 2>/dev/null)"
    exif_dt="$(exif -mt DateTime "$file" 2>/dev/null)"
    last_mod="$(stat -c %y "$file")"
    last_mod="${last_mod%\.*}"

    echo
    echo "$file"
    echo "1) DateTimeOriginal: $exif_dto"
    echo "2) DateTime: $exif_dt"
    echo "3) Last modified: $last_mod"
    echo "4) Skip"

    ans=
    datetime=
    while true; do
        read -p "Select a value: " ans
        case "$ans" in
            1) datetime="$exif_dto"; break;;
            2) datetime="$exif_dt"; break;;
            3) datetime="$last_mod"; break;;
            4) break;;
        esac
    done

    if [ -z "$datetime" ]; then
        echo "$file skipped"
        let skip_count++
        continue
    fi

    datetime="${datetime//:/-}"
    datetime="${datetime// /_}"
    newfile="$cwd/$datetime.$ext"

    if [ "$file" = "$newfile" ]; then
        echo "$file skipped - name already correct"
        let skip_count++
        continue
    fi

    # BUG: this doesn't work in dry run if more than one file would have its
    # named changed to the same thing
    n=0
    while [ -f "$newfile" ]; do
        let n++
        newfile="$cwd/$datetime"_"$n.$ext"
    done

    if [ "$dry_run" = false ]; then
        mv "$file" "$newfile"
        echo "$file renamed to $newfile"
        let rename_count++
    else
        echo "$file would be renamed to $newfile"
        let rename_count++
    fi
done

echo

if [ "$dry_run" = false ]; then
    echo "$rename_count files renamed, $skip_count files skipped"
else
    echo "$rename_count files would be renamed, $skip_count files would be \
skipped"
fi
