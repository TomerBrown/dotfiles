#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art for TOMER BROWN
print_ascii_art() {
    echo -e "${PURPLE}"
    cat << "EOF"
████████╗ ██████╗ ███╗   ███╗███████╗██████╗     ██████╗ ██████╗  ██████╗ ██╗    ██╗███╗   ██╗
╚══██╔══╝██╔═══██╗████╗ ████║██╔════╝██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗██║    ██║████╗  ██║
   ██║   ██║   ██║██╔████╔██║█████╗  ██████╔╝    ██████╔╝██████╔╝██║   ██║██║ █╗ ██║██╔██╗ ██║
   ██║   ██║   ██║██║╚██╔╝██║██╔══╝  ██╔══██╗    ██╔══██╗██╔══██╗██║   ██║██║███╗██║██║╚██╗██║
   ██║   ╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██║    ██████╔╝██║  ██║╚██████╔╝╚███╔███╔╝██║ ╚████║
   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝
                                                                                                  
                    🚀 Dotfiles Setup Script 🚀
EOF
    echo -e "${NC}"
}

# Function to ask yes/no questions
ask_yes_no() {
    local question="$1"
    local default="${2:-y}"
    
    if [[ $default == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    while true; do
        echo -e "${CYAN}$question $prompt: ${NC}"
        read -r response
        
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo -e "${RED}Please answer yes or no.${NC}"
                ;;
        esac
    done
}

# Function to detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        if command -v brew >/dev/null 2>&1; then
            PKG_MANAGER="brew"
        else
            echo -e "${YELLOW}Homebrew not found. Please install it first: https://brew.sh${NC}"
            PKG_MANAGER=""
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt >/dev/null 2>&1; then
            OS="debian"
            PKG_MANAGER="apt"
        elif command -v yum >/dev/null 2>&1; then
            OS="redhat"
            PKG_MANAGER="yum"
        elif command -v pacman >/dev/null 2>&1; then
            OS="arch"
            PKG_MANAGER="pacman"
        else
            echo -e "${RED}Unsupported Linux distribution${NC}"
            PKG_MANAGER=""
        fi
    else
        echo -e "${RED}Unsupported operating system${NC}"
        PKG_MANAGER=""
    fi
    
    echo -e "${GREEN}Detected OS: $OS, Package Manager: $PKG_MANAGER${NC}"
}

# Function to check if a package is installed
is_package_installed() {
    local package="$1"
    
    case "$PKG_MANAGER" in
        "brew")
            brew list "$package" >/dev/null 2>&1
            ;;
        "apt")
            dpkg -l | grep -q "^ii  $package "
            ;;
        "yum")
            yum list installed "$package" >/dev/null 2>&1
            ;;
        "pacman")
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to install packages
install_package() {
    local package="$1"
    
    if is_package_installed "$package"; then
        echo -e "${GREEN}✓ $package is already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing $package...${NC}"
    
    case "$PKG_MANAGER" in
        "brew")
            brew install "$package"
            ;;
        "apt")
            sudo apt update && sudo apt install -y "$package"
            ;;
        "yum")
            sudo yum install -y "$package"
            ;;
        "pacman")
            sudo pacman -S --noconfirm "$package"
            ;;
        *)
            echo -e "${RED}Cannot install $package: unsupported package manager${NC}"
            return 1
            ;;
    esac
}

# Function to change default shell to zsh
change_shell_to_zsh() {
    echo -e "${BLUE}=== Changing Default Shell to Zsh ===${NC}"
    
    if [[ "$SHELL" == */zsh ]]; then
        echo -e "${GREEN}✓ Zsh is already your default shell${NC}"
        return 0
    fi
    
    if ! command -v zsh >/dev/null 2>&1; then
        echo -e "${YELLOW}Zsh not found. Installing zsh first...${NC}"
        install_package "zsh"
    fi
    
    local zsh_path
    zsh_path=$(which zsh)
    
    if ! grep -q "$zsh_path" /etc/shells; then
        echo -e "${YELLOW}Adding zsh to /etc/shells...${NC}"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    echo -e "${YELLOW}Changing default shell to zsh...${NC}"
    chsh -s "$zsh_path"
    
    echo -e "${GREEN}✓ Default shell changed to zsh (will take effect on next login)${NC}"
}

# Function to initialize Zinit
initialize_zinit() {
    echo -e "${BLUE}=== Initializing Zinit ===${NC}"
    
    if [[ -d "$HOME/.local/share/zinit/zinit.git" ]]; then
        echo -e "${GREEN}✓ Zinit is already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing Zinit...${NC}"
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
    
    echo -e "${GREEN}✓ Zinit installed successfully${NC}"
}

# Function to install required packages
install_packages() {
    echo -e "${BLUE}=== Installing Required Packages ===${NC}"
    
    local packages=("tmux" "fzf" "bat")
    
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Special handling for oh-my-posh
    if ! command -v oh-my-posh >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing oh-my-posh...${NC}"
        case "$PKG_MANAGER" in
            "brew")
                brew install jandedobbeleer/oh-my-posh/oh-my-posh
                ;;
            "apt")
                sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
                sudo chmod +x /usr/local/bin/oh-my-posh
                ;;
            *)
                echo -e "${YELLOW}Please install oh-my-posh manually for your system${NC}"
                ;;
        esac
    else
        echo -e "${GREEN}✓ oh-my-posh is already installed${NC}"
    fi
    
    # Install JetBrains Mono Nerd Font
    install_jetbrains_font
}

# Function to install Tmux Plugin Manager (tpm)
install_tpm() {
    echo -e "${BLUE}=== Installing Tmux Plugin Manager (tpm) ===${NC}"
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ -d "$tpm_dir" ]]; then
        echo -e "${GREEN}✓ Tmux Plugin Manager (tpm) is already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing Tmux Plugin Manager (tpm)...${NC}"
    
    # Create the plugins directory if it doesn't exist
    mkdir -p "$HOME/.tmux/plugins"
    
    # Clone tpm repository
    if git clone https://github.com/tmux-plugins/tpm "$tpm_dir"; then
        echo -e "${GREEN}✓ Successfully installed Tmux Plugin Manager (tpm)${NC}"
        echo -e "${CYAN}ℹ After tmux configuration is loaded, you can install plugins by pressing prefix + I (Ctrl-B + I by default)${NC}"
    else
        echo -e "${RED}✗ Failed to install Tmux Plugin Manager (tpm)${NC}"
        echo -e "${YELLOW}⚠ You can install it manually by running:${NC}"
        echo -e "${CYAN}  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm${NC}"
        return 1
    fi
}

# Function to install JetBrains Mono Nerd Font
install_jetbrains_font() {
    echo -e "${YELLOW}Checking JetBrains Mono Nerd Font...${NC}"
    
    case "$PKG_MANAGER" in
        "brew")
            # Check if font is already installed
            if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
                echo -e "${GREEN}✓ JetBrains Mono Nerd Font is already installed${NC}"
                return 0
            fi
            
            # Install the font via Homebrew
            echo -e "${YELLOW}Installing JetBrains Mono Nerd Font via Homebrew...${NC}"
            if brew install --cask font-jetbrains-mono-nerd-font; then
                echo -e "${GREEN}✓ Successfully installed JetBrains Mono Nerd Font${NC}"
            else
                echo -e "${RED}✗ Failed to install JetBrains Mono Nerd Font via Homebrew${NC}"
                install_jetbrains_font_manual
            fi
            ;;
        "apt")
            # For Linux, we'll download and install manually
            echo -e "${YELLOW}Installing JetBrains Mono Nerd Font manually (Linux)...${NC}"
            install_jetbrains_font_manual
            ;;
        *)
            echo -e "${YELLOW}Unsupported package manager for font installation${NC}"
            install_jetbrains_font_manual
            ;;
    esac
}

# Function to manually install JetBrains Mono Nerd Font
install_jetbrains_font_manual() {
    echo -e "${CYAN}Manual JetBrains Mono Nerd Font installation:${NC}"
    
    # Check if font might already be installed by looking for common paths
    local font_paths=(
        "/System/Library/Fonts/JetBrainsMono*.ttf"
        "/Library/Fonts/JetBrainsMono*.ttf"
        "$HOME/Library/Fonts/JetBrainsMono*.ttf"
        "$HOME/.local/share/fonts/JetBrainsMono*.ttf"
        "$HOME/.fonts/JetBrainsMono*.ttf"
    )
    
    local font_found=false
    for path in "${font_paths[@]}"; do
        if ls $path >/dev/null 2>&1; then
            echo -e "${GREEN}✓ JetBrains Mono font appears to be already installed${NC}"
            font_found=true
            break
        fi
    done
    
    if [[ "$font_found" == false ]]; then
        echo -e "${CYAN}JetBrains Mono Nerd Font not found. Please install it manually:${NC}"
        echo -e "${CYAN}1. Visit: https://github.com/ryanoasis/nerd-fonts/releases${NC}"
        echo -e "${CYAN}2. Download: JetBrainsMono.zip${NC}"
        echo -e "${CYAN}3. Extract and install the .ttf files${NC}"
        echo -e "${CYAN}   - macOS: Double-click .ttf files and click 'Install'${NC}"
        echo -e "${CYAN}   - Linux: Copy to ~/.local/share/fonts/ and run 'fc-cache -fv'${NC}"
        echo -e "${YELLOW}⚠ This font is required for your Ghostty terminal configuration${NC}"
    fi
}

# Function to handle a single symlink
create_single_symlink() {
    local source="$1"
    local target="$2"
    local filename=$(basename "$target")
    
    if [[ -L "$target" ]]; then
        local current_link=$(readlink "$target")
        if [[ "$current_link" == "$source" ]]; then
            echo -e "${GREEN}✓ Correct symlink already exists: $target${NC}"
        else
            echo -e "${YELLOW}⚠ Symlink exists but points to different location: $target -> $current_link${NC}"
            if ask_yes_no "Do you want to update the symlink to point to $source?"; then
                ln -sf "$source" "$target"
                echo -e "${GREEN}✓ Updated symlink: $target -> $source${NC}"
            else
                echo -e "${YELLOW}⚠ Skipped updating: $target${NC}"
            fi
        fi
    elif [[ -e "$target" ]]; then
        echo -e "${YELLOW}⚠ File/directory already exists: $target${NC}"
        echo -e "${CYAN}   Current: $(ls -la "$target" | awk '{print $1, $3, $4, $5, $6, $7, $8, $9}')${NC}"
        echo -e "${CYAN}   Will be replaced with symlink to: $source${NC}"
        
        if ask_yes_no "Do you want to backup the existing $filename and create a symlink?" "n"; then
            local backup_name="${target}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$target" "$backup_name"
            ln -sf "$source" "$target"
            echo -e "${GREEN}✓ Backed up to: $backup_name${NC}"
            echo -e "${GREEN}✓ Created symlink: $target -> $source${NC}"
        else
            echo -e "${YELLOW}⚠ Skipped: $target (existing file preserved)${NC}"
        fi
    else
        ln -sf "$source" "$target"
        echo -e "${GREEN}✓ Created symlink: $target -> $source${NC}"
    fi
}

# Function to create symlinks
create_symlinks() {
    echo -e "${BLUE}=== Creating Symlinks ===${NC}"
    
    local dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Create .config directories if they don't exist
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/ghostty"
    
    # Create symlinks one by one (compatible with sh and bash)
    create_single_symlink "$dotfiles_dir/zshrc" "$HOME/.zshrc"
    create_single_symlink "$dotfiles_dir/tmux.conf" "$HOME/.tmux.conf"
    create_single_symlink "$dotfiles_dir/oh-my-posh" "$HOME/.config/oh-my-posh"
    create_single_symlink "$dotfiles_dir/ghostty.config" "$HOME/.config/ghostty/config"
    
    echo
    echo -e "${CYAN}Symlink Summary:${NC}"
    
    # Check each symlink for summary
    local targets=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/oh-my-posh" "$HOME/.config/ghostty/config")
    for target in "${targets[@]}"; do
        if [[ -L "$target" ]]; then
            echo -e "${GREEN}  ✓ $target -> $(readlink "$target")${NC}"
        else
            echo -e "${RED}  ✗ $target (not a symlink)${NC}"
        fi
    done
}

# Function to source/reload configuration files
source_configs() {
    echo -e "${BLUE}=== Sourcing Configuration Files ===${NC}"
    
    local configs_sourced=0
    local configs_total=0
    
    echo -e "${CYAN}Attempting to source/reload all configuration files...${NC}"
    echo
    
    # Source zshrc if it exists and is a symlink to our config
    if [[ -L "$HOME/.zshrc" ]] && [[ "$(readlink "$HOME/.zshrc")" == *"dotfiles/zshrc" ]]; then
        configs_total=$((configs_total + 1))
        echo -e "${YELLOW}• Sourcing zsh configuration...${NC}"
        if [[ "$SHELL" == */zsh ]] || command -v zsh >/dev/null 2>&1; then
            # Use zsh to source the config to avoid compatibility issues
            if zsh -c "source $HOME/.zshrc" 2>/dev/null; then
                echo -e "${GREEN}  ✓ Successfully sourced ~/.zshrc${NC}"
                configs_sourced=$((configs_sourced + 1))
            else
                echo -e "${YELLOW}  ⚠ Could not source ~/.zshrc (this is normal if running from a different shell)${NC}"
                echo -e "${CYAN}    → Please restart your terminal or run: source ~/.zshrc${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠ Zsh not available in current session${NC}"
            echo -e "${CYAN}    → Please restart your terminal or run: source ~/.zshrc${NC}"
        fi
    else
        echo -e "${YELLOW}• Skipping zsh: symlink not found or doesn't point to dotfiles${NC}"
    fi
    
    # Reload tmux config if tmux is running and config exists
    if [[ -L "$HOME/.tmux.conf" ]] && [[ "$(readlink "$HOME/.tmux.conf")" == *"dotfiles/tmux.conf" ]]; then
        if command -v tmux >/dev/null 2>&1; then
            if tmux list-sessions >/dev/null 2>&1; then
                configs_total=$((configs_total + 1))
                echo -e "${YELLOW}• Reloading tmux configuration...${NC}"
                if tmux source-file "$HOME/.tmux.conf" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ Successfully reloaded tmux configuration${NC}"
                    configs_sourced=$((configs_sourced + 1))
                else
                    echo -e "${RED}  ✗ Failed to reload tmux configuration${NC}"
                fi
            else
                echo -e "${CYAN}• Skipping tmux: No active sessions found${NC}"
                echo -e "${CYAN}    → Tmux configuration will be loaded when you start tmux${NC}"
            fi
        else
            echo -e "${YELLOW}• Skipping tmux: Command not found${NC}"
        fi
    else
        echo -e "${YELLOW}• Skipping tmux: symlink not found or doesn't point to dotfiles${NC}"
    fi
    
    # Reload Ghostty config if it exists and Ghostty is running
    if [[ -L "$HOME/.config/ghostty/config" ]] && [[ "$(readlink "$HOME/.config/ghostty/config")" == *"dotfiles/ghostty.config" ]]; then
        if command -v ghostty >/dev/null 2>&1; then
            # Check if Ghostty is running (by looking for the process)
            if pgrep -x "ghostty" >/dev/null 2>&1; then
                configs_total=$((configs_total + 1))
                echo -e "${YELLOW}• Reloading Ghostty configuration...${NC}"
                if ghostty reload 2>/dev/null; then
                    echo -e "${GREEN}  ✓ Successfully reloaded Ghostty configuration${NC}"
                    configs_sourced=$((configs_sourced + 1))
                else
                    echo -e "${YELLOW}  ⚠ Could not reload Ghostty configuration automatically${NC}"
                    echo -e "${CYAN}    → Configuration will be loaded when you restart Ghostty${NC}"
                fi
            else
                echo -e "${CYAN}• Skipping Ghostty: No running instances found${NC}"
                echo -e "${CYAN}    → Configuration will be loaded when you start Ghostty${NC}"
            fi
        else
            echo -e "${YELLOW}• Skipping Ghostty: Command not found${NC}"
        fi
    else
        echo -e "${YELLOW}• Skipping Ghostty: symlink not found or doesn't point to dotfiles${NC}"
    fi
    
    echo
    if [[ $configs_total -eq 0 ]]; then
        echo -e "${CYAN}ℹ No configuration files were available to source${NC}"
        echo -e "${CYAN}  You may need to restart your terminal to apply changes${NC}"
    elif [[ $configs_sourced -eq $configs_total ]]; then
        echo -e "${GREEN}🎉 All configuration files sourced successfully! ($configs_sourced/$configs_total)${NC}"
    elif [[ $configs_sourced -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Partially successful: $configs_sourced/$configs_total configurations sourced${NC}"
        echo -e "${CYAN}  You may need to restart your terminal for remaining changes${NC}"
    else
        echo -e "${YELLOW}⚠ No configurations could be sourced automatically${NC}"
        echo -e "${CYAN}  Please restart your terminal to apply all changes${NC}"
    fi
}

# Main function
main() {
    print_ascii_art
    
    echo -e "${CYAN}Welcome to Tomer Brown's Dotfiles Setup!${NC}"
    echo -e "${CYAN}This script will help you set up your development environment.${NC}"
    echo
    
    # Detect OS and package manager
    detect_os
    echo
    
    if [[ -z "$PKG_MANAGER" ]]; then
        echo -e "${RED}Cannot proceed without a supported package manager. Exiting.${NC}"
        exit 1
    fi
    
    # Step 1: Change shell to zsh
    if ask_yes_no "Do you want to change your default shell to zsh?"; then
        change_shell_to_zsh
    else
        echo -e "${YELLOW}⚠ Skipped changing default shell${NC}"
    fi
    echo
    
    # Step 2: Initialize Zinit
    if ask_yes_no "Do you want to initialize Zinit?"; then
        initialize_zinit
    else
        echo -e "${YELLOW}⚠ Skipped Zinit initialization${NC}"
    fi
    echo
    
    # Step 3: Install packages
    if ask_yes_no "Do you want to install required packages (tmux, fzf, bat, oh-my-posh, JetBrains Mono Nerd Font)?"; then
        install_packages
    else
        echo -e "${YELLOW}⚠ Skipped package installation${NC}"
    fi
    echo
    
    # Step 4: Install Tmux Plugin Manager (tpm)
    if ask_yes_no "Do you want to install Tmux Plugin Manager (tpm)?"; then
        install_tpm
    else
        echo -e "${YELLOW}⚠ Skipped tpm installation${NC}"
    fi
    echo
    
    # Step 5: Create symlinks
    if ask_yes_no "Do you want to create symlinks for config files?"; then
        create_symlinks
    else
        echo -e "${YELLOW}⚠ Skipped creating symlinks${NC}"
    fi
    echo
    
    # Step 6: Source configuration files
    if ask_yes_no "Do you want to source/reload the configuration files now?"; then
        source_configs
    else
        echo -e "${YELLOW}⚠ Skipped sourcing configuration files${NC}"
        echo -e "${CYAN}  Remember to restart your terminal or manually source your configs${NC}"
    fi
    echo
    
    echo -e "${GREEN}🎉 Setup complete! 🎉${NC}"
    echo -e "${CYAN}If you didn't source the configs, restart your terminal or run 'source ~/.zshrc'${NC}"
    echo -e "${CYAN}If you changed your default shell, you may need to log out and back in.${NC}"
}

# Run main function
main "$@"