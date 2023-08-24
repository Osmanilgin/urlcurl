#!/bin/bash

# Default values
threads=1
custom_headers=""
delay=0
output_dir="url_responses"

# Function to display script usage
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h                          Display this help message"
    echo "  -t NUM       Specify the number of threads for parallel processing (default: 1)"
    echo "  -H HEADER            Add a custom header to the HTTP requests"
    echo "  -d delay                 Specify the delay between requests in seconds"
    echo "  -o DIRECTORY        Specify the output directory name (default: url_responses)"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h)
            show_help
            ;;
        -threads)
            threads="$2"
            shift
            shift
            ;;
        -H)
            custom_headers+="$2 "
            shift
            shift
            ;;
        -d)
            delay="$2"
            shift
            shift
            ;;
        -o)
            output_dir="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done

# Create the output directory
mkdir -p "$output_dir"

# Define a function to process a URL
process_url() {
    url="$1"
    url_dir="$output_dir/$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')"
    mkdir -p "$url_dir"

    headers=$(curl -s -L -I $custom_headers "$url")
    body=$(curl -s -L $custom_headers "$url")

    echo "$headers" > "$url_dir/headers.txt"
    echo "$body" > "$url_dir/body.txt"

    echo "Response saved for: $url"
}

# Process URLs in parallel
count=0
while IFS= read -r url; do
    ((count++))
    process_url "$url" &
    if [[ $count -ge $threads ]]; then
        wait
        count=0
    fi
    sleep "$delay"
done

# Wait for any remaining background processes to finish
wait

echo "Done"
