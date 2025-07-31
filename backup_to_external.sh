#!/bin/bash

# Script to safely back up project data to external storage
# with checksum verification and dated folder destination.

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Get today's date in YYYY-MM-DD format
TODAY=$(date +%Y-%m-%d)

# Define source and destination paths for chunks
SRC="$BACKUP_BASE/$TODAY/chunks"
DEST="$TEST_BASE/$TODAY/chunks"

# Make sure the destination directory exists
mkdir -p "$DEST"

# Run rsync with archive, verbose, human-readable, checksum, progress, and in-place options
echo "Backing up chunks..."
rsync -avhc --progress --inplace "$SRC" "$DEST"

# Run it again for snippets
echo "Backing up snippets..."
SRC="$BACKUP_BASE/$TODAY/snippets"
DEST="$TEST_BASE/$TODAY/snippets"

mkdir -p "$DEST"
rsync -avhc --progress --inplace "$SRC" "$DEST"

echo "✅ Backup completed to: $TEST_BASE/$TODAY"