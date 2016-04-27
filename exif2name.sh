#!/bin/bash

if ! command -v exif > /dev/null 2>&1; then
    echo "Error: exif is not installed"
    exit 1
fi

usage="Usage: ${0##*/} [--dry-run] DIRECTORY"

if [ "$1" = --help ]; then
    echo "$usage"
    exit 0
fi

dry_run=false

if [ "$1" = --dry-run ]; then
    dry_run=true
    shift
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
        continue
    fi

    answer=
    ext="${file##*\.}"

    if [ "${ext,,}" != jpg -a "${ext,,}" != jpeg ]; then
        echo "$file skipped - unknown extension"
        let skip_count++
        continue
    fi

    if datetime="$(exif --debug --machine-readable --tag=DateTimeOriginal "$file" 2>&1)"; then
        datetime="${datetime##*$'\n'}"
    else
        datetime="$(stat --format=%y "$file")"
        datetime="${datetime%\.*}"

        echo "Warning: $file does not contain tag DateTimeOriginal"
        echo "Last modified date is $datetime - use it instead?"

        option1="Use last modified date"
        option2="Skip file"

        select answer in "$option1" "$option2"; do
            case "$answer" in
                "$option1"|"$option2")
                    break
                    ;;
            esac
        done

        if [ "$answer" = "$option2" ]; then
            echo "$file skipped - not using last modified date"
            let skip_count++
            continue
        fi
    fi

    datetime="${datetime//:/-}"
    datetime="${datetime// /_}"
    newfile="$cwd/$datetime.$ext"
    n=1

    # BUG: this doesn't work in dry run if more than one file would have its named changed
    # to the same thing
    while [ -f "$newfile" ]; do
        if [ "$file" = "$newfile" ]; then
            break
        fi

        newfile="$cwd/$datetime"_"$n.$ext"
        let n++
    done

    if [ "$file" = "$newfile" ]; then
        echo "$file skipped - name already correct"
        let skip_count++
        continue
    fi

    if [ "$dry_run" = false ]; then
        mv "$file" "$newfile"
    fi

    echo "$file renamed to $newfile"
    let rename_count++
done

echo
echo "$rename_count files renamed, $skip_count files skipped"
