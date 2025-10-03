#!/bin/bash

# fzf-preview.sh - Intelligent preview script for fzf
# Handles files and directories with appropriate preview methods

file="$1"

# Check if file exists
if [[ ! -e "$file" ]]; then
    echo "File not found: $file"
    exit 0
fi

# If it's a directory, show tree structure
if [[ -d "$file" ]]; then
    if command -v eza >/dev/null 2>&1; then
        eza --tree --icons --level=3 --color=always "$file" 2>/dev/null | head -50
    elif command -v tree >/dev/null 2>&1; then
        tree -C -L 3 "$file" 2>/dev/null | head -50
    else
        ls -la "$file" 2>/dev/null
    fi
    exit 0
fi

# If it's a regular file, determine how to preview it
if [[ -f "$file" ]]; then
    # Get file size in bytes
    if [[ "$OSTYPE" == "darwin"* ]]; then
        file_size=$(stat -f%z "$file" 2>/dev/null || echo 0)
    else
        file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    fi
    
    # Don't preview very large files (>10MB)
    if [[ $file_size -gt 10485760 ]]; then
        echo "File too large to preview ($(($file_size / 1024 / 1024))MB)"
        echo "Type: $(file "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
        exit 0
    fi
    
    # Get file type
    mime_type=""
    if command -v file >/dev/null 2>&1; then
        mime_type=$(file --mime-type "$file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
    fi
    
    # Try bat first for text files and code
    if command -v bat >/dev/null 2>&1; then
        # Let bat auto-detect and handle most files
        if bat --color=always --style=numbers --line-range=:500 "$file" 2>/dev/null; then
            exit 0
        fi
    fi
    
    # Handle binary files
    case "$mime_type" in
        *image*)
            echo "🖼️  Image file: $(basename "$file")"
            if command -v identify >/dev/null 2>&1; then
                identify "$file" 2>/dev/null
            else
                echo "Size: $(($file_size / 1024))KB"
            fi
            ;;
        *pdf*)
            echo "📄 PDF file: $(basename "$file")"
            echo "Size: $(($file_size / 1024))KB"
            if command -v pdfinfo >/dev/null 2>&1; then
                pdfinfo "$file" 2>/dev/null | head -20
            fi
            ;;
        *audio*)
            echo "🎵 Audio file: $(basename "$file")"
            echo "Size: $(($file_size / 1024))KB"
            ;;
        *video*)
            echo "🎬 Video file: $(basename "$file")"
            echo "Size: $(($file_size / 1024 / 1024))MB"
            ;;
        *zip*|*archive*|*compressed*)
            echo "📦 Archive file: $(basename "$file")"
            echo "Size: $(($file_size / 1024))KB"
            if command -v unzip >/dev/null 2>&1 && [[ "$file" == *.zip ]]; then
                echo -e "\nContents:"
                unzip -l "$file" 2>/dev/null | head -20
            fi
            ;;
        *)
            # Fallback: try to show as text, but safely
            if [[ $file_size -lt 1048576 ]]; then  # Less than 1MB
                # Check if it's mostly text
                if file "$file" 2>/dev/null | grep -q text; then
                    cat "$file" 2>/dev/null | head -100
                else
                    echo "Binary file: $(basename "$file")"
                    echo "Size: $(($file_size / 1024))KB"
                    echo "Type: $(file "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
                    echo -e "\nHex dump (first 256 bytes):"
                    xxd "$file" 2>/dev/null | head -16
                fi
            else
                echo "Large file: $(basename "$file")"
                echo "Size: $(($file_size / 1024))KB"
                echo "Type: $(file "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
            fi
            ;;
    esac
fi
