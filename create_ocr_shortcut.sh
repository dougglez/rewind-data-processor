#!/bin/bash

# create_ocr_shortcut.sh
#
# This script creates a macOS Shortcut for OCR that can be called from command line
# The shortcut uses Apple's built-in Vision framework for text recognition

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Setting up Apple OCR Shortcut${NC}"
echo "=================================="
echo ""

# Check if Shortcuts app is available
if ! command -v shortcuts &> /dev/null; then
    echo -e "${RED}❌ Shortcuts command not available${NC}"
    echo "This requires macOS Monterey (12.0) or later."
    exit 1
fi

# Check if shortcut already exists
if shortcuts list | grep -q "Extract Text CLI"; then
    echo -e "${YELLOW}⚠️  'Extract Text CLI' shortcut already exists${NC}"
    read -p "Would you like to recreate it? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing shortcut."
        exit 0
    fi
fi

echo -e "${YELLOW}📋 Creating OCR shortcut...${NC}"
echo ""
echo "This will open the Shortcuts app and create a new shortcut."
echo "Please follow these steps:"
echo ""
echo "1. The Shortcuts app will open"
echo "2. Create a new shortcut and name it 'Extract Text CLI'"
echo "3. Add these actions in order:"
echo "   a) 'Receive Any Input from Nowhere' (should appear automatically)"
echo "   b) 'Extract Text from Image'"
echo "   c) 'Get Text from Input' (optional, for better output)"
echo "   d) 'Copy to Clipboard' OR 'Output Text'"
echo ""
echo "4. Make sure the input flows: Input → Extract Text → Output"
echo ""

read -p "Press Enter to open Shortcuts app..." -r

# Open Shortcuts app
open -a "Shortcuts"

echo ""
echo "After creating the shortcut, test it with:"
echo -e "${GREEN}shortcuts run 'Extract Text CLI' -i /path/to/image.png${NC}"
echo ""

# Create a test function
cat > /tmp/test_ocr.sh << 'EOF'
#!/bin/bash

# Test the OCR shortcut
test_ocr() {
    local image_path="$1"

    if [ ! -f "$image_path" ]; then
        echo "❌ File not found: $image_path"
        return 1
    fi

    echo "🔍 Extracting text from: $(basename "$image_path")"

    # Try to extract text
    local extracted_text
    extracted_text=$(shortcuts run "Extract Text CLI" -i "$image_path" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$extracted_text" ]; then
        echo "✅ Text extracted successfully:"
        echo "---"
        echo "$extracted_text"
        echo "---"
        return 0
    else
        echo "❌ Failed to extract text"
        return 1
    fi
}

# Run test if image path provided
if [ $# -eq 1 ]; then
    test_ocr "$1"
else
    echo "Usage: $0 /path/to/image.png"
fi
EOF

chmod +x /tmp/test_ocr.sh

echo "Test script created at: /tmp/test_ocr.sh"
echo ""
echo -e "${GREEN}✅ Setup instructions provided!${NC}"
echo ""
echo "After creating the shortcut, you can test with any image file:"
echo -e "${BLUE}/tmp/test_ocr.sh /path/to/screenshot.png${NC}"