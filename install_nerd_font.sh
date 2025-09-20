#!/bin/bash

# Nerd Fonts Installation Script
# Downloads and installs JetBrains Mono Nerd Font from the latest release

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define the font and the base URL for the latest release on GitHub
FONT_NAME="JetBrainsMono"
BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
FONT_URL="${BASE_URL}/${FONT_NAME}.zip"

# Function to detect OS and set appropriate font directory
detect_font_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        FONT_DIR="$HOME/Library/Fonts"
        OS_TYPE="macos"
    else
        # Linux
        FONT_DIR="$HOME/.local/share/fonts"
        OS_TYPE="linux"
    fi
}

# Function to check if JetBrains Mono Nerd Font is already installed
check_nerd_font_installed() {
    echo -e "${CYAN}Checking if JetBrains Mono Nerd Font is already installed...${NC}"
    
    # Check for Nerd Font specific files
    local nerd_font_patterns=(
        "*JetBrains*Mono*Nerd*Font*.ttf"
        "*JetBrainsMono*NF*.ttf"
        "*JetBrainsMonoNL*NF*.ttf"
    )
    
    for pattern in "${nerd_font_patterns[@]}"; do
        if ls "$FONT_DIR"/$pattern >/dev/null 2>&1; then
            echo -e "${GREEN}✓ JetBrains Mono Nerd Font is already installed${NC}"
            return 0
        fi
    done
    
    # Also check using fc-list if available (Linux)
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list | grep -i "jetbrains.*mono.*nerd\|jetbrainsmono.*nf" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ JetBrains Mono Nerd Font is already installed${NC}"
            return 0
        fi
    fi
    
    return 1
}

# Function to install JetBrains Mono Nerd Font
install_jetbrains_nerd_font() {
    echo -e "${BLUE}=== Installing JetBrains Mono Nerd Font ===${NC}"
    
    # Detect OS and set font directory
    detect_font_dir
    
    # Check if already installed
    if check_nerd_font_installed; then
        return 0
    fi
    
    # Create the font directory if it doesn't exist
    mkdir -p "$FONT_DIR"
    
    # Check if the font directory exists
    if [ ! -d "$FONT_DIR" ]; then
        echo -e "${RED}✗ Error: Could not create font directory at $FONT_DIR${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Downloading the latest version of ${FONT_NAME} Nerd Font...${NC}"
    
    # Create temporary directory for download
    local temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/${FONT_NAME}.zip"
    
    # Download the font using wget or curl with the latest release URL
    if command -v curl >/dev/null 2>&1; then
        echo -e "${CYAN}Using curl to download...${NC}"
        if curl -o "$zip_file" -L "$FONT_URL" --progress-bar; then
            echo -e "${GREEN}✓ Download completed${NC}"
        else
            echo -e "${RED}✗ Download failed with curl${NC}"
            rm -rf "$temp_dir"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        echo -e "${CYAN}Using wget to download...${NC}"
        if wget -q --show-progress "$FONT_URL" -O "$zip_file"; then
            echo -e "${GREEN}✓ Download completed${NC}"
        else
            echo -e "${RED}✗ Download failed with wget${NC}"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        echo -e "${RED}✗ Error: wget or curl is required to download the font.${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check if the download was successful
    if [ ! -f "$zip_file" ]; then
        echo -e "${RED}✗ Error: Download failed. The font might not be available at the specified URL.${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${CYAN}Extracting font files...${NC}"
    
    # Check if unzip is available
    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "${RED}✗ Error: unzip command is required to extract the font.${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Create extraction directory
    local extract_dir="$temp_dir/extracted"
    mkdir -p "$extract_dir"
    
    # Unzip the contents to the extraction directory
    if unzip -q "$zip_file" -d "$extract_dir"; then
        echo -e "${GREEN}✓ Font files extracted${NC}"
    else
        echo -e "${RED}✗ Error: Failed to extract font files${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Copy only .ttf files to the font directory
    echo -e "${CYAN}Installing font files to $FONT_DIR...${NC}"
    local font_count=0
    while IFS= read -r -d '' font_file; do
        cp "$font_file" "$FONT_DIR/"
        font_count=$((font_count + 1))
    done < <(find "$extract_dir" -name "*.ttf" -print0)
    
    if [ $font_count -eq 0 ]; then
        echo -e "${RED}✗ Error: No .ttf font files found in the archive${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${GREEN}✓ Installed $font_count font files${NC}"
    
    # Clean up the temporary directory
    rm -rf "$temp_dir"
    
    # Update font cache based on OS
    if [[ "$OS_TYPE" == "linux" ]]; then
        echo -e "${CYAN}Updating font cache...${NC}"
        if command -v fc-cache >/dev/null 2>&1; then
            if fc-cache -f -v >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Font cache updated${NC}"
            else
                echo -e "${YELLOW}⚠ Warning: Failed to update font cache${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Warning: fc-cache not available, font cache not updated${NC}"
        fi
    else
        echo -e "${CYAN}ℹ macOS will automatically detect the new fonts${NC}"
    fi
    
    echo -e "${GREEN}✓ Latest ${FONT_NAME} Nerd Font installed successfully!${NC}"
    echo -e "${CYAN}ℹ You may need to restart applications to see the new font${NC}"
    echo -e "${CYAN}ℹ Recommended settings: Font size 13, Line spacing 1.2${NC}"
    
    return 0
}

# Function to provide manual installation instructions
install_nerd_font_manual() {
    echo -e "${CYAN}Manual JetBrains Mono Nerd Font installation:${NC}"
    echo -e "${CYAN}Automatic installation failed. Please install manually:${NC}"
    echo
    echo -e "${YELLOW}Manual Installation Steps:${NC}"
    echo -e "${CYAN}1. Visit: https://github.com/ryanoasis/nerd-fonts/releases/latest${NC}"
    echo -e "${CYAN}2. Download JetBrainsMono.zip${NC}"
    echo -e "${CYAN}3. Extract the archive${NC}"
    echo -e "${CYAN}4. Install the font files:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${CYAN}   • Select all .ttf files and double-click 'Install Font'${NC}"
        echo -e "${CYAN}   • Or drag them to Font Book${NC}"
    else
        echo -e "${CYAN}   • Copy .ttf files to ~/.local/share/fonts/${NC}"
        echo -e "${CYAN}   • Run: fc-cache -f -v${NC}"
    fi
    echo -e "${CYAN}5. Restart your terminal/IDE${NC}"
    echo -e "${CYAN}6. Set font to 'JetBrainsMono Nerd Font' with size 13${NC}"
    echo
    echo -e "${YELLOW}⚠ Nerd Fonts provide better icon and symbol support for development${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    if install_jetbrains_nerd_font; then
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    else
        echo -e "${RED}❌ Installation failed!${NC}"
        install_nerd_font_manual
        exit 1
    fi
fi
