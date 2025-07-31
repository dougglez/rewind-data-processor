#!/bin/bash

# sync_audio_snippets.sh
#
# This script synchronizes new snippets from the snippets directory to the
# organized audio directory structure. It only copies snippets that don't
# already exist in the destination, making it safe to run repeatedly.
#
# Recommended usage: Run daily or weekly via cron job or manually

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Configuration from config.sh
SRC_DIR="$REWIND_SNIPPETS_DIR"
DEST_BASE_DIR="$TEMP_AUDIO_DIR"
DATE_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[$DATE_FORMAT] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
    handle_error "Source directory '$SRC_DIR' not found."
fi

# Ensure base destination directory exists
if [ ! -d "$DEST_BASE_DIR" ]; then
    mkdir -p "$DEST_BASE_DIR"
    log "Created base directory: $DEST_BASE_DIR"
fi

# Initialize counters
new_dirs=0
existing_dirs=0
error_count=0

log "Starting snippet synchronization..."

# Process each directory in snippets
for snippet in "$SRC_DIR"/*; do
    # Skip if not a directory
    if [ ! -d "$snippet" ]; then
        continue
    fi

    dirname=$(basename "$snippet")

    # Check if it matches the datetime pattern
    if [[ "$dirname" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}:[0-9]{2}:[0-9]{2})$ ]]; then
        date_part=${BASH_REMATCH[1]}
        date_dir="$DEST_BASE_DIR/$date_part"
        target_dir="$date_dir/$dirname"

        # Skip if already exists
        if [ -d "$target_dir" ]; then
            ((existing_dirs++))
            continue
        fi

        # Create date directory if needed
        if [ ! -d "$date_dir" ]; then
            mkdir -p "$date_dir"
            log "Created date directory: $date_part"
        fi

        # Copy directory
        log "Copying $dirname to $date_dir/"
        if rsync -a --exclude=".DS_Store" "$snippet" "$date_dir/"; then
            ((new_dirs++))
            log "Successfully copied $dirname"
        else
            ((error_count++))
            log "Error copying $dirname"
        fi
    else
        log "Skipping directory with invalid format: $dirname"
    fi
done

# Print summary
log ""
log "Synchronization completed:"
log "- New directories copied: $new_dirs"
log "- Existing directories skipped: $existing_dirs"
log "- Errors encountered: $error_count"

if [ $new_dirs -eq 0 ] && [ $error_count -eq 0 ]; then
    log "No new snippets to copy."
elif [ $new_dirs -gt 0 ] && [ $error_count -eq 0 ]; then
    log "All new snippets successfully copied to $DEST_BASE_DIR"
fi

exit $error_count
