#!/bin/bash

# Script to copy snippets to date-based directories in ~/PROJECT_NAME/audio
# Format: ./snippets/YYYY-MM-DDThh:mm:ss -> ~/PROJECT_NAME/audio/YYYY-MM-DD/YYYY-MM-DDThh:mm:ss

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Configuration from config.sh
SRC_DIR="$SNIPPETS_SOURCE_DIR"
DEST_DIR="$AUDIO_DIR"

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
  echo "Error: Source directory '$SRC_DIR' not found."
  exit 1
fi

# Ensure base destination directory exists
mkdir -p "$DEST_DIR"
echo "Created base directory: $DEST_DIR"

# Counter for processed directories
processed=0
skipped=0

# Iterate over all entries in the snippets directory
echo "Starting to process snippet directories..."
for snippet in "$SRC_DIR"/*; do
  # Skip if not a directory
  if [ ! -d "$snippet" ]; then
    echo "Skipping non-directory: $(basename "$snippet")"
    ((skipped++))
    continue
  fi

  # Get directory name
  dirname=$(basename "$snippet")

  # Extract date portion (YYYY-MM-DD) if it matches the pattern
  if [[ "$dirname" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}:[0-9]{2}:[0-9]{2})$ ]]; then
    date_part=${BASH_REMATCH[1]}

    # Create target date directory if it doesn't exist
    date_dir="$DEST_DIR/$date_part"
    if [ ! -d "$date_dir" ]; then
      mkdir -p "$date_dir"
      echo "Created date directory: $date_part"
    fi

    # Copy directory using rsync
    # -a preserves permissions, timestamps, recursive, etc.
    # --exclude skips .DS_Store files
    echo "Copying $dirname to $date_dir/"
    if rsync -a --exclude=".DS_Store" "$snippet" "$date_dir/"; then
      ((processed++))
      echo "Successfully copied $dirname"
    else
      echo "Error copying $dirname"
      exit 1
    fi
  else
    echo "Skipping directory with invalid format: $dirname"
    ((skipped++))
  fi
done

echo ""
echo "Completed organization of snippets:"
echo "- Processed $processed directories"
echo "- Skipped $skipped entries"
echo "All snippets have been organized in $DEST_DIR"

# Output final structure sample if any directories were processed
if [ $processed -gt 0 ]; then
  echo ""
  echo "Directory structure (sample):"
  find "$DEST_DIR" -type d -depth 2 | head -5
fi
