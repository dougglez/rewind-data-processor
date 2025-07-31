#!/bin/bash

# Configuration file for Rewind data extraction scripts
# Update these values for your specific setup

# Project Configuration
PROJECT_NAME="your_project_name"  # Change this to your desired project folder name

# Rewind/MemoryVault Paths
REWIND_SNIPPETS_DIR="$HOME/Library/Application Support/com.memoryvault.MemoryVault/snippets"
REWIND_CHUNKS_DIR="$HOME/Library/Application Support/com.memoryvault.MemoryVault/chunks"

# Local Project Paths
PROJECT_BASE_DIR="$HOME/$PROJECT_NAME"
MEMORIES_DIR="$PROJECT_BASE_DIR/memories"
AUDIO_DIR="$PROJECT_BASE_DIR/audio"
VIDEO_DIR="$PROJECT_BASE_DIR/video"
TEMP_AUDIO_DIR="$MEMORIES_DIR/temp/audio"
TEMP_VIDEO_DIR="$MEMORIES_DIR/temp/video"

# Video Processing Pipeline Paths (Modular Approach)
CHUNKS_TEST_DIR="$HOME/Desktop/chunks_copy"  # Desktop copy for testing
VIDEO_OUTPUT_DIR="$VIDEO_DIR/processed"      # Step 1: Copy and organize output
VIDEO_MEETINGS_DIR="$VIDEO_DIR/meetings"     # Step 2: Meeting videos
VIDEO_SCREENSHOTS_DIR="$VIDEO_DIR/screenshots"  # Step 2: Screenshot videos

# OCR and Text Extraction Paths
OCR_OUTPUT_DIR="$VIDEO_DIR/ocr_text"  # Step 3: Extracted text from videos
SEARCHABLE_INDEX_DIR="$PROJECT_BASE_DIR/search_index"  # Search database location
APPLE_TOOLS_BIN="$PROJECT_BASE_DIR/scripts/bin"  # Compiled Apple framework tools

# Audio Transcription Paths
TRANSCRIPTS_OUTPUT_DIR="$PROJECT_BASE_DIR/transcripts"  # Audio transcriptions
AUDIO_TRANSCRIPTION_LOG_FILE="$PROJECT_BASE_DIR/transcribe_audio.log"

# Log Files
LOG_FILE="$PROJECT_BASE_DIR/sync_audio_snippets.log"
VIDEO_LOG_FILE="$PROJECT_BASE_DIR/process_video_chunks.log"

# External Drive Configuration
EXTERNAL_DRIVE="/Volumes/your_external_drive"  # Change to your external drive name
EXTERNAL_PROJECT_DIR="$EXTERNAL_DRIVE/$PROJECT_NAME"
BACKUP_BASE="$EXTERNAL_PROJECT_DIR/backup"
TEST_BASE="$EXTERNAL_PROJECT_DIR/test"

# Script Configuration
SNIPPETS_SOURCE_DIR="./snippets"  # Relative path for organize_snippets.sh

# OCR Configuration
ENABLE_OCR="true"  # Set to "false" to disable OCR processing
OCR_METHOD="auto"  # Options: "swift", "shortcuts", "auto"
OCR_CONFIDENCE_THRESHOLD="0.8"  # Minimum confidence for text recognition

# Audio Transcription Configuration
ENABLE_TRANSCRIPTION="true"  # Set to "false" to disable audio transcription
TRANSCRIPTION_LANGUAGE="en-US"  # Language for speech recognition
TRANSCRIPTION_FORMAT="text"  # Output format: "text" or "json"
TRANSCRIPTION_INCLUDE_METADATA="true"  # Include metadata in transcription files

# Processing Pipeline Configuration
PIPELINE_PARALLEL_PROCESSING="false"  # Enable parallel processing (experimental)
PIPELINE_BATCH_SIZE="10"  # Number of files to process in each batch
PIPELINE_CLEANUP_TEMP_FILES="true"  # Clean up temporary files after processing