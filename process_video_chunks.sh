#!/bin/bash

# process_video_chunks.sh
#
# This script processes Rewind video chunks, converting them from the internal
# format to individual MP4 files with human-readable timestamps.
#
# Features:
# - Copies chunks to desktop for safe testing
# - Preserves original metadata and timestamps
# - Renames files with start_time_to_end_time format
# - Processes each chunk individually (not combined like export.js)
# - Creates organized directory structure by date
#
# Requirements: ffmpeg/ffprobe must be installed

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Configuration from config.sh
CHUNKS_SOURCE="$REWIND_CHUNKS_DIR"
CHUNKS_COPY="$CHUNKS_TEST_DIR"
OUTPUT_DIR="$VIDEO_OUTPUT_DIR"
LOG_FILE="$VIDEO_LOG_FILE"
DATE_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters
total_files=0
processed_files=0
error_count=0
skipped_files=0

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[$DATE_FORMAT] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    ((error_count++))
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."

    if ! command -v ffprobe &> /dev/null; then
        handle_error "ffprobe not found. Please install ffmpeg."
        exit 1
    fi

    if ! command -v rsync &> /dev/null; then
        handle_error "rsync not found. Please install rsync."
        exit 1
    fi

    log "Dependencies check passed."
}

# Copy chunks directory to desktop for testing
copy_chunks_for_testing() {
    log "Copying chunks directory to desktop for testing..."

    if [ ! -d "$CHUNKS_SOURCE" ]; then
        handle_error "Source chunks directory '$CHUNKS_SOURCE' not found."
        exit 1
    fi

    # Remove existing copy if it exists
    if [ -d "$CHUNKS_COPY" ]; then
        log "Removing existing chunks copy..."
        rm -rf "$CHUNKS_COPY"
    fi

    # Copy with metadata preservation
    log "Copying chunks to: $CHUNKS_COPY"
    if rsync -a --exclude=".DS_Store" "$CHUNKS_SOURCE/" "$CHUNKS_COPY/"; then
        log "Successfully copied chunks directory"
    else
        handle_error "Failed to copy chunks directory"
        exit 1
    fi
}

# Get video duration using ffprobe
get_video_duration() {
    local file="$1"

    # Get duration in seconds
    ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "0"
}

# Get file creation time as timestamp
get_file_timestamp() {
    local file="$1"

    # Get creation time (or modification time as fallback)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use stat to get birth time
        stat -f "%B" "$file" 2>/dev/null || stat -f "%m" "$file"
    else
        # Linux - use modification time
        stat -c "%Y" "$file"
    fi
}

# Format timestamp for filename (YYYY-MM-DD_HH-MM-SS)
format_timestamp_for_filename() {
    local timestamp="$1"
    date -r "$timestamp" "+%Y-%m-%d_%H-%M-%S"
}

# Process a single chunk file
process_chunk_file() {
    local chunk_file="$1"
    local relative_path="$2"

    log "Processing: $relative_path"

    # Get file creation timestamp
    local start_timestamp
    start_timestamp=$(get_file_timestamp "$chunk_file")

    if [ "$start_timestamp" = "0" ] || [ -z "$start_timestamp" ]; then
        handle_error "Could not get timestamp for: $relative_path"
        return 1
    fi

    # Add .mp4 extension temporarily for ffprobe
    local temp_file="${chunk_file}.mp4"
    cp "$chunk_file" "$temp_file"

    # Get video duration
    local duration
    duration=$(get_video_duration "$temp_file")

    # Clean up temp file
    rm -f "$temp_file"

    if [ "$duration" = "0" ] || [ -z "$duration" ]; then
        handle_error "Could not get duration for: $relative_path"
        return 1
    fi

    # Calculate end timestamp
    local end_timestamp
    end_timestamp=$((start_timestamp + ${duration%.*}))  # Remove decimal part

    # Format timestamps for filename
    local start_formatted
    local end_formatted
    start_formatted=$(format_timestamp_for_filename "$start_timestamp")
    end_formatted=$(format_timestamp_for_filename "$end_timestamp")

    # Create output filename
    local output_filename="${start_formatted}_to_${end_formatted}.mp4"

    # Create date-based directory structure
    local date_dir
    date_dir=$(date -r "$start_timestamp" "+%Y-%m-%d")
    local output_dir="$OUTPUT_DIR/$date_dir"
    mkdir -p "$output_dir"

    local output_path="$output_dir/$output_filename"

    # Copy file with new name and .mp4 extension
    if cp "$chunk_file" "$output_path"; then
        # Preserve original timestamps
        touch -r "$chunk_file" "$output_path"
        log "Created: $date_dir/$output_filename"
        ((processed_files++))
        return 0
    else
        handle_error "Failed to copy: $relative_path"
        return 1
    fi
}

# Find and process all chunk files
process_all_chunks() {
    log "Discovering chunk files..."

    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR"

    # Find all files in chunks directory (excluding .DS_Store)
    local chunk_files=()
    while IFS= read -r -d '' file; do
        if [[ "$(basename "$file")" != ".DS_Store" ]] && [ -f "$file" ]; then
            chunk_files+=("$file")
        fi
    done < <(find "$CHUNKS_COPY" -type f -print0)

    total_files=${#chunk_files[@]}
    log "Found $total_files chunk files to process"

    # Process each file
    local count=0
    for chunk_file in "${chunk_files[@]}"; do
        ((count++))
        local relative_path="${chunk_file#$CHUNKS_COPY/}"

        log "Progress: $count/$total_files - Processing: $relative_path"

        if ! process_chunk_file "$chunk_file" "$relative_path"; then
            ((skipped_files++))
        fi
    done
}

# Print summary
print_summary() {
    log ""
    log "=== PROCESSING SUMMARY ==="
    log "Total files found: $total_files"
    log "Successfully processed: $processed_files"
    log "Skipped/Error files: $skipped_files"
    log "Total errors: $error_count"
    log "Output directory: $OUTPUT_DIR"
    log ""

    if [ $processed_files -gt 0 ]; then
        log "Sample output structure:"
        find "$OUTPUT_DIR" -name "*.mp4" | head -5 | while read -r file; do
            log "  - $(basename "$(dirname "$file")")/$(basename "$file")"
        done
    fi

    if [ $error_count -gt 0 ]; then
        log "⚠️  Processing completed with $error_count errors. Check log for details."
    else
        log "✅ Processing completed successfully!"
    fi
}

# Main execution
main() {
    log "Starting video chunk processing..."
    log "Source: $CHUNKS_SOURCE"
    log "Test copy: $CHUNKS_COPY"
    log "Output: $OUTPUT_DIR"
    log ""

    check_dependencies
    copy_chunks_for_testing
    process_all_chunks
    print_summary

    exit $error_count
}

# Run main function
main "$@"