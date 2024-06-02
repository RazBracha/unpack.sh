#!/bin/bash

unpack_file() {
    local file="$1"
    local verbose="$2"
    
    file_type=$(file "$file")

    # Get compression method
    if [[ $file_type == *gzip* ]]; then
        decomp_method="gunzip -f" # -f To overwrite file
    elif [[ $file_type == *bzip2* ]]; then
        decomp_method="bunzip2 -fq" # q To redirect unzip output to /dev/null
    elif [[ $file_type == *Zip* ]]; then
        decomp_method="unzip -oq"  # o to overwrite
    elif [[ $file_type == *compress* ]]; then
        decomp_method="uncompress -f"
    else
        # File is not compressed
        if [ "$verbose" = true ]; then
            echo "Ignoring $(basename "$file")"
        fi
        return 1
    fi

    # Exectute unpacking
    if $decomp_method "$file"; then
        if [ "$verbose" = true ]; then
            echo "Unpacking $(basename "$file")"
        fi
        num_files_decomp=$((num_files_decomp + 1))
        return 0
    else
        echo "Failed to decompress $file"
        return 1
    fi
}

unpack_directory() {
    local directory="$1"
    local verbose="$2"

    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            if ! unpack_file "$file" "$verbose"; then
                num_files_not_decomp=$((num_files_not_decomp + 1))
            fi
        elif [ -d "$file" ] && [ "$recursive" = true ]; then
                unpack_directory "$file" "$verbose"; 
        fi
    done
}

recursive=false
verbose=false

num_files_decomp=0
num_files_not_decomp=0

# Get Option
while getopts "rv" opt; do
    case $opt in
        r) recursive=true ;;
        v) verbose=true ;;
        *) echo "Usage: $0 [-r] [-v] file [file...]" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# Check if any files were provided
if [ "$#" -eq 0 ]; then
    echo "No files provided"
    exit 1
fi

# Unpack files
for file in "$@"; do
    file_name=$(basename "$file")  # Extract the file name (without directory)
    if [ -f "$file" ]; then
        if [ "$recursive" = true ]; then
            echo "Error: -r option can only be used with directories."
            exit 1
        fi
        if ! unpack_file "$file" "$verbose"; then
            num_files_not_decomp=$((num_files_not_decomp + 1))
        fi
    elif [ -d "$file" ]; then
        unpack_directory "$file" "$verbose"; 
    else
        echo "File or directory '$file_name' not found"
    fi
done

echo "Decompressed $num_files_decomp archive(s)"
exit "$num_files_not_decomp"