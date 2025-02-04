#!/bin/bash

# Usage function for help
usage() {
    echo "Usage: $0 -l <input_file> -o <output_folder> [-p <port>]"
    exit 1
}

# Parse command-line arguments
port=""
while getopts "l:o:p:h" opt; do
    case ${opt} in
        l) input_file=${OPTARG} ;;
        o) output_folder=${OPTARG} ;;
        p) port=${OPTARG} ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$input_file" || -z "$output_folder" ]]; then
    usage
fi

# Ensure the output folder exists
mkdir -p "$output_folder"

# Function to fetch headers and body, following redirects
fetch_and_save() {
    local ip=$1
    local output_folder=$2
    local port=$3

    # Append port to IP if specified
    if [[ -n "$port" ]]; then
        ip="$ip:$port"
    fi

    # Fetch headers and body using curl with redirect following (-L)
    headers_file="$output_folder/${ip//[:]/_}_headers.txt"
    body_file="$output_folder/${ip//[:]/_}_body.txt"

    curl -s -L -D - "$ip" -o "$body_file" > "$headers_file" 2>/dev/null

    # Separate headers and status line
    sed -i -n "/^HTTP/{p; :a; n; /\r$/p; ta}" "$headers_file"

    echo "Fetched $ip with redirects followed"
}

# Read IP list and process each IP
while IFS= read -r ip; do
    [[ -z "$ip" ]] && continue
    fetch_and_save "$ip" "$output_folder" "$port" &
done < "$input_file"

# Wait for all background jobs to finish
wait

echo "Completed fetching headers and bodies with redirects followed."
