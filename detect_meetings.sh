#!/bin/bash

# detect_meetings.sh
#
# Step 2 of video processing pipeline: Detect meetings and reorganize chunks
#
# This script analyzes video chunks and audio snippets to determine which
# chunks are from meetings vs regular screenshots, then reorganizes them.
#
# Logic (to be implemented):
# - Compare video chunk timestamps with audio snippet timestamps
# - Chunks that overlap with audio snippets = meeting recordings
# - Chunks without audio = regular screenshots
# - Move files to appropriate directories (meetings vs screenshots)
#
# Prerequisites: copy_video_chunks.sh must be run first
# Followed by: extract_text_from_videos.sh

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Configuration from config.sh
VIDEO_INPUT_DIR="$VIDEO_OUTPUT_DIR"
AUDIO_SNIPPETS_DIR="$REWIND_SNIPPETS_DIR"
MEETINGS_DIR="$VIDEO_MEETINGS_DIR"
SCREENSHOTS_DIR="$VIDEO_SCREENSHOTS_DIR"
LOG_FILE="$VIDEO_LOG_FILE"
DATE_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters
total_videos=0
meeting_videos=0
screenshot_videos=0
error_count=0

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

# Check if required directories exist
check_prerequisites() {
    log "Checking prerequisites..."

    if [ ! -d "$VIDEO_INPUT_DIR" ]; then
        handle_error "Video input directory not found: $VIDEO_INPUT_DIR"
        log "Please run './copy_video_chunks.sh' first"
        exit 1
    fi

    if [ ! -d "$AUDIO_SNIPPETS_DIR" ]; then
        log "WARNING: Audio snippets directory not found: $AUDIO_SNIPPETS_DIR"
        log "Will treat all videos as screenshots"
    fi

    log "Prerequisites check completed."
}

# Parse timestamp from filename
parse_timestamp_from_filename() {
    local filename="$1"

    # Extract start timestamp from filename format: YYYY-MM-DD_HH-MM-SS_to_YYYY-MM-DD_HH-MM-SS.mp4
    if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2}-[0-9]{2})_to_([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2}-[0-9]{2})\.mp4$ ]]; then
        local start_date="${BASH_REMATCH[1]}"
        local start_time="${BASH_REMATCH[2]}"
        local end_date="${BASH_REMATCH[3]}"
        local end_time="${BASH_REMATCH[4]}"

        # Convert to timestamps (this is a placeholder - real implementation would convert properly)
        echo "$start_date $start_time $end_date $end_time"
        return 0
    else
        return 1
    fi
}

# Check if video overlaps with any audio snippet (placeholder logic)
is_meeting_video() {
    local video_file="$1"
    local filename=$(basename "$video_file")

    # Parse timestamps from filename
    local timestamps
    if timestamps=$(parse_timestamp_from_filename "$filename"); then
        # TODO: Implement actual timestamp comparison with audio snippets
        # For now, return false (treat everything as screenshots)

        # Placeholder logic: check if audio snippets directory has any content for this date
        local video_date
        video_date=$(echo "$timestamps" | cut -d' ' -f1)

        if [ -d "$AUDIO_SNIPPETS_DIR" ]; then
            # Simple heuristic: if we have audio snippets for this date, it might be a meeting
            local audio_count
            audio_count=$(find "$AUDIO_SNIPPETS_DIR" -name "*${video_date}T*" -type d 2>/dev/null | wc -l)

            if [ "$audio_count" -gt 0 ]; then
                log "Found $audio_count audio snippets for $video_date - treating as potential meeting"
                return 0  # Is a meeting
            fi
        fi
    fi

    return 1  # Is a screenshot
}

# Move video to appropriate directory
organize_video() {
    local video_file="$1"
    local relative_path="${video_file#$VIDEO_INPUT_DIR/}"
    local filename=$(basename "$video_file")
    local date_dir=$(dirname "$relative_path")

    if is_meeting_video "$video_file"; then
        # Move to meetings directory
        local meeting_dir="$MEETINGS_DIR/$date_dir"
        mkdir -p "$meeting_dir"

        local dest_file="$meeting_dir/$filename"
        if mv "$video_file" "$dest_file"; then
            log "Meeting: $relative_path -> meetings/$date_dir/$filename"
            ((meeting_videos++))
        else
            handle_error "Failed to move meeting video: $relative_path"
        fi
    else
        # Move to screenshots directory
        local screenshot_dir="$SCREENSHOTS_DIR/$date_dir"
        mkdir -p "$screenshot_dir"

        local dest_file="$screenshot_dir/$filename"
        if mv "$video_file" "$dest_file"; then
            log "Screenshot: $relative_path -> screenshots/$date_dir/$filename"
            ((screenshot_videos++))
        else
            handle_error "Failed to move screenshot video: $relative_path"
        fi
    fi
}

# Process all videos for meeting detection
process_videos() {
    log "Analyzing videos for meeting detection..."

    # Create output directories
    mkdir -p "$MEETINGS_DIR"
    mkdir -p "$SCREENSHOTS_DIR"

    # Find all video files
    local video_files=()
    while IFS= read -r -d '' file; do
        if [[ "$file" == *.mp4 ]]; then
            video_files+=("$file")
        fi
    done < <(find "$VIDEO_INPUT_DIR" -name "*.mp4" -type f -print0)

    total_videos=${#video_files[@]}
    log "Found $total_videos video files to analyze"

    if [ $total_videos -eq 0 ]; then
        log "No video files found. Please run './copy_video_chunks.sh' first."
        return 1
    fi

    # Process each video
    local count=0
    for video_file in "${video_files[@]}"; do
        ((count++))
        local relative_path="${video_file#$VIDEO_INPUT_DIR/}"

        log "Progress: $count/$total_videos - Analyzing: $relative_path"
        organize_video "$video_file"
    done
}

# Print summary
print_summary() {
    log ""
    log "=== MEETING DETECTION SUMMARY ==="
    log "Total videos analyzed: $total_videos"
    log "Meeting videos: $meeting_videos"
    log "Screenshot videos: $screenshot_videos"
    log "Errors encountered: $error_count"
    log "Meetings directory: $MEETINGS_DIR"
    log "Screenshots directory: $SCREENSHOTS_DIR"
    log ""

    if [ $meeting_videos -gt 0 ]; then
        log "Sample meeting videos:"
        find "$MEETINGS_DIR" -name "*.mp4" | head -3 | while read -r file; do
            local rel_path="${file#$MEETINGS_DIR/}"
            log "  - meetings/$rel_path"
        done
    fi

    if [ $screenshot_videos -gt 0 ]; then
        log ""
        log "Sample screenshot videos:"
        find "$SCREENSHOTS_DIR" -name "*.mp4" | head -3 | while read -r file; do
            local rel_path="${file#$SCREENSHOTS_DIR/}"
            log "  - screenshots/$rel_path"
        done
    fi

    if [ $error_count -gt 0 ]; then
        log ""
        log "⚠️  Processing completed with $error_count errors. Check log for details."
    else
        log ""
        log "✅ Meeting detection completed successfully!"
    fi

    log ""
    log "📋 Next Steps:"
    log "1. Run './extract_text_from_videos.sh' to extract text from organized videos"
    log "2. Review organization in meetings/ and screenshots/ directories"
    log ""
    log "🔮 Future Enhancements:"
    log "- Implement precise timestamp comparison with audio snippets"
    log "- Add confidence scoring for meeting detection"
    log "- Support for splitting long videos at meeting boundaries"
}

# Main execution
main() {
    log "Starting meeting detection and video organization..."
    log "Input directory: $VIDEO_INPUT_DIR"
    log "Audio snippets: $AUDIO_SNIPPETS_DIR"
    log "Meetings output: $MEETINGS_DIR"
    log "Screenshots output: $SCREENSHOTS_DIR"
    log ""
    log "⚠️  NOTE: This is a placeholder implementation."
    log "Currently using simple heuristics. Full implementation coming soon."
    log ""

    check_prerequisites
    process_videos
    print_summary

    exit $error_count
}

# Run main function
main "$@"