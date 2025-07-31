#!/bin/bash

# test_video_processing.sh
#
# Unit test for process_video_chunks.sh
# Creates mock chunk files and verifies processing works correctly

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test configuration
TEST_DIR="$HOME/Desktop/video_chunk_test"
MOCK_CHUNKS_DIR="$TEST_DIR/mock_chunks"
TEST_OUTPUT_DIR="$TEST_DIR/test_output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Log function
log() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

# Success function
success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

# Failure function
fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Create mock video files (using ffmpeg to create actual test videos)
create_mock_video() {
    local output_file="$1"
    local duration="${2:-2}"  # Default 2 seconds

    # Create a simple test video using ffmpeg if available
    if command -v ffmpeg &> /dev/null; then
        ffmpeg -f lavfi -i testsrc=duration=$duration:size=320x240:rate=0.5 \
               -pix_fmt yuv420p -y "$output_file" &>/dev/null
    else
        # If ffmpeg not available, create a dummy file that looks like video
        echo "MOCK_VIDEO_DATA_${duration}s" > "$output_file"
    fi
}

# Setup test environment
setup_test() {
    log "Setting up test environment..."

    # Clean up any existing test directory
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi

    # Create test directory structure
    mkdir -p "$MOCK_CHUNKS_DIR/202401/15"
    mkdir -p "$MOCK_CHUNKS_DIR/202401/16"
    mkdir -p "$TEST_OUTPUT_DIR"

    # Create mock chunk files with different timestamps
    log "Creating mock video files..."

    # Set specific timestamps for test files
    local test_time1=$(date -j -f "%Y-%m-%d %H:%M:%S" "2024-01-15 14:30:00" "+%s" 2>/dev/null || echo "1705339800")
    local test_time2=$(date -j -f "%Y-%m-%d %H:%M:%S" "2024-01-15 14:32:00" "+%s" 2>/dev/null || echo "1705339920")
    local test_time3=$(date -j -f "%Y-%m-%d %H:%M:%S" "2024-01-16 09:15:00" "+%s" 2>/dev/null || echo "1705408500")

    # Create mock video files
    create_mock_video "$MOCK_CHUNKS_DIR/202401/15/chunk001" 3
    create_mock_video "$MOCK_CHUNKS_DIR/202401/15/chunk002" 2
    create_mock_video "$MOCK_CHUNKS_DIR/202401/16/chunk001" 4

    # Set timestamps on files
    touch -t "$(date -r $test_time1 '+%Y%m%d%H%M.%S')" "$MOCK_CHUNKS_DIR/202401/15/chunk001" 2>/dev/null || true
    touch -t "$(date -r $test_time2 '+%Y%m%d%H%M.%S')" "$MOCK_CHUNKS_DIR/202401/15/chunk002" 2>/dev/null || true
    touch -t "$(date -r $test_time3 '+%Y%m%d%H%M.%S')" "$MOCK_CHUNKS_DIR/202401/16/chunk001" 2>/dev/null || true

    success "Test environment created"
}

# Test that dependencies are available
test_dependencies() {
    log "Testing dependencies..."

    if command -v ffprobe &> /dev/null; then
        success "ffprobe is available"
    else
        fail "ffprobe not found - video processing will not work properly"
    fi

    if command -v rsync &> /dev/null; then
        success "rsync is available"
    else
        fail "rsync not found"
    fi
}

# Test the video processing script with mock data
test_video_processing() {
    log "Testing video processing with mock data..."

    # Temporarily override config for testing
    export REWIND_CHUNKS_DIR="$MOCK_CHUNKS_DIR"
    export CHUNKS_TEST_DIR="$TEST_DIR/chunks_copy"
    export VIDEO_OUTPUT_DIR="$TEST_OUTPUT_DIR"
    export VIDEO_LOG_FILE="$TEST_DIR/test_video.log"

    # Create a test config file
    cat > "$TEST_DIR/test_config.sh" << EOF
#!/bin/bash
PROJECT_NAME="test_project"
REWIND_CHUNKS_DIR="$MOCK_CHUNKS_DIR"
CHUNKS_TEST_DIR="$TEST_DIR/chunks_copy"
VIDEO_OUTPUT_DIR="$TEST_OUTPUT_DIR"
VIDEO_LOG_FILE="$TEST_DIR/test_video.log"
EOF

    # Create a modified version of the script for testing
    sed "s|source \"\$SCRIPT_DIR/config.sh\"|source \"$TEST_DIR/test_config.sh\"|g" \
        "$SCRIPT_DIR/process_video_chunks.sh" > "$TEST_DIR/test_process_chunks.sh"

    chmod +x "$TEST_DIR/test_process_chunks.sh"

    # Run the test (capture output to check for errors)
    if "$TEST_DIR/test_process_chunks.sh" > "$TEST_DIR/test_output.log" 2>&1; then
        success "Video processing script executed without errors"
    else
        fail "Video processing script failed - check $TEST_DIR/test_output.log"
        return 1
    fi
}

# Verify output files were created correctly
test_output_verification() {
    log "Verifying output files..."

    # Check if output directory structure was created
    if [ -d "$TEST_OUTPUT_DIR" ]; then
        success "Output directory created"
    else
        fail "Output directory not created"
        return 1
    fi

    # Count output files
    local output_files
    output_files=$(find "$TEST_OUTPUT_DIR" -name "*.mp4" 2>/dev/null | wc -l)

    if [ "$output_files" -gt 0 ]; then
        success "Found $output_files processed video files"
    else
        fail "No processed video files found"
        return 1
    fi

    # Check file naming pattern
    local sample_file
    sample_file=$(find "$TEST_OUTPUT_DIR" -name "*.mp4" | head -1)

    if [ -n "$sample_file" ]; then
        local filename
        filename=$(basename "$sample_file")

        if [[ "$filename" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}_to_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.mp4$ ]]; then
            success "File naming pattern is correct: $filename"
        else
            fail "File naming pattern is incorrect: $filename"
        fi
    fi
}

# Clean up test environment
cleanup_test() {
    log "Cleaning up test environment..."

    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        success "Test environment cleaned up"
    fi
}

# Print test summary
print_test_summary() {
    echo ""
    echo "=== TEST SUMMARY ==="
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed.${NC}"
        return 1
    fi
}

# Main test execution
main() {
    echo "=== VIDEO CHUNK PROCESSING UNIT TEST ==="
    echo ""

    setup_test
    test_dependencies
    test_video_processing
    test_output_verification
    cleanup_test

    print_test_summary
}

# Run tests
main "$@"