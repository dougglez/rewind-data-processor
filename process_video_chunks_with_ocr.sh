#!/bin/bash

# process_video_chunks_with_ocr.sh
#
# Enhanced video chunk processor that includes OCR text extraction
# This script processes Rewind video chunks, converting them to MP4 files
# and extracting any text found in the screenshots using Apple's Vision framework
#
# Features:
# - All features from process_video_chunks.sh
# - OCR text extraction from each video frame
# - Creates searchable text files alongside MP4s
# - Builds index for future semantic search
#
# Requirements: ffmpeg/ffprobe, Apple OCR tools

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Source Apple Vision helpers if available
if [ -f "$SCRIPT_DIR/apple_vision_helpers.sh" ]; then
    source "$SCRIPT_DIR/apple_vision_helpers.sh"
fi

# Configuration from config.sh
CHUNKS_SOURCE="$REWIND_CHUNKS_DIR"
CHUNKS_COPY="$CHUNKS_TEST_DIR"
OUTPUT_DIR="$VIDEO_OUTPUT_DIR"
OCR_DIR="$OCR_OUTPUT_DIR"
LOG_FILE="$VIDEO_LOG_FILE"
DATE_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters
total_files=0
processed_files=0
ocr_extracted_files=0
error_count=0
skipped_files=0

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$OCR_DIR"

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

    # Check OCR availability
    if [ "$ENABLE_OCR" = "true" ]; then
        if command -v check_ocr_available &> /dev/null; then
            if check_ocr_available >/dev/null 2>&1; then
                log "OCR capabilities available"
            else
                log "WARNING: OCR enabled but no OCR tools available"
                log "Run './compile_apple_tools.sh' or './create_ocr_shortcut.sh' first"
            fi
        else
            log "WARNING: OCR helpers not loaded"
        fi
    fi

    log "Dependencies check completed."
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

# Extract text from a video chunk using OCR
extract_text_from_chunk() {
    local chunk_file="$1"
    local output_text_file="$2"

    if [ "$ENABLE_OCR" != "true" ]; then
        return 1
    fi

    # Create a temporary frame from the video
    local temp_frame="/tmp/chunk_frame_$$.png"

    # Extract a frame from the middle of the video (to avoid black frames)
    if ffmpeg -i "$chunk_file" -vf "select=eq(n\,1)" -vframes 1 "$temp_frame" -y &>/dev/null; then

        # Use Apple OCR if available
        if command -v apple_ocr &> /dev/null; then
            local extracted_text
            extracted_text=$(apple_ocr "$temp_frame" 2>/dev/null)

            if [ -n "$extracted_text" ] && [ "$extracted_text" != "No text found in image" ]; then
                echo "$extracted_text" > "$output_text_file"
                log "OCR extracted $(echo "$extracted_text" | wc -l) lines of text"

                # Clean up temp frame
                rm -f "$temp_frame"
                return 0
            fi
        fi

        # Clean up temp frame
        rm -f "$temp_frame"
    fi

    return 1
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

# Process a single chunk file with OCR
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

    if [ "$duration" = "0" ] || [ -z "$duration" ]; then
        handle_error "Could not get duration for: $relative_path"
        rm -f "$temp_file"
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
    local text_filename="${start_formatted}_to_${end_formatted}.txt"

    # Create date-based directory structure
    local date_dir
    date_dir=$(date -r "$start_timestamp" "+%Y-%m-%d")
    local output_dir="$OUTPUT_DIR/$date_dir"
    local ocr_dir="$OCR_DIR/$date_dir"

    mkdir -p "$output_dir"
    mkdir -p "$ocr_dir"

    local output_path="$output_dir/$output_filename"
    local text_path="$ocr_dir/$text_filename"

    # Copy video file with new name and .mp4 extension
    if cp "$temp_file" "$output_path"; then
        # Preserve original timestamps
        touch -r "$chunk_file" "$output_path"
        log "Created: $date_dir/$output_filename"
        ((processed_files++))

        # Extract text using OCR
        if extract_text_from_chunk "$temp_file" "$text_path"; then
            log "OCR: $date_dir/$text_filename"
            ((ocr_extracted_files++))
        else
            # Create empty text file to indicate OCR was attempted
            touch "$text_path"
            echo "# No text detected" > "$text_path"
        fi

        # Clean up temp file
        rm -f "$temp_file"
        return 0
    else
        handle_error "Failed to copy: $relative_path"
        rm -f "$temp_file"
        return 1
    fi
}

# Find and process all chunk files
process_all_chunks() {
    log "Discovering chunk files..."

    # Ensure output directories exist
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OCR_DIR"

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

# Create search index from OCR text
create_search_index() {
    if [ "$ENABLE_OCR" != "true" ] || [ $ocr_extracted_files -eq 0 ]; then
        return 0
    fi

    log "Creating search index from OCR text..."

    # Create search index directory
    mkdir -p "$SEARCHABLE_INDEX_DIR"

    # Create a simple text index (future: use SQLite FTS)
    local index_file="$SEARCHABLE_INDEX_DIR/text_index.txt"

    # Find all OCR text files and create an index
    find "$OCR_DIR" -name "*.txt" -type f | while read -r text_file; do
        local relative_path="${text_file#$OCR_DIR/}"
        local video_file="${text_file%.txt}.mp4"

        if [ -s "$text_file" ]; then  # Only if file has content
            echo "=== $relative_path ===" >> "$index_file"
            cat "$text_file" >> "$index_file"
            echo "" >> "$index_file"
        fi
    done

    if [ -f "$index_file" ]; then
        log "Search index created: $index_file"
    fi
}

# Print summary
print_summary() {
    log ""
    log "=== PROCESSING SUMMARY ==="
    log "Total files found: $total_files"
    log "Successfully processed: $processed_files"
    log "OCR text extracted: $ocr_extracted_files"
    log "Skipped/Error files: $skipped_files"
    log "Total errors: $error_count"
    log "Video output: $OUTPUT_DIR"
    log "OCR text output: $OCR_DIR"
    log ""

    if [ $processed_files -gt 0 ]; then
        log "Sample output structure:"
        find "$OUTPUT_DIR" -name "*.mp4" | head -3 | while read -r file; do
            log "  - $(basename "$(dirname "$file")")/$(basename "$file")"
        done
    fi

    if [ $ocr_extracted_files -gt 0 ]; then
        log ""
        log "Sample OCR files:"
        find "$OCR_DIR" -name "*.txt" -size +1c | head -3 | while read -r file; do
            log "  - $(basename "$(dirname "$file")")/$(basename "$file")"
        done
    fi

    if [ $error_count -gt 0 ]; then
        log "⚠️  Processing completed with $error_count errors. Check log for details."
    else
        log "✅ Processing completed successfully!"
    fi

    if [ "$ENABLE_OCR" = "true" ]; then
        log ""
        log "🔍 OCR Features:"
        log "- Text extracted from video screenshots"
        log "- Searchable text files created alongside MP4s"
        log "- Future: Full-text search and semantic indexing"
    fi
}

# Main execution
main() {
    log "Starting enhanced video chunk processing with OCR..."
    log "Source: $CHUNKS_SOURCE"
    log "Test copy: $CHUNKS_COPY"
    log "Video output: $OUTPUT_DIR"
    log "OCR output: $OCR_DIR"
    log "OCR enabled: $ENABLE_OCR"
    log ""

    check_dependencies
    copy_chunks_for_testing
    process_all_chunks
    create_search_index
    print_summary

    exit $error_count
}

# Run main function
main "$@"