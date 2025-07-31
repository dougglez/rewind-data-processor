#!/bin/bash

# demo_apple_ocr.sh
#
# Demo script showcasing Apple's OCR capabilities with our Rewind processing tools
# This creates test scenarios and demonstrates text extraction from images

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helpers if available
if [ -f "$SCRIPT_DIR/apple_vision_helpers.sh" ]; then
    source "$SCRIPT_DIR/apple_vision_helpers.sh"
fi

echo -e "${BLUE}🍎 Apple OCR Demo for Rewind Data Extraction${NC}"
echo "=============================================="
echo ""

# Function to create a test image with text
create_test_image() {
    local output_file="$1"
    local text="$2"

    # Create a simple image with text using Apple's built-in tools
    if command -v sips &> /dev/null && command -v textutil &> /dev/null; then
        # Create a simple white background image
        # This is a placeholder - in practice we'd use a real screenshot
        echo "Creating test image: $output_file"
        echo "Text content: $text"

        # For demo purposes, we'll just note that this would create an image
        echo -e "${YELLOW}📝 (In real usage, this would be a Rewind screenshot)${NC}"
    fi
}

# Demo OCR capabilities
demo_ocr_methods() {
    echo -e "${CYAN}🔍 OCR Capabilities Demo${NC}"
    echo "========================"
    echo ""

    # Check available OCR methods
    echo "Checking available OCR methods..."
    echo ""

    # Check Swift OCR tool
    if [ -f "$SCRIPT_DIR/bin/apple_ocr" ]; then
        echo -e "${GREEN}✅ Native Swift OCR tool available${NC}"
        echo "   Location: $SCRIPT_DIR/bin/apple_ocr"
        echo "   Method: Direct Vision framework access"
        echo "   Performance: Excellent"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Native Swift OCR tool not found${NC}"
        echo "   Run './compile_apple_tools.sh' to compile it"
        echo ""
    fi

    # Check Shortcuts OCR
    if command -v shortcuts &> /dev/null; then
        if shortcuts list | grep -q "Extract Text CLI"; then
            echo -e "${GREEN}✅ Shortcuts OCR available${NC}"
            echo "   Method: macOS Shortcuts with Vision framework"
            echo "   Performance: Good"
            echo ""
        else
            echo -e "${YELLOW}⚠️  Shortcuts OCR not configured${NC}"
            echo "   Run './create_ocr_shortcut.sh' to set it up"
            echo ""
        fi
    else
        echo -e "${RED}❌ Shortcuts command not available${NC}"
        echo "   Requires macOS Monterey (12.0) or later"
        echo ""
    fi

    # Check helper functions
    if command -v apple_ocr &> /dev/null; then
        echo -e "${GREEN}✅ Helper functions loaded${NC}"
        echo "   Auto-detection: Available"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Helper functions not loaded${NC}"
        echo ""
    fi
}

# Demo realistic use cases
demo_use_cases() {
    echo -e "${CYAN}💼 Realistic Use Cases${NC}"
    echo "====================="
    echo ""

    echo "1. **Meeting Screenshots**"
    echo "   - Extract participant names from video calls"
    echo "   - Capture slide text and presentation content"
    echo "   - Index discussion topics and action items"
    echo ""

    echo "2. **Code Review Screenshots**"
    echo "   - Extract code snippets and function names"
    echo "   - Capture bug reports and issue numbers"
    echo "   - Index documentation and comments"
    echo ""

    echo "3. **Document Screenshots**"
    echo "   - Extract text from PDFs and documents"
    echo "   - Capture email content and addresses"
    echo "   - Index file names and folder structures"
    echo ""

    echo "4. **Web Browsing Screenshots**"
    echo "   - Capture article titles and content"
    echo "   - Extract URLs and link text"
    echo "   - Index search queries and results"
    echo ""
}

# Demo integration with video processing
demo_integration() {
    echo -e "${CYAN}🎬 Integration with Video Processing${NC}"
    echo "==================================="
    echo ""

    echo "The OCR functionality integrates seamlessly with video chunk processing:"
    echo ""

    echo -e "${YELLOW}Processing Flow:${NC}"
    echo "1. Copy Rewind chunks to desktop (safe testing)"
    echo "2. Convert each chunk to MP4 with timestamp naming"
    echo "3. Extract one frame from each video chunk"
    echo "4. Run Apple OCR on the extracted frame"
    echo "5. Save extracted text to matching .txt file"
    echo "6. Build searchable index of all text"
    echo ""

    echo -e "${YELLOW}Example Output:${NC}"
    echo "  video/processed/2024-01-15/2024-01-15_14-30-00_to_2024-01-15_14-32-15.mp4"
    echo "  video/ocr_text/2024-01-15/2024-01-15_14-30-00_to_2024-01-15_14-32-15.txt"
    echo ""

    echo -e "${YELLOW}Search Capabilities:${NC}"
    echo "  # Find all chunks containing 'meeting'"
    echo "  grep -r 'meeting' ~/project/video/ocr_text/"
    echo ""
    echo "  # Search for specific person's name"
    echo "  grep -r 'John Smith' ~/project/video/ocr_text/"
    echo ""
    echo "  # Find code-related screenshots"
    echo "  grep -r 'function\\|class\\|import' ~/project/video/ocr_text/"
    echo ""
}

# Demo privacy and performance benefits
demo_benefits() {
    echo -e "${CYAN}🔒 Privacy & Performance Benefits${NC}"
    echo "================================="
    echo ""

    echo -e "${GREEN}✅ Privacy Advantages:${NC}"
    echo "  • 100% offline processing - no data sent to cloud"
    echo "  • No API keys or accounts required"
    echo "  • Apple's on-device privacy guarantees"
    echo "  • No usage tracking or data collection"
    echo ""

    echo -e "${GREEN}✅ Performance Advantages:${NC}"
    echo "  • Native Apple Silicon optimization"
    echo "  • No network latency or bandwidth usage"
    echo "  • Unlimited processing - no rate limits"
    echo "  • Instant results with no API delays"
    echo ""

    echo -e "${GREEN}✅ Cost Advantages:${NC}"
    echo "  • No per-request charges"
    echo "  • No subscription fees"
    echo "  • No usage limits or quotas"
    echo "  • One-time setup, unlimited use"
    echo ""

    echo -e "${GREEN}✅ Accuracy Advantages:${NC}"
    echo "  • Optimized for macOS screenshot formats"
    echo "  • Automatic language detection"
    echo "  • Context-aware text recognition"
    echo "  • Handles various text sizes and fonts"
    echo ""
}

# Show next steps
show_next_steps() {
    echo -e "${CYAN}🚀 Next Steps${NC}"
    echo "============="
    echo ""

    echo "1. **Setup OCR Tools:**"
    echo "   ./compile_apple_tools.sh     # Compile native Swift tools"
    echo "   ./create_ocr_shortcut.sh     # OR setup Shortcuts method"
    echo ""

    echo "2. **Test with Real Data:**"
    echo "   ./process_video_chunks_with_ocr.sh    # Process chunks with OCR"
    echo ""

    echo "3. **Explore Results:**"
    echo "   ls ~/your_project/video/ocr_text/     # Browse extracted text"
    echo "   grep -r 'keyword' ~/your_project/video/ocr_text/  # Search text"
    echo ""

    echo "4. **Future Enhancements:**"
    echo "   • Semantic search with vector embeddings"
    echo "   • Meeting detection using OCR + audio timestamps"
    echo "   • SQLite database for advanced querying"
    echo "   • Speech transcription integration"
    echo ""
}

# Main demo execution
main() {
    demo_ocr_methods
    demo_use_cases
    demo_integration
    demo_benefits
    show_next_steps

    echo -e "${GREEN}🎉 Apple OCR Demo Complete!${NC}"
    echo ""
    echo "Ready to extract searchable text from your Rewind screenshots!"
    echo ""
    echo "Questions or issues? Check the README.md for detailed documentation."
}

# Run the demo
main "$@"