#!/bin/bash

# run_full_pipeline.sh
#
# Master script that runs the complete Rewind data extraction pipeline
#
# This script orchestrates all the modular processing steps:
# 1. Copy and organize video chunks
# 2. Detect meetings and organize into categories
# 3. Extract text from videos using OCR
# 4. Transcribe audio snippets using speech recognition
#
# Can be run in full or individual steps

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize tracking
PIPELINE_START_TIME=$(date +%s)
STEP_ERRORS=0
TOTAL_STEPS=4

echo -e "${BLUE}🚀 Rewind Data Extraction Pipeline${NC}"
echo "=================================="
echo ""
echo "This will run the complete data extraction pipeline:"
echo "1. Copy & organize video chunks"
echo "2. Detect meetings vs screenshots"
echo "3. Extract text using Apple OCR"
echo "4. Transcribe audio using Apple Speech Recognition"
echo ""

# Function to log pipeline steps
log_step() {
    local step_num="$1"
    local step_name="$2"
    local status="$3"  # "start", "success", "error"

    case $status in
        "start")
            echo -e "${CYAN}📋 Step $step_num/$TOTAL_STEPS: $step_name${NC}"
            echo "----------------------------------------"
            ;;
        "success")
            echo -e "${GREEN}✅ Step $step_num completed successfully${NC}"
            echo ""
            ;;
        "error")
            echo -e "${RED}❌ Step $step_num failed${NC}"
            echo ""
            ((STEP_ERRORS++))
            ;;
    esac
}

# Function to check if a step should be skipped
should_skip_step() {
    local step="$1"

    # Check command line arguments for selective execution
    if [ $# -gt 0 ]; then
        for arg in "$@"; do
            if [ "$arg" = "$step" ]; then
                return 1  # Don't skip
            fi
        done
        return 0  # Skip this step
    fi

    return 1  # Don't skip (run all steps)
}

# Step 1: Copy and organize video chunks
step1_copy_chunks() {
    if should_skip_step "copy" "$@"; then
        echo -e "${YELLOW}⏭️  Skipping Step 1: Copy chunks${NC}"
        return 0
    fi

    log_step 1 "Copy and organize video chunks" "start"

    if [ -f "$SCRIPT_DIR/copy_video_chunks.sh" ]; then
        if "$SCRIPT_DIR/copy_video_chunks.sh"; then
            log_step 1 "" "success"
        else
            log_step 1 "" "error"
            return 1
        fi
    else
        echo -e "${RED}❌ Script not found: copy_video_chunks.sh${NC}"
        log_step 1 "" "error"
        return 1
    fi
}

# Step 2: Detect meetings and organize
step2_detect_meetings() {
    if should_skip_step "meetings" "$@"; then
        echo -e "${YELLOW}⏭️  Skipping Step 2: Detect meetings${NC}"
        return 0
    fi

    log_step 2 "Detect meetings and organize videos" "start"

    if [ -f "$SCRIPT_DIR/detect_meetings.sh" ]; then
        if "$SCRIPT_DIR/detect_meetings.sh"; then
            log_step 2 "" "success"
        else
            log_step 2 "" "error"
            return 1
        fi
    else
        echo -e "${RED}❌ Script not found: detect_meetings.sh${NC}"
        log_step 2 "" "error"
        return 1
    fi
}

# Step 3: Extract text using OCR
step3_extract_text() {
    if should_skip_step "ocr" "$@"; then
        echo -e "${YELLOW}⏭️  Skipping Step 3: OCR text extraction${NC}"
        return 0
    fi

    log_step 3 "Extract text from videos using OCR" "start"

    if [ "$ENABLE_OCR" != "true" ]; then
        echo -e "${YELLOW}⚠️  OCR disabled in configuration${NC}"
        log_step 3 "" "success"
        return 0
    fi

    if [ -f "$SCRIPT_DIR/extract_text_from_videos.sh" ]; then
        if "$SCRIPT_DIR/extract_text_from_videos.sh"; then
            log_step 3 "" "success"
        else
            log_step 3 "" "error"
            return 1
        fi
    else
        echo -e "${RED}❌ Script not found: extract_text_from_videos.sh${NC}"
        log_step 3 "" "error"
        return 1
    fi
}

# Step 4: Transcribe audio
step4_transcribe_audio() {
    if should_skip_step "transcribe" "$@"; then
        echo -e "${YELLOW}⏭️  Skipping Step 4: Audio transcription${NC}"
        return 0
    fi

    log_step 4 "Transcribe audio using Speech Recognition" "start"

    if [ "$ENABLE_TRANSCRIPTION" != "true" ]; then
        echo -e "${YELLOW}⚠️  Audio transcription disabled in configuration${NC}"
        log_step 4 "" "success"
        return 0
    fi

    if [ -f "$SCRIPT_DIR/transcribe_audio_snippets.sh" ]; then
        if "$SCRIPT_DIR/transcribe_audio_snippets.sh"; then
            log_step 4 "" "success"
        else
            log_step 4 "" "error"
            return 1
        fi
    else
        echo -e "${RED}❌ Script not found: transcribe_audio_snippets.sh${NC}"
        log_step 4 "" "error"
        return 1
    fi
}

# Function to print usage
print_usage() {
    echo "Usage: $0 [steps...]"
    echo ""
    echo "Run the complete Rewind data extraction pipeline or specific steps."
    echo ""
    echo "Steps:"
    echo "  copy       Copy and organize video chunks"
    echo "  meetings   Detect meetings and organize videos"
    echo "  ocr        Extract text from videos using OCR"
    echo "  transcribe Transcribe audio using Speech Recognition"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run complete pipeline"
    echo "  $0 copy meetings      # Run only copy and meeting detection"
    echo "  $0 ocr transcribe     # Run only OCR and transcription"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

    local missing_tools=0

    # Check if config file exists
    if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
        echo -e "${RED}❌ Configuration file not found: config.sh${NC}"
        ((missing_tools++))
    fi

    # Check if Apple tools are compiled (if needed)
    if [ "$ENABLE_OCR" = "true" ] && [ ! -f "$SCRIPT_DIR/bin/apple_ocr" ]; then
        echo -e "${YELLOW}⚠️  OCR tool not found. Run './compile_apple_tools.sh' first${NC}"
    fi

    if [ "$ENABLE_TRANSCRIPTION" = "true" ] && [ ! -f "$SCRIPT_DIR/bin/apple_speech" ]; then
        echo -e "${YELLOW}⚠️  Speech Recognition tool not found. Run './compile_apple_tools.sh' first${NC}"
    fi

    # Check if ffmpeg is available
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${YELLOW}⚠️  ffmpeg not found. Some features may not work properly${NC}"
    fi

    if [ $missing_tools -gt 0 ]; then
        echo -e "${RED}❌ Missing required tools. Please fix issues above.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo ""
    return 0
}

# Function to print summary
print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - PIPELINE_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo ""
    echo -e "${BLUE}📊 Pipeline Summary${NC}"
    echo "==================="
    echo ""
    echo "Total execution time: ${minutes}m ${seconds}s"
    echo "Steps completed: $((TOTAL_STEPS - STEP_ERRORS))/$TOTAL_STEPS"
    echo "Errors encountered: $STEP_ERRORS"
    echo ""

    if [ $STEP_ERRORS -eq 0 ]; then
        echo -e "${GREEN}🎉 Pipeline completed successfully!${NC}"
        echo ""
        echo "Your Rewind data has been processed and organized:"
        echo "📁 Video files: $VIDEO_MEETINGS_DIR & $VIDEO_SCREENSHOTS_DIR"
        echo "📄 OCR text: $OCR_OUTPUT_DIR"
        echo "🎤 Transcripts: $TRANSCRIPTS_OUTPUT_DIR"
        echo "🔍 Search indexes: $SEARCHABLE_INDEX_DIR"
        echo ""
        echo "Next steps:"
        echo "- Search your data using grep commands"
        echo "- Build semantic search capabilities"
        echo "- Set up SQLite database integration"
    else
        echo -e "${RED}⚠️  Pipeline completed with $STEP_ERRORS errors.${NC}"
        echo ""
        echo "Check individual script logs for details:"
        echo "- Video processing: $VIDEO_LOG_FILE"
        echo "- Audio transcription: $AUDIO_TRANSCRIPTION_LOG_FILE"
    fi

    echo ""
}

# Main execution
main() {
    # Handle help request
    if [[ "$1" = "--help" ]] || [[ "$1" = "-h" ]]; then
        print_usage
        exit 0
    fi

    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi

    # Run pipeline steps
    step1_copy_chunks "$@"
    step2_detect_meetings "$@"
    step3_extract_text "$@"
    step4_transcribe_audio "$@"

    # Print summary
    print_summary

    exit $STEP_ERRORS
}

# Run main function with all arguments
main "$@"