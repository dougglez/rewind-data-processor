#!/bin/bash

# setup.sh
#
# Quick setup script for Rewind Data Extraction Scripts
# This script helps configure the environment and test dependencies

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Rewind Data Extraction Scripts Setup${NC}"
echo "==========================================="
echo ""

# Function to check and install dependencies
check_dependencies() {
    echo -e "${YELLOW}📋 Checking dependencies...${NC}"

    # Check ffmpeg/ffprobe
    if command -v ffprobe &> /dev/null; then
        echo -e "${GREEN}✅ ffprobe is installed${NC}"
    else
        echo -e "${RED}❌ ffprobe not found${NC}"
        echo "   Video processing requires ffmpeg. Install with:"
        echo "   brew install ffmpeg"
        echo ""
        read -p "Would you like to install ffmpeg now? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v brew &> /dev/null; then
                echo "Installing ffmpeg..."
                brew install ffmpeg
            else
                echo -e "${RED}Homebrew not found. Please install ffmpeg manually.${NC}"
            fi
        fi
    fi

    # Check rsync
    if command -v rsync &> /dev/null; then
        echo -e "${GREEN}✅ rsync is available${NC}"
    else
        echo -e "${RED}❌ rsync not found (usually pre-installed on macOS)${NC}"
    fi

    echo ""
}

# Function to configure project settings
configure_project() {
    echo -e "${YELLOW}⚙️  Project Configuration${NC}"
    echo ""

    # Read current config if it exists
    local current_project_name="your_project_name"
    local current_external_drive="/Volumes/your_external_drive"

    if [ -f "$SCRIPT_DIR/config.sh" ]; then
        current_project_name=$(grep "PROJECT_NAME=" "$SCRIPT_DIR/config.sh" | cut -d'"' -f2)
        current_external_drive=$(grep "EXTERNAL_DRIVE=" "$SCRIPT_DIR/config.sh" | cut -d'"' -f2)
    fi

    echo "Current configuration:"
    echo "  Project name: $current_project_name"
    echo "  External drive: $current_external_drive"
    echo ""

    read -p "Would you like to update the configuration? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Enter your project name (e.g., 'my_rewind_data'): " new_project_name
        read -p "Enter your external drive path (e.g., '/Volumes/MyDrive'): " new_external_drive

        # Update config.sh
        sed -i.bak "s|PROJECT_NAME=\".*\"|PROJECT_NAME=\"$new_project_name\"|g" "$SCRIPT_DIR/config.sh"
        sed -i.bak "s|EXTERNAL_DRIVE=\".*\"|EXTERNAL_DRIVE=\"$new_external_drive\"|g" "$SCRIPT_DIR/config.sh"

        echo -e "${GREEN}✅ Configuration updated!${NC}"
        echo ""
    fi
}

# Function to make scripts executable
make_executable() {
    echo -e "${YELLOW}🔧 Making scripts executable...${NC}"
    chmod +x "$SCRIPT_DIR"/*.sh
    echo -e "${GREEN}✅ All scripts are now executable${NC}"
    echo ""
}

# Function to run basic tests
run_tests() {
    echo -e "${YELLOW}🧪 Running basic tests...${NC}"

    read -p "Would you like to run the video processing test? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Running video processing test..."
        if "$SCRIPT_DIR/test_video_processing.sh"; then
            echo -e "${GREEN}✅ Tests passed!${NC}"
        else
            echo -e "${RED}❌ Tests failed. Check the output above.${NC}"
        fi
    else
        echo "Skipping tests."
    fi
    echo ""
}

# Function to show usage information
show_usage() {
    echo -e "${BLUE}📚 Usage Information${NC}"
    echo "==================="
    echo ""
    echo "Available scripts:"
    echo "  • sync_audio_snippets.sh    - Sync audio snippets from Rewind"
    echo "  • organize_snippets.sh      - Organize local snippet directories"
    echo "  • process_video_chunks.sh   - Process video chunks to MP4 files"
    echo "  • backup_to_external.sh     - Backup data to external storage"
    echo "  • test_video_processing.sh  - Test video processing functionality"
    echo ""
    echo "Quick start:"
    echo "  1. Run './process_video_chunks.sh' to convert video chunks"
    echo "  2. Run './sync_audio_snippets.sh' to organize audio snippets"
    echo ""
    echo "For detailed documentation, see README.md"
    echo ""
}

# Function to check Rewind data directory
check_rewind_data() {
    echo -e "${YELLOW}📁 Checking Rewind data directories...${NC}"

    local rewind_dir="$HOME/Library/Application Support/com.memoryvault.MemoryVault"
    local chunks_dir="$rewind_dir/chunks"
    local snippets_dir="$rewind_dir/snippets"

    if [ -d "$rewind_dir" ]; then
        echo -e "${GREEN}✅ Rewind data directory found${NC}"

        if [ -d "$chunks_dir" ]; then
            local chunk_count=$(find "$chunks_dir" -type f | wc -l)
            echo -e "${GREEN}✅ Chunks directory found ($chunk_count files)${NC}"
        else
            echo -e "${YELLOW}⚠️  Chunks directory not found${NC}"
        fi

        if [ -d "$snippets_dir" ]; then
            local snippet_count=$(find "$snippets_dir" -type d -name "*T*" | wc -l)
            echo -e "${GREEN}✅ Snippets directory found ($snippet_count snippets)${NC}"
        else
            echo -e "${YELLOW}⚠️  Snippets directory not found${NC}"
        fi
    else
        echo -e "${RED}❌ Rewind data directory not found${NC}"
        echo "   Make sure Rewind.ai is installed and has been run at least once."
    fi
    echo ""
}

# Main setup flow
main() {
    check_dependencies
    check_rewind_data
    configure_project
    make_executable
    run_tests
    show_usage

    echo -e "${GREEN}🎉 Setup complete!${NC}"
    echo ""
    echo "You're ready to start processing your Rewind data!"
}

# Run setup
main "$@"