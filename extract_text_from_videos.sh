#!/bin/bash

# extract_text_from_videos.sh
#
# Step 3 of video processing pipeline: Extract text using OCR
#
# This script processes organized video files (from meetings and screenshots
# directories) and extracts text using Apple's Vision framework.
#
# Features:
# - Processes both meeting recordings and screenshots
# - Extracts text from video frames using Apple OCR
# - Creates searchable text files with timestamp metadata
# - Builds searchable index for future semantic search
#
# Prerequisites: copy_video_chunks.sh and detect_meetings.sh must be run first

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
MEETINGS_DIR="$VIDEO_MEETINGS_DIR"
SCREENSHOTS_DIR="$VIDEO_SCREENSHOTS_DIR"
OCR_DIR="$OCR_OUTPUT_DIR"
LOG_FILE="$VIDEO_LOG_FILE"
DATE_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters
total_videos=0
processed_videos=0
ocr_extracted_videos=0
error_count=0
skipped_videos=0

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

# Check dependencies and prerequisites
check_dependencies() {
    log "Checking dependencies and prerequisites..."

    if ! command -v ffmpeg &> /dev/null; then
        handle_error "ffmpeg not found. Please install ffmpeg."
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

    # Check if input directories exist
    if [ ! -d "$MEETINGS_DIR" ] && [ ! -d "$SCREENSHOTS_DIR" ]; then
        handle_error "No input directories found. Please run previous pipeline steps first:"
        log "1. ./copy_video_chunks.sh"
        log "2. ./detect_meetings.sh"
        exit 1
    fi

    log "Dependencies check completed."
}

# Extract text from a video file using OCR
extract_text_from_video() {
    local video_file="$1"
    local output_text_file="$2"

    if [ "$ENABLE_OCR" != "true" ]; then
        return 1
    fi

    # Create a temporary frame from the video
    local temp_frame="/tmp/video_frame_$$.png"

    # Extract a frame from the middle of the video (to avoid black frames)
    if ffmpeg -i "$video_file" -vf "select=eq(n\,1)" -vframes 1 "$temp_frame" -y &>/dev/null; then

        # Use Apple OCR if available
        if command -v apple_ocr &> /dev/null; then
            local extracted_text
            extracted_text=$(apple_ocr "$temp_frame" 2>/dev/null)

            if [ -n "$extracted_text" ] && [ "$extracted_text" != "No text found in image" ]; then
                # Create text file with metadata
                {
                    echo "# OCR Text Extraction"
                    echo "# Video: $(basename "$video_file")"
                    echo "# Extracted: $(date)"
                    echo "# Method: Apple Vision Framework"
                    echo ""
                    echo "$extracted_text"
                } > "$output_text_file"

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

# Process a single video file
process_video_file() {
    local video_file="$1"
    local video_type="$2"  # "meeting" or "screenshot"
    local relative_path="$3"

    log "Processing $video_type: $relative_path"

    # Create output filename (replace .mp4 with .txt)
    local filename=$(basename "$video_file" .mp4)
    local date_dir=$(dirname "$relative_path")

    # Create OCR output directory structure
    local ocr_type_dir="$OCR_DIR/$video_type"
    local ocr_output_dir="$ocr_type_dir/$date_dir"
    mkdir -p "$ocr_output_dir"

    local text_file="$ocr_output_dir/${filename}.txt"

    ((processed_videos++))

    # Extract text using OCR
    if extract_text_from_video "$video_file" "$text_file"; then
        log "OCR: $video_type/$date_dir/${filename}.txt"
        ((ocr_extracted_videos++))
    else
        # Create empty text file to indicate OCR was attempted
        {
            echo "# OCR Text Extraction"
            echo "# Video: $(basename "$video_file")"
            echo "# Extracted: $(date)"
            echo "# Result: No text detected"
        } > "$text_file"
        log "No text detected in: $relative_path"
    fi
}

# Process videos in a directory
process_video_directory() {
    local input_dir="$1"
    local video_type="$2"

    if [ ! -d "$input_dir" ]; then
        log "Directory not found: $input_dir (skipping $video_type videos)"
        return 0
    fi

    log "Processing $video_type videos from: $input_dir"

    # Find all video files
    local video_files=()
    while IFS= read -r -d '' file; do
        if [[ "$file" == *.mp4 ]]; then
            video_files+=("$file")
        fi
    done < <(find "$input_dir" -name "*.mp4" -type f -print0)

    local dir_video_count=${#video_files[@]}
    log "Found $dir_video_count $video_type videos"

    # Process each video
    for video_file in "${video_files[@]}"; do
        local relative_path="${video_file#$input_dir/}"

        if ! process_video_file "$video_file" "$video_type" "$relative_path"; then
            ((skipped_videos++))
        fi
    done

    return $dir_video_count
}

# Create search index from OCR text
create_search_index() {
    if [ "$ENABLE_OCR" != "true" ] || [ $ocr_extracted_videos -eq 0 ]; then
        return 0
    fi

    log "Creating search index from OCR text..."

    # Create search index directory
    mkdir -p "$SEARCHABLE_INDEX_DIR"

    # Create separate indexes for meetings and screenshots
    local meeting_index="$SEARCHABLE_INDEX_DIR/meetings_text_index.txt"
    local screenshot_index="$SEARCHABLE_INDEX_DIR/screenshots_text_index.txt"
    local combined_index="$SEARCHABLE_INDEX_DIR/all_text_index.txt"

    # Clear existing indexes
    > "$meeting_index"
    > "$screenshot_index"
    > "$combined_index"

    # Index meeting videos
    if [ -d "$OCR_DIR/meeting" ]; then
        echo "=== MEETING RECORDINGS TEXT INDEX ===" >> "$meeting_index"
        echo "Generated: $(date)" >> "$meeting_index"
        echo "" >> "$meeting_index"

        find "$OCR_DIR/meeting" -name "*.txt" -type f | while read -r text_file; do
            local relative_path="${text_file#$OCR_DIR/meeting/}"

            if [ -s "$text_file" ]; then  # Only if file has content
                echo "=== MEETING: $relative_path ===" >> "$meeting_index"
                cat "$text_file" >> "$meeting_index"
                echo "" >> "$meeting_index"

                # Also add to combined index
                echo "=== MEETING: $relative_path ===" >> "$combined_index"
                cat "$text_file" >> "$combined_index"
                echo "" >> "$combined_index"
            fi
        done
    fi

    # Index screenshot videos
    if [ -d "$OCR_DIR/screenshot" ]; then
        echo "=== SCREENSHOTS TEXT INDEX ===" >> "$screenshot_index"
        echo "Generated: $(date)" >> "$screenshot_index"
        echo "" >> "$screenshot_index"

        find "$OCR_DIR/screenshot" -name "*.txt" -type f | while read -r text_file; do
            local relative_path="${text_file#$OCR_DIR/screenshot/}"

            if [ -s "$text_file" ]; then  # Only if file has content
                echo "=== SCREENSHOT: $relative_path ===" >> "$screenshot_index"
                cat "$text_file" >> "$screenshot_index"
                echo "" >> "$screenshot_index"

                # Also add to combined index
                echo "=== SCREENSHOT: $relative_path ===" >> "$combined_index"
                cat "$text_file" >> "$combined_index"
                echo "" >> "$combined_index"
            fi
        done
    fi

    log "Search indexes created:"
    log "  - Meetings: $meeting_index"
    log "  - Screenshots: $screenshot_index"
    log "  - Combined: $combined_index"
}

# Print summary
print_summary() {
    log ""
    log "=== OCR TEXT EXTRACTION SUMMARY ==="
    log "Total videos processed: $processed_videos"
    log "Videos with text extracted: $ocr_extracted_videos"
    log "Videos skipped: $skipped_videos"
    log "Errors encountered: $error_count"
    log "OCR output directory: $OCR_DIR"
    log ""

    if [ $ocr_extracted_videos -gt 0 ]; then
        log "Sample OCR files:"
        find "$OCR_DIR" -name "*.txt" -size +1c | head -5 | while read -r file; do
            local rel_path="${file#$OCR_DIR/}"
            log "  - $rel_path"
        done

        log ""
        log "🔍 Search Examples:"
        log "  # Search in meeting recordings:"
        log "  grep -r 'keyword' $OCR_DIR/meeting/"
        log ""
        log "  # Search in screenshots:"
        log "  grep -r 'keyword' $OCR_DIR/screenshot/"
        log ""
        log "  # Search everything:"
        log "  grep -r 'keyword' $OCR_DIR/"
    fi

    if [ $error_count -gt 0 ]; then
        log ""
        log "⚠️  Processing completed with $error_count errors. Check log for details."
    else
        log ""
        log "✅ OCR text extraction completed successfully!"
    fi

    log ""
    log "📋 Next Steps:"
    log "1. Run './transcribe_audio_snippets.sh' to transcribe audio"
    log "2. Search extracted text using grep or build semantic search"
    log "3. Consider SQLite integration for advanced querying"
}

# Main execution
main() {
    log "Starting OCR text extraction from organized videos..."
    log "Meetings directory: $MEETINGS_DIR"
    log "Screenshots directory: $SCREENSHOTS_DIR"
    log "OCR output: $OCR_DIR"
    log "OCR enabled: $ENABLE_OCR"
    log ""

    check_dependencies

    # Process meeting videos
    local meeting_count
    meeting_count=$(process_video_directory "$MEETINGS_DIR" "meeting")

    # Process screenshot videos
    local screenshot_count
    screenshot_count=$(process_video_directory "$SCREENSHOTS_DIR" "screenshot")

    total_videos=$((meeting_count + screenshot_count))

    # Create search index
    create_search_index

    print_summary

    exit $error_count
}

# Run main function
main "$@"