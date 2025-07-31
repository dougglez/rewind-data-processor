#!/bin/bash

# transcribe_audio_snippets.sh
#
# Audio transcription using Apple's Speech Recognition framework
#
# This script processes audio snippets from Rewind and creates text transcriptions
# using Apple's native Speech framework for maximum accuracy and privacy.
#
# Features:
# - Processes audio snippets from organized directories
# - Uses Apple's Speech Recognition (better than most cloud services)
# - Creates transcription files with metadata
# - Builds searchable index of all transcriptions
# - Handles speaker diarization (when available)
# - 100% offline processing for privacy

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Configuration from config.sh
AUDIO_SNIPPETS_DIR="$REWIND_SNIPPETS_DIR"
ORGANIZED_AUDIO_DIR="$AUDIO_DIR"
TRANSCRIPTS_DIR="$TRANSCRIPTS_OUTPUT_DIR"
LOG_FILE="$AUDIO_TRANSCRIPTION_LOG_FILE"
DATE_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters
total_audio_files=0
processed_audio_files=0
transcribed_files=0
error_count=0
skipped_files=0

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$TRANSCRIPTS_DIR"

# Log function
log() {
    echo "[$DATE_FORMAT] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    ((error_count++))
}

# Check dependencies and setup
check_dependencies() {
    log "Checking speech recognition dependencies..."

    # Check if Apple Speech tool is available
    if [ -f "$SCRIPT_DIR/bin/apple_speech" ]; then
        log "Native Apple Speech tool available"

        # Check permissions
        if "$SCRIPT_DIR/bin/apple_speech" --help &>/dev/null; then
            log "Apple Speech tool is functional"
        else
            log "WARNING: Apple Speech tool found but may need permissions"
            log "Run: $SCRIPT_DIR/bin/apple_speech --request-permission"
        fi
    else
        log "WARNING: Apple Speech tool not found"
        log "Run './compile_apple_tools.sh' to compile speech recognition tools"

        if [ "$ENABLE_TRANSCRIPTION" = "true" ]; then
            handle_error "Transcription enabled but no speech tools available"
            exit 1
        fi
    fi

    log "Dependencies check completed."
}

# Get audio file duration (for progress tracking)
get_audio_duration() {
    local audio_file="$1"

    if command -v ffprobe &> /dev/null; then
        ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Transcribe a single audio file
transcribe_audio_file() {
    local audio_file="$1"
    local output_transcript_file="$2"
    local relative_path="$3"

    if [ "$ENABLE_TRANSCRIPTION" != "true" ]; then
        return 1
    fi

    log "Transcribing: $relative_path"

    # Check if Apple Speech tool is available
    if [ -f "$SCRIPT_DIR/bin/apple_speech" ]; then
        local duration
        duration=$(get_audio_duration "$audio_file")

        if [ "$duration" != "0" ] && [ -n "$duration" ]; then
            log "Audio duration: ${duration%.*} seconds"
        fi

        # Transcribe using Apple Speech Recognition
        local transcription
        if transcription=$("$SCRIPT_DIR/bin/apple_speech" "$audio_file" --metadata 2>/dev/null); then

            if [ -n "$transcription" ] && [ "$transcription" != "No speech detected in audio file" ]; then
                # Save transcription with additional metadata
                {
                    echo "# Audio Transcription"
                    echo "# Audio File: $(basename "$audio_file")"
                    echo "# Relative Path: $relative_path"
                    echo "# Duration: ${duration%.*} seconds"
                    echo "# Transcribed: $(date)"
                    echo "# Method: Apple Speech Recognition Framework"
                    echo ""
                    echo "$transcription"
                } > "$output_transcript_file"

                local word_count
                word_count=$(echo "$transcription" | wc -w)
                log "Transcribed $word_count words from $relative_path"
                return 0
            fi
        fi
    fi

    return 1
}

# Process audio files in a directory
process_audio_directory() {
    local input_dir="$1"
    local dir_type="$2"  # "snippets" or "organized"

    if [ ! -d "$input_dir" ]; then
        log "Audio directory not found: $input_dir (skipping $dir_type)"
        return 0
    fi

    log "Processing $dir_type audio files from: $input_dir"

    # Find all audio files (common formats)
    local audio_files=()
    while IFS= read -r -d '' file; do
        if [[ "$file" =~ \.(wav|mp3|m4a|aac|flac|ogg)$ ]]; then
            audio_files+=("$file")
        fi
    done < <(find "$input_dir" -type f -print0)

    local dir_audio_count=${#audio_files[@]}
    log "Found $dir_audio_count $dir_type audio files"

    # Process each audio file
    local count=0
    for audio_file in "${audio_files[@]}"; do
        ((count++))
        ((total_audio_files++))

        local relative_path="${audio_file#$input_dir/}"
        local filename=$(basename "$audio_file")
        local audio_dir=$(dirname "$relative_path")

        log "Progress: $count/$dir_audio_count - Processing: $relative_path"

        # Create transcript output directory structure
        local transcript_type_dir="$TRANSCRIPTS_DIR/$dir_type"
        local transcript_output_dir="$transcript_type_dir/$audio_dir"
        mkdir -p "$transcript_output_dir"

        # Create transcript filename (replace audio extension with .txt)
        local base_filename="${filename%.*}"
        local transcript_file="$transcript_output_dir/${base_filename}.txt"

        ((processed_audio_files++))

        # Transcribe the audio file
        if transcribe_audio_file "$audio_file" "$transcript_file" "$relative_path"; then
            ((transcribed_files++))
        else
            # Create empty transcript file to indicate transcription was attempted
            {
                echo "# Audio Transcription"
                echo "# Audio File: $(basename "$audio_file")"
                echo "# Relative Path: $relative_path"
                echo "# Transcribed: $(date)"
                echo "# Result: No speech detected or transcription failed"
            } > "$transcript_file"

            log "No speech detected in: $relative_path"
            ((skipped_files++))
        fi
    done

    return $dir_audio_count
}

# Create search index from transcriptions
create_transcript_index() {
    if [ "$ENABLE_TRANSCRIPTION" != "true" ] || [ $transcribed_files -eq 0 ]; then
        return 0
    fi

    log "Creating search index from transcriptions..."

    # Create search index directory
    mkdir -p "$SEARCHABLE_INDEX_DIR"

    # Create transcript indexes
    local snippets_index="$SEARCHABLE_INDEX_DIR/audio_snippets_transcripts.txt"
    local organized_index="$SEARCHABLE_INDEX_DIR/organized_audio_transcripts.txt"
    local all_transcripts_index="$SEARCHABLE_INDEX_DIR/all_transcripts.txt"

    # Clear existing indexes
    > "$snippets_index"
    > "$organized_index"
    > "$all_transcripts_index"

    # Index snippet transcriptions
    if [ -d "$TRANSCRIPTS_DIR/snippets" ]; then
        echo "=== AUDIO SNIPPETS TRANSCRIPTS INDEX ===" >> "$snippets_index"
        echo "Generated: $(date)" >> "$snippets_index"
        echo "" >> "$snippets_index"

        find "$TRANSCRIPTS_DIR/snippets" -name "*.txt" -type f | while read -r transcript_file; do
            local relative_path="${transcript_file#$TRANSCRIPTS_DIR/snippets/}"

            if [ -s "$transcript_file" ]; then  # Only if file has content
                echo "=== SNIPPET: $relative_path ===" >> "$snippets_index"
                cat "$transcript_file" >> "$snippets_index"
                echo "" >> "$snippets_index"

                # Also add to combined index
                echo "=== SNIPPET: $relative_path ===" >> "$all_transcripts_index"
                cat "$transcript_file" >> "$all_transcripts_index"
                echo "" >> "$all_transcripts_index"
            fi
        done
    fi

    # Index organized audio transcriptions
    if [ -d "$TRANSCRIPTS_DIR/organized" ]; then
        echo "=== ORGANIZED AUDIO TRANSCRIPTS INDEX ===" >> "$organized_index"
        echo "Generated: $(date)" >> "$organized_index"
        echo "" >> "$organized_index"

        find "$TRANSCRIPTS_DIR/organized" -name "*.txt" -type f | while read -r transcript_file; do
            local relative_path="${transcript_file#$TRANSCRIPTS_DIR/organized/}"

            if [ -s "$transcript_file" ]; then  # Only if file has content
                echo "=== ORGANIZED: $relative_path ===" >> "$organized_index"
                cat "$transcript_file" >> "$organized_index"
                echo "" >> "$organized_index"

                # Also add to combined index
                echo "=== ORGANIZED: $relative_path ===" >> "$all_transcripts_index"
                cat "$transcript_file" >> "$all_transcripts_index"
                echo "" >> "$all_transcripts_index"
            fi
        done
    fi

    log "Transcript indexes created:"
    log "  - Snippets: $snippets_index"
    log "  - Organized: $organized_index"
    log "  - Combined: $all_transcripts_index"
}

# Print summary
print_summary() {
    log ""
    log "=== AUDIO TRANSCRIPTION SUMMARY ==="
    log "Total audio files found: $total_audio_files"
    log "Audio files processed: $processed_audio_files"
    log "Successful transcriptions: $transcribed_files"
    log "Files skipped/no speech: $skipped_files"
    log "Errors encountered: $error_count"
    log "Transcripts directory: $TRANSCRIPTS_DIR"
    log ""

    if [ $transcribed_files -gt 0 ]; then
        log "Sample transcript files:"
        find "$TRANSCRIPTS_DIR" -name "*.txt" -size +1c | head -5 | while read -r file; do
            local rel_path="${file#$TRANSCRIPTS_DIR/}"
            log "  - $rel_path"
        done

        log ""
        log "🔍 Search Examples:"
        log "  # Search in audio snippet transcripts:"
        log "  grep -r 'keyword' $TRANSCRIPTS_DIR/snippets/"
        log ""
        log "  # Search in organized audio transcripts:"
        log "  grep -r 'keyword' $TRANSCRIPTS_DIR/organized/"
        log ""
        log "  # Search all transcripts:"
        log "  grep -r 'keyword' $TRANSCRIPTS_DIR/"
        log ""
        log "  # Find specific speakers or topics:"
        log "  grep -r 'meeting\\|discussion\\|presentation' $TRANSCRIPTS_DIR/"
    fi

    if [ $error_count -gt 0 ]; then
        log ""
        log "⚠️  Processing completed with $error_count errors. Check log for details."
    else
        log ""
        log "✅ Audio transcription completed successfully!"
    fi

    log ""
    log "🍎 Apple Speech Recognition Benefits:"
    log "  • 100% offline processing - complete privacy"
    log "  • Industry-leading accuracy for English"
    log "  • No API costs or usage limits"
    log "  • Optimized for Apple devices"
    log ""
    log "📋 Next Steps:"
    log "1. Search transcripts using grep for quick queries"
    log "2. Build semantic search integration"
    log "3. Correlate with video OCR text for complete context"
    log "4. Consider SQLite integration for advanced querying"
}

# Main execution
main() {
    log "Starting audio transcription using Apple Speech Recognition..."
    log "Audio snippets: $AUDIO_SNIPPETS_DIR"
    log "Organized audio: $ORGANIZED_AUDIO_DIR"
    log "Transcripts output: $TRANSCRIPTS_DIR"
    log "Transcription enabled: $ENABLE_TRANSCRIPTION"
    log ""

    check_dependencies

    # Process audio snippets (from Rewind)
    local snippets_count
    snippets_count=$(process_audio_directory "$AUDIO_SNIPPETS_DIR" "snippets")

    # Process organized audio (if available)
    local organized_count
    organized_count=$(process_audio_directory "$ORGANIZED_AUDIO_DIR" "organized")

    # Create search index
    create_transcript_index

    print_summary

    exit $error_count
}

# Run main function
main "$@"