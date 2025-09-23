#!/bin/bash

echo "=== Installing Tmux Plugin Manager (tpm) ==="

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is not installed. Please install git first:"
    echo "sudo apt update && sudo apt install -y git"
    exit 1
fi

# Create the plugins directory
mkdir -p "$HOME/.tmux/plugins"

# Remove existing tpm directory if it exists but is broken
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "Removing existing tpm directory..."
    rm -rf "$HOME/.tmux/plugins/tpm"
fi

# Clone tpm repository
echo "Cloning tpm repository..."
if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
    echo "✓ Successfully cloned tpm"
else
    echo "✗ Failed to clone tpm repository"
    exit 1
fi

# Make sure tpm script is executable
chmod +x "$HOME/.tmux/plugins/tpm/tpm"

# Verify installation
if [[ -x "$HOME/.tmux/plugins/tpm/tpm" ]]; then
    echo "✓ tpm is now installed and executable"
    echo "✓ You can now reload your tmux config: tmux source-file ~/.tmux.conf"
    echo "✓ To install plugins, press: Ctrl-B + I"
else
    echo "✗ Installation verification failed"
    exit 1
fi
