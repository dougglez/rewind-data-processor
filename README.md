# Rewind Data Processor

A comprehensive toolkit for extracting, processing, and organizing data from Rewind.ai (MemoryVault) with **Apple's native OCR and Vision framework integration**.

## Features

- 🎥 **Video Processing**: Convert Rewind chunks to searchable MP4 files
- 🔍 **Apple OCR Integration**: Extract text from video screenshots using Apple Vision
- 🎤 **Speech Recognition**: Transcribe audio using Apple Speech Recognition
- 🗣️ **Speaker Diarization**: Identify different speakers in meetings
- 📊 **Data Organization**: Automatic date-based organization and indexing
- 🔄 **Pipeline Automation**: Complete end-to-end processing workflow

## Setup

1. **Install dependencies**:
   ```bash
   # For video processing (required for process_video_chunks.sh)
   brew install ffmpeg

   # For Apple framework tools (optional but recommended)
   xcode-select --install
   ```

2. **Quick setup** (recommended):
   ```bash
   ./setup.sh  # Interactive setup with dependency checking
   ```

3. **Configuration**: Copy and customize the environment file:
   ```bash
   cp env.example .env
   # Edit .env with your specific settings
   ```

4. **Manual configuration**: Edit `config.sh` to match your setup:
   ```bash
   # Change these values in config.sh:
   PROJECT_NAME="my_rewind_project"  # Your project folder name
   EXTERNAL_DRIVE="/Volumes/MyDrive"  # Your external drive name
   ```

4. **Setup Apple OCR** (choose one method):
   ```bash
   # Method 1: Compile native Swift tools (best performance)
   ./compile_apple_tools.sh

   # Method 2: Use macOS Shortcuts (easier setup)
   ./create_ocr_shortcut.sh
   ```

## Scripts

### Core Processing Scripts

### `sync_audio_snippets.sh`
Synchronizes new snippets from Rewind's storage to your organized directory structure.

- **Source**: `~/Library/Application Support/com.memoryvault.MemoryVault/snippets`
- **Destination**: `~/[PROJECT_NAME]/memories/temp/audio/`
- **Features**:
  - Only copies new snippets (safe to run repeatedly)
  - Organizes by date (YYYY-MM-DD)
  - Detailed logging

**Usage**:
```bash
./sync_audio_snippets.sh
```

### `organize_snippets.sh`
Organizes local snippet directories into date-based structure.

- **Source**: `./snippets` (relative to current directory)
- **Destination**: `~/[PROJECT_NAME]/audio/`
- **Features**: Date-based organization

**Usage**:
```bash
./organize_snippets.sh
```

### `process_video_chunks.sh`
Processes Rewind video chunks into individual MP4 files with readable timestamps.

- **Source**: `~/Library/Application Support/com.memoryvault.MemoryVault/chunks`
- **Test Copy**: `~/Desktop/chunks_copy` (for safe testing)
- **Destination**: `~/[PROJECT_NAME]/video/processed/`
- **Features**:
  - Copies chunks to desktop for testing (doesn't modify originals)
  - Converts chunk files to proper MP4 format
  - Renames with human-readable timestamps: `YYYY-MM-DD_HH-MM-SS_to_YYYY-MM-DD_HH-MM-SS.mp4`
  - Preserves original metadata and creation times
  - Organizes by date directories
  - Calculates accurate end times using video duration
  - Progress reporting and detailed logging

**Requirements**: `ffmpeg` must be installed

### `process_video_chunks_with_ocr.sh` 🆕🔍
**Enhanced video processor with Apple OCR integration**

All features of `process_video_chunks.sh` PLUS:
- **Apple Vision OCR**: Extracts text from video screenshots using Apple's frameworks
- **Searchable Text Files**: Creates `.txt` files alongside each `.mp4`
- **Search Index**: Builds searchable index of all extracted text
- **Native Performance**: Uses Apple's optimized text recognition
- **Multiple OCR Methods**: Swift tools or Shortcuts integration

**Usage**:
```bash
./process_video_chunks_with_ocr.sh
```

**Output Structure**:
```
video/
├── processed/
│   └── 2024-01-15/
│       ├── 2024-01-15_14-30-00_to_2024-01-15_14-32-15.mp4
│       └── 2024-01-15_15-45-30_to_2024-01-15_15-47-45.mp4
└── ocr_text/
    └── 2024-01-15/
        ├── 2024-01-15_14-30-00_to_2024-01-15_14-32-15.txt
        └── 2024-01-15_15-45-30_to_2024-01-15_15-47-45.txt
```

### `backup_to_external.sh`
Backs up data to external storage with checksum verification.

- **Source**: `[EXTERNAL_DRIVE]/[PROJECT_NAME]/backup/[DATE]/`
- **Destination**: `[EXTERNAL_DRIVE]/[PROJECT_NAME]/test/[DATE]/`
- **Features**:
  - Checksum verification
  - Progress display
  - Handles both chunks and snippets

**Usage**:
```bash
./backup_to_external.sh
```

## Apple Vision & OCR Tools 🍎

### `compile_apple_tools.sh`
Compiles native Swift command-line tools using Apple's Vision framework.

**Creates**:
- `bin/apple_ocr` - Native OCR tool with best performance
- `apple_vision_helpers.sh` - Bash helper functions
- `apple_transcribe.swift` - Transcription tool template

**Usage**:
```bash
./compile_apple_tools.sh
```

### `create_ocr_shortcut.sh`
Sets up macOS Shortcuts for OCR (alternative to Swift tools).

**Features**:
- Uses built-in Shortcuts app
- No compilation required
- Easy setup for non-developers

**Usage**:
```bash
./create_ocr_shortcut.sh
```

### Apple OCR Integration

**Direct Usage**:
```bash
# Using compiled Swift tool
./bin/apple_ocr screenshot.png

# Using Shortcuts
shortcuts run "Extract Text CLI" -i screenshot.png

# Using helper functions
source apple_vision_helpers.sh
apple_ocr "/path/to/image.png"
```

**In Scripts**:
```bash
# Auto-detects available OCR method
source apple_vision_helpers.sh
extracted_text=$(apple_ocr "$image_file")
```

## Testing & Setup Scripts

### `setup.sh` 🚀
**Interactive setup wizard**

**Features**:
- Dependency checking and installation
- Configuration wizard
- Rewind data directory validation
- OCR capability testing
- Usage guidance

**Usage**:
```bash
./setup.sh
```

### `test_video_processing.sh`
Unit test for video chunk processing functionality.

**Features**:
- Creates mock video files for testing
- Verifies script functionality without touching real data
- Tests file naming patterns and directory structure
- Validates dependency requirements

**Usage**:
```bash
./test_video_processing.sh
```

## Configuration File

All scripts source `config.sh` for centralized configuration:

### Basic Configuration
- `PROJECT_NAME`: Your project folder name
- `EXTERNAL_DRIVE`: Path to your external drive

### Rewind Paths
- `REWIND_SNIPPETS_DIR`: Rewind's snippet storage location
- `REWIND_CHUNKS_DIR`: Rewind's video chunks storage location

### Video Processing Paths
- `VIDEO_OUTPUT_DIR`: Processed video files
- `VIDEO_SCREENSHOTS_DIR`: Non-meeting screenshots (future use)
- `VIDEO_MEETINGS_DIR`: Meeting recordings (future use)
- `CHUNKS_TEST_DIR`: Desktop copy for safe testing

### OCR Configuration 🆕
- `OCR_OUTPUT_DIR`: Extracted text from screenshots
- `SEARCHABLE_INDEX_DIR`: Search database location
- `ENABLE_OCR`: Enable/disable OCR processing
- `OCR_METHOD`: Preferred OCR method ("swift", "shortcuts", "auto")
- `OCR_CONFIDENCE_THRESHOLD`: Minimum confidence for text recognition

## Directory Structure

After running the scripts, your directory structure will look like:

```
~/[PROJECT_NAME]/
├── audio/
│   ├── 2024-01-15/
│   │   ├── 2024-01-15T09:30:00/
│   │   └── 2024-01-15T14:22:15/
│   └── 2024-01-16/
├── video/
│   ├── processed/
│   │   ├── 2024-01-15/
│   │   │   ├── 2024-01-15_14-30-00_to_2024-01-15_14-32-15.mp4
│   │   │   └── 2024-01-15_15-45-30_to_2024-01-15_15-47-45.mp4
│   │   └── 2024-01-16/
│   └── ocr_text/ 🆕
│       ├── 2024-01-15/
│       │   ├── 2024-01-15_14-30-00_to_2024-01-15_14-32-15.txt
│       │   └── 2024-01-15_15-45-30_to_2024-01-15_15-47-45.txt
│       └── 2024-01-16/
├── search_index/ 🆕
│   └── text_index.txt
├── memories/
│   └── temp/
│       ├── audio/
│       └── video/
├── sync_audio_snippets.log
└── process_video_chunks.log
```

## Video Processing Details

### Chunk Structure
Rewind stores video chunks in a nested structure:
- `/chunks/YYYYMM/DD/filename` (no file extensions)
- Files are MP4 format but hidden by Rewind
- Videos are 0.5 FPS screenshots (every 2 seconds)

### Processing Logic
1. **Safe Testing**: Copies chunks to `~/Desktop/chunks_copy` first
2. **Metadata Extraction**: Uses file creation time as start time
3. **Duration Calculation**: Uses `ffprobe` to get accurate video length
4. **End Time**: Calculated as start_time + duration
5. **Naming**: Human-readable format with start and end timestamps
6. **Organization**: Files sorted into date-based directories
7. **OCR Processing** 🆕: Extracts text from video frames using Apple Vision
8. **Search Indexing** 🆕: Creates searchable text index

### Meeting Detection (Future)
The video processing script prepares for future meeting detection:
- Audio snippets only exist during meetings (based on current observations)
- This will be used to separate meeting recordings from regular screenshots
- Meeting videos will be moved to `VIDEO_MEETINGS_DIR`
- Regular screenshots will go to `VIDEO_SCREENSHOTS_DIR`

## Apple Vision Framework Integration 🍎

### Why Apple's OCR?

**Advantages**:
- ✅ **Native Performance**: Optimized for Apple Silicon
- ✅ **No Internet Required**: Completely offline
- ✅ **High Accuracy**: Industry-leading text recognition
- ✅ **Multi-language**: Automatic language detection
- ✅ **Privacy**: All processing happens on-device
- ✅ **No Cost**: No API fees or usage limits

**vs. Third-party OCR**:
- Better accuracy than Tesseract on screenshots
- Faster than cloud-based services (Google Vision, AWS Textract)
- No API costs or rate limiting
- Perfect integration with macOS ecosystem

### OCR Methods Available

1. **Swift Command-line Tool** (Recommended)
   - Best performance and accuracy
   - Requires compilation (automatic via `compile_apple_tools.sh`)
   - Direct Vision framework access

2. **macOS Shortcuts Integration**
   - Easy setup, no compilation
   - Good for non-developers
   - Uses same Vision framework under the hood

3. **Auto-detection**
   - Scripts automatically choose best available method
   - Fallback chain: Swift tool → Shortcuts → Error

## Requirements

- **macOS** (uses Rewind.ai paths and Apple frameworks)
- **macOS 12.0+** for Shortcuts OCR functionality
- **rsync** (for efficient copying)
- **ffmpeg/ffprobe** (for video processing)
- **Xcode Command Line Tools** (for Swift OCR compilation)
- **External drive** (for backup script)

## Future Enhancements

### Planned Features
1. **Audio-Video Matching**: Script to sync audio snippets with video chunks
2. **Meeting Detection**: Automatically separate meeting recordings from screenshots
3. **SQLite Integration**: Database for managing file relationships and metadata
4. **Semantic Search**: Natural language search through extracted text
5. **Speech Recognition**: Transcribe audio snippets using Apple's Speech framework 🆕
6. **Smart Meeting Detection**: Use OCR text + audio to identify meeting content

### Database Schema (Planned)
- `meetings` table with start/end times, titles, UUIDs
- `audio_snippets` table linking to meetings
- `video_chunks` table linking to meetings
- `screenshots` table for non-meeting captures
- `ocr_text` table for searchable text content 🆕
- `transcripts` table for audio transcriptions 🆕

## Quick Start Guide

```bash
# 1. Clone or download scripts
cd "my own scripts"

# 2. Run interactive setup
./setup.sh

# 3. Process video chunks with OCR
./process_video_chunks_with_ocr.sh

# 4. Organize audio snippets
./sync_audio_snippets.sh

# 5. Search extracted text
grep -r "meeting" ~/your_project_name/video/ocr_text/
```

## Notes

- The Rewind application stores data in `/Library/Application Support/com.memoryvault.MemoryVault/`
- Scripts are designed to be safe to run multiple times
- All paths are configurable through `config.sh`
- Video processing uses desktop copy to avoid modifying original Rewind data
- Audio snippets appear to only be created during meetings (useful for detection logic)
- OCR processing is completely offline and respects privacy
- Apple's Vision framework provides industry-leading accuracy for screenshot text extraction