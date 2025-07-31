#!/bin/bash

# compile_apple_tools.sh
#
# Compiles Swift tools for OCR and speech recognition using Apple's frameworks
# Creates standalone executables that our bash scripts can use

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Compiling Apple Framework Tools${NC}"
echo "=================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script only works on macOS${NC}"
    exit 1
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift compiler not found${NC}"
    echo "Please install Xcode Command Line Tools:"
    echo "xcode-select --install"
    exit 1
fi

echo -e "${YELLOW}📋 Checking Swift compiler...${NC}"
swift --version

# Create bin directory if it doesn't exist
BIN_DIR="$SCRIPT_DIR/bin"
mkdir -p "$BIN_DIR"

echo ""
echo -e "${YELLOW}🔍 Compiling OCR tool...${NC}"

# Compile the OCR tool
if [ -f "$SCRIPT_DIR/apple_ocr.swift" ]; then
    echo "Compiling apple_ocr.swift..."
    if swiftc "$SCRIPT_DIR/apple_ocr.swift" -o "$BIN_DIR/apple_ocr" -framework Vision -framework CoreImage; then
        echo -e "${GREEN}✅ OCR tool compiled successfully${NC}"
        echo "   Location: $BIN_DIR/apple_ocr"
    else
        echo -e "${RED}❌ Failed to compile OCR tool${NC}"
        echo "Trying alternative compilation method..."

        # Alternative: Create a temporary Swift package
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        swift package init --type executable --name apple_ocr
        cp "$SCRIPT_DIR/apple_ocr.swift" Sources/apple_ocr/main.swift

        if swift build -c release; then
            cp .build/release/apple_ocr "$BIN_DIR/"
            echo -e "${GREEN}✅ OCR tool compiled successfully (via Swift Package)${NC}"
        else
            echo -e "${RED}❌ All OCR compilation methods failed${NC}"
        fi

        cd "$SCRIPT_DIR"
        rm -rf "$TEMP_DIR"
    fi
else
    echo -e "${YELLOW}⚠️  apple_ocr.swift not found, skipping${NC}"
fi

echo ""
echo -e "${YELLOW}🎤 Compiling Speech Recognition tool...${NC}"

# Compile the Speech Recognition tool
if [ -f "$SCRIPT_DIR/apple_speech.swift" ]; then
    echo "Compiling apple_speech.swift..."
    if swiftc "$SCRIPT_DIR/apple_speech.swift" -o "$BIN_DIR/apple_speech" -framework Speech -framework AVFoundation; then
        echo -e "${GREEN}✅ Speech Recognition tool compiled successfully${NC}"
        echo "   Location: $BIN_DIR/apple_speech"
    else
        echo -e "${RED}❌ Failed to compile Speech Recognition tool${NC}"
        echo "Trying alternative compilation method..."

        # Alternative: Create a temporary Swift package
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        swift package init --type executable --name apple_speech
        cp "$SCRIPT_DIR/apple_speech.swift" Sources/apple_speech/main.swift

        if swift build -c release; then
            cp .build/release/apple_speech "$BIN_DIR/"
            echo -e "${GREEN}✅ Speech Recognition tool compiled successfully (via Swift Package)${NC}"
        else
            echo -e "${RED}❌ All Speech Recognition compilation methods failed${NC}"
        fi

        cd "$SCRIPT_DIR"
        rm -rf "$TEMP_DIR"
    fi
else
    echo -e "${YELLOW}⚠️  apple_speech.swift not found, skipping${NC}"
fi

echo ""
echo -e "${YELLOW}🧪 Testing compiled tools...${NC}"

# Test OCR tool if it exists
if [ -f "$BIN_DIR/apple_ocr" ]; then
    echo "Testing OCR tool..."
    if "$BIN_DIR/apple_ocr" --help &>/dev/null; then
        echo -e "${GREEN}✅ OCR tool is functional${NC}"
    else
        echo -e "${YELLOW}⚠️  OCR tool compiled but may have issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  OCR tool not available${NC}"
fi

# Test Speech Recognition tool if it exists
if [ -f "$BIN_DIR/apple_speech" ]; then
    echo "Testing Speech Recognition tool..."
    if "$BIN_DIR/apple_speech" --help &>/dev/null; then
        echo -e "${GREEN}✅ Speech Recognition tool is functional${NC}"

        # Check permissions
        echo "Checking speech recognition permissions..."
        if "$BIN_DIR/apple_speech" --request-permission &>/dev/null; then
            echo -e "${GREEN}✅ Speech recognition permissions OK${NC}"
        else
            echo -e "${YELLOW}⚠️  Speech recognition may need permissions setup${NC}"
            echo "   Run: $BIN_DIR/apple_speech --request-permission"
        fi
    else
        echo -e "${YELLOW}⚠️  Speech Recognition tool compiled but may have issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Speech Recognition tool not available${NC}"
fi

echo ""
echo -e "${YELLOW}📝 Creating wrapper functions...${NC}"

# Create bash wrapper functions for both OCR and Speech
cat > "$SCRIPT_DIR/apple_vision_helpers.sh" << EOF
#!/bin/bash

# apple_vision_helpers.sh
#
# Helper functions for using Apple's Vision and Speech frameworks from bash

# Get the directory where this script is located
HELPERS_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="\$HELPERS_DIR/bin"

# OCR function using Apple's Vision framework
apple_ocr() {
    local image_path="\$1"

    if [ ! -f "\$image_path" ]; then
        echo "❌ Image file not found: \$image_path" >&2
        return 1
    fi

    # Try compiled Swift tool first
    if [ -f "\$BIN_DIR/apple_ocr" ]; then
        "\$BIN_DIR/apple_ocr" "\$image_path"
        return \$?
    fi

    # Fallback to Shortcuts if available
    if command -v shortcuts &> /dev/null; then
        if shortcuts list | grep -q "Extract Text CLI"; then
            shortcuts run "Extract Text CLI" -i "\$image_path" 2>/dev/null
            return \$?
        fi
    fi

    echo "❌ No OCR method available. Run setup scripts first." >&2
    return 1
}

# Speech Recognition function using Apple's Speech framework
apple_speech() {
    local audio_path="\$1"
    shift  # Remove first argument
    local additional_args="\$@"

    if [ ! -f "\$audio_path" ]; then
        echo "❌ Audio file not found: \$audio_path" >&2
        return 1
    fi

    # Try compiled Swift tool
    if [ -f "\$BIN_DIR/apple_speech" ]; then
        "\$BIN_DIR/apple_speech" "\$audio_path" \$additional_args
        return \$?
    fi

    echo "❌ No Speech Recognition tool available. Run setup scripts first." >&2
    return 1
}

# Function to check OCR availability
check_ocr_available() {
    if [ -f "\$BIN_DIR/apple_ocr" ]; then
        echo "✅ Native Swift OCR available"
        return 0
    elif command -v shortcuts &> /dev/null && shortcuts list | grep -q "Extract Text CLI"; then
        echo "✅ Shortcuts OCR available"
        return 0
    else
        echo "❌ No OCR method available"
        return 1
    fi
}

# Function to check Speech Recognition availability
check_speech_available() {
    if [ -f "\$BIN_DIR/apple_speech" ]; then
        echo "✅ Native Swift Speech Recognition available"
        return 0
    else
        echo "❌ No Speech Recognition method available"
        return 1
    fi
}

# Test function for OCR
test_apple_ocr() {
    local test_image="\$1"

    echo "🧪 Testing Apple OCR..."

    if [ -z "\$test_image" ]; then
        echo "Usage: test_apple_ocr /path/to/image.png"
        return 1
    fi

    check_ocr_available

    if [ \$? -eq 0 ]; then
        echo "Testing with: \$test_image"
        apple_ocr "\$test_image"
    fi
}

# Test function for Speech Recognition
test_apple_speech() {
    local test_audio="\$1"

    echo "🧪 Testing Apple Speech Recognition..."

    if [ -z "\$test_audio" ]; then
        echo "Usage: test_apple_speech /path/to/audio.wav"
        return 1
    fi

    check_speech_available

    if [ \$? -eq 0 ]; then
        echo "Testing with: \$test_audio"
        apple_speech "\$test_audio" --metadata
    fi
}

# Export functions for use in other scripts
export -f apple_ocr
export -f apple_speech
export -f check_ocr_available
export -f check_speech_available
export -f test_apple_ocr
export -f test_apple_speech
EOF

chmod +x "$SCRIPT_DIR/apple_vision_helpers.sh"

echo -e "${GREEN}✅ Helper functions created${NC}"
echo "   Location: $SCRIPT_DIR/apple_vision_helpers.sh"

echo ""
echo -e "${BLUE}📚 Usage Instructions${NC}"
echo "===================="
echo ""
echo "1. **OCR (Text from Images):**"
echo "   # Direct usage:"
echo "   $BIN_DIR/apple_ocr screenshot.png"
echo ""
echo "   # In other scripts:"
echo "   source $SCRIPT_DIR/apple_vision_helpers.sh"
echo "   apple_ocr \"/path/to/image.png\""
echo ""
echo "2. **Speech Recognition (Audio Transcription):**"
echo "   # Direct usage:"
echo "   $BIN_DIR/apple_speech recording.wav"
echo "   $BIN_DIR/apple_speech meeting.m4a --metadata --format json"
echo ""
echo "   # In other scripts:"
echo "   source $SCRIPT_DIR/apple_vision_helpers.sh"
echo "   apple_speech \"/path/to/audio.wav\" --metadata"
echo ""
echo "3. **Setup Shortcuts (alternative OCR method):**"
echo "   ./create_ocr_shortcut.sh"
echo ""
echo "4. **Test everything:**"
echo "   source $SCRIPT_DIR/apple_vision_helpers.sh"
echo "   test_apple_ocr /path/to/test_image.png"
echo "   test_apple_speech /path/to/test_audio.wav"
echo ""

# Check what tools were successfully compiled
COMPILED_TOOLS=0
if [ -f "$BIN_DIR/apple_ocr" ]; then
    ((COMPILED_TOOLS++))
fi
if [ -f "$BIN_DIR/apple_speech" ]; then
    ((COMPILED_TOOLS++))
fi

if [ $COMPILED_TOOLS -eq 2 ]; then
    echo -e "${GREEN}🎉 Setup complete! Both OCR and Speech Recognition tools ready to use.${NC}"
elif [ $COMPILED_TOOLS -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Partial setup completed. Check compilation errors above.${NC}"
else
    echo -e "${RED}❌ Setup completed with issues. Check compilation errors above.${NC}"
fi

echo ""
echo "Next steps:"
echo "- Test tools with sample files"
echo "- Run the modular video processing pipeline:"
echo "  1. ./copy_video_chunks.sh"
echo "  2. ./detect_meetings.sh"
echo "  3. ./extract_text_from_videos.sh"
echo "- Run audio transcription:"
echo "  4. ./transcribe_audio_snippets.sh"