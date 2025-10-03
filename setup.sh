#!/bin/bash

# Check if running with bash (array support test)
if ! (return 0 2>/dev/null) && [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash to run properly."
    echo "The syntax error you're seeing is because this script uses bash-specific features."
    echo ""
    echo "Please run it with one of these methods:"
    echo "  bash setup.sh    (recommended)"
    echo "  ./setup.sh       (uses shebang)"
    echo ""
    echo "Do NOT use: sh setup.sh"
    exit 1
fi

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

# Function to check if fd is installed (handles different package names)
is_fd_installed() {
    # Check if the fd command is available regardless of package name
    if command -v fd >/dev/null 2>&1; then
        return 0
    fi
    
    # If command not found, check package installation by name
    case "$PKG_MANAGER" in
        "brew")
            is_package_installed "fd"
            ;;
        "apt"|"yum")
            is_package_installed "fd-find"
            ;;
        "pacman")
            is_package_installed "fd"
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

# Function to install fzf from GitHub using Git
install_fzf_from_git() {
    echo -e "${YELLOW}Installing fzf from GitHub...${NC}"
    
    local fzf_dir="$HOME/.fzf"
    
    if [[ -d "$fzf_dir" ]]; then
        echo -e "${GREEN}✓ fzf directory already exists${NC}"
        if [[ -f "$fzf_dir/bin/fzf" ]]; then
            echo -e "${GREEN}✓ fzf is already installed${NC}"
            return 0
        fi
    fi
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}✗ Git is not installed. Please install git first.${NC}"
        return 1
    fi
    
    # Remove existing fzf directory if it exists but might be incomplete
    if [[ -d "$fzf_dir" ]]; then
        echo -e "${YELLOW}Removing existing fzf directory...${NC}"
        rm -rf "$fzf_dir"
    fi
    
    # Clone the repository with depth 1
    echo -e "${CYAN}Cloning fzf repository...${NC}"
    if git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"; then
        # Navigate to the fzf directory and run the install script
        echo -e "${CYAN}Running fzf install script...${NC}"
        cd "$fzf_dir"
        
        # Run the install script with automatic yes to all prompts
        if ./install --all; then
            echo -e "${GREEN}✓ Successfully installed fzf from GitHub${NC}"
            echo -e "${CYAN}ℹ fzf key bindings and auto-completion have been set up${NC}"
            cd - >/dev/null  # Return to previous directory
            return 0
        else
            echo -e "${RED}✗ Failed to run fzf install script${NC}"
            cd - >/dev/null  # Return to previous directory
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to clone fzf repository${NC}"
        echo -e "${YELLOW}⚠ This might be due to:${NC}"
        echo -e "${CYAN}    - No internet connection${NC}"
        echo -e "${CYAN}    - Git not installed${NC}"
        echo -e "${CYAN}    - Permission issues${NC}"
        echo -e "${YELLOW}⚠ You can install it manually by running:${NC}"
        echo -e "${CYAN}    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf${NC}"
        echo -e "${CYAN}    cd ~/.fzf && ./install${NC}"
        return 1
    fi
}

# Function to install required packages
install_packages() {
    echo -e "${BLUE}=== Installing Required Packages ===${NC}"
    
    local packages=("tmux" "bat" "tree" "eza" "fribidi" "yazi")
    
    for package in "${packages[@]}"; do
        install_package "$package"
        
        # Install tpm automatically after tmux is installed
        if [[ "$package" == "tmux" ]] && command -v tmux >/dev/null 2>&1; then
            echo -e "${CYAN}Installing Tmux Plugin Manager (tpm) for tmux...${NC}"
            if ! install_tpm_silent; then
                echo -e "${RED}  ✗ Failed to install tpm automatically${NC}"
                echo -e "${YELLOW}  ⚠ Tmux will not work properly without tpm${NC}"
                echo -e "${CYAN}  ℹ You can install it manually later or re-run this script${NC}"
            fi
        fi
    done
    
    # Install fzf from GitHub using Git
    install_fzf_from_git
    
    # Special handling for fd (package name varies by system)
    if is_fd_installed; then
        echo -e "${GREEN}✓ fd is already installed${NC}"
    else
        echo -e "${YELLOW}Installing fd (find alternative)...${NC}"
        local fd_package=""
        case "$PKG_MANAGER" in
            "brew")
                fd_package="fd"
                ;;
            "apt")
                fd_package="fd-find"
                ;;
            "yum")
                fd_package="fd-find"
                ;;
            "pacman")
                fd_package="fd"
                ;;
            *)
                echo -e "${YELLOW}Unknown package manager for fd installation${NC}"
                fd_package="fd"
                ;;
        esac
        
        if [[ -n "$fd_package" ]]; then
            case "$PKG_MANAGER" in
                "brew")
                    brew install "$fd_package"
                    ;;
                "apt")
                    sudo apt update && sudo apt install -y "$fd_package"
                    ;;
                "yum")
                    sudo yum install -y "$fd_package"
                    ;;
                "pacman")
                    sudo pacman -S --noconfirm "$fd_package"
                    ;;
                *)
                    echo -e "${RED}Cannot install $fd_package: unsupported package manager${NC}"
                    ;;
            esac
        fi
    fi
    
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
    install_jetbrains_nerd_font
    
    # Ensure tpm is installed if tmux is available
    if command -v tmux >/dev/null 2>&1; then
        echo -e "${CYAN}Checking Tmux Plugin Manager (tpm) installation...${NC}"
        if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
            echo -e "${YELLOW}Tmux Plugin Manager (tpm) not found. Installing...${NC}"
            if ! install_tpm_silent; then
                echo -e "${RED}  ✗ Failed to install tpm${NC}"
                echo -e "${YELLOW}  ⚠ Tmux will not work properly without tpm${NC}"
            fi
        else
            echo -e "${GREEN}✓ Tmux Plugin Manager (tpm) is already installed${NC}"
        fi
    fi
}

# Function to install Tmux Plugin Manager (tpm) - silent version for automatic installation
install_tpm_silent() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ -d "$tpm_dir" ]]; then
        echo -e "${GREEN}  ✓ Tmux Plugin Manager (tpm) is already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}  Installing Tmux Plugin Manager (tpm)...${NC}"
    
    # Create the plugins directory if it doesn't exist
    mkdir -p "$HOME/.tmux/plugins"
    
    # Remove existing tpm directory if it exists but might be corrupted
    if [[ -d "$tpm_dir" ]]; then
        echo -e "${YELLOW}  Removing existing tpm directory...${NC}"
        rm -rf "$tpm_dir"
    fi
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}  ✗ Git is not installed. Please install git first.${NC}"
        return 1
    fi
    
    # Clone tpm repository
    echo -e "${CYAN}  Cloning tpm repository...${NC}"
    if git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null; then
        # Ensure the tpm script is executable
        chmod +x "$tpm_dir/tpm"
        
        # Verify installation
        if [[ -x "$tpm_dir/tpm" ]]; then
            echo -e "${GREEN}  ✓ Successfully installed Tmux Plugin Manager (tpm)${NC}"
            echo -e "${CYAN}  ℹ After tmux configuration is loaded, you can install plugins by pressing prefix + I (Ctrl-B + I by default)${NC}"
        else
            echo -e "${RED}  ✗ tpm script is not executable after installation${NC}"
            return 1
        fi
    else
        echo -e "${RED}  ✗ Failed to install Tmux Plugin Manager (tpm)${NC}"
        echo -e "${YELLOW}  ⚠ This might be due to:${NC}"
        echo -e "${CYAN}    - No internet connection${NC}"
        echo -e "${CYAN}    - Git not installed${NC}"
        echo -e "${CYAN}    - Permission issues${NC}"
        echo -e "${YELLOW}  ⚠ You can install it manually by running:${NC}"
        echo -e "${CYAN}    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm${NC}"
        echo -e "${CYAN}    chmod +x ~/.tmux/plugins/tpm/tpm${NC}"
        return 1
    fi
}

# Function to install Tmux Plugin Manager (tpm) - interactive version
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
        # Ensure the tpm script is executable
        chmod +x "$tpm_dir/tpm"
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
install_jetbrains_nerd_font() {
    local dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local nerd_font_script="$dotfiles_dir/install_nerd_font.sh"
    
    if [[ -f "$nerd_font_script" ]]; then
        echo -e "${CYAN}Using dedicated Nerd Font installation script...${NC}"
        source "$nerd_font_script"
        if install_jetbrains_nerd_font; then
            return 0
        else
            echo -e "${YELLOW}⚠ Nerd Font script failed, trying Homebrew fallback...${NC}"
            install_jetbrains_font_homebrew_fallback
        fi
    else
        echo -e "${YELLOW}⚠ Nerd Font script not found, using fallback method...${NC}"
        install_jetbrains_font_homebrew_fallback
    fi
}

# Function to install JetBrains Mono font via Homebrew (fallback)
install_jetbrains_font_homebrew_fallback() {
    case "$PKG_MANAGER" in
        "brew")
            echo -e "${YELLOW}Installing JetBrains Mono Nerd Font via Homebrew...${NC}"
            if brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null; then
                echo -e "${GREEN}✓ Successfully installed JetBrains Mono Nerd Font via Homebrew${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠ Homebrew installation failed, trying manual method...${NC}"
                install_jetbrains_font_manual
                return 1
            fi
            ;;
        *)
            install_jetbrains_font_manual
            return 1
            ;;
    esac
}


# Function to provide manual installation instructions
install_jetbrains_font_manual() {
    echo -e "${CYAN}Manual JetBrains Mono Nerd Font installation:${NC}"
    echo -e "${CYAN}Automatic installation failed. Please install manually:${NC}"
    echo
    echo -e "${YELLOW}Nerd Fonts Installation (Recommended):${NC}"
    echo -e "${CYAN}1. Visit: https://github.com/ryanoasis/nerd-fonts/releases/latest${NC}"
    echo -e "${CYAN}2. Download JetBrainsMono.zip${NC}"
    echo -e "${CYAN}3. Extract the archive${NC}"
    echo -e "${CYAN}4. Install the font files:${NC}"
    if [[ "$OS" == "macos" ]]; then
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
    create_single_symlink "$dotfiles_dir/vimrc" "$HOME/.vimrc"
    create_single_symlink "$dotfiles_dir/tmux.conf" "$HOME/.tmux.conf"
    create_single_symlink "$dotfiles_dir/oh-my-posh" "$HOME/.config/oh-my-posh"
    create_single_symlink "$dotfiles_dir/ghostty.config" "$HOME/.config/ghostty/config"
    
    echo
    echo -e "${CYAN}Symlink Summary:${NC}"
    
    # Check each symlink for summary
    local targets=("$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.tmux.conf" "$HOME/.config/oh-my-posh" "$HOME/.config/ghostty/config")
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

# Function to print next steps and helpful information
print_next_steps() {
    echo -e "${BLUE}=== Next Steps & Important Information ===${NC}"
    echo
    
    # Shell and environment
    echo -e "${YELLOW}🔄 Shell & Environment:${NC}"
    if [[ "$SHELL" != */zsh ]]; then
        echo -e "${CYAN}  • Your shell was changed to zsh - you may need to log out and back in${NC}"
    fi
    echo -e "${CYAN}  • If configs weren't sourced, restart your terminal or run: ${GREEN}source ~/.zshrc${NC}"
    echo -e "${CYAN}  • Your terminal prompt is now powered by oh-my-posh with a custom theme${NC}"
    echo
    
    # Tmux and plugins
    if command -v tmux >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Tmux & Plugins:${NC}"
        echo -e "${CYAN}  • Start tmux with: ${GREEN}tmux${NC}"
        echo -e "${CYAN}  • Install tmux plugins by pressing: ${GREEN}Ctrl-B + I${NC} (prefix + I)"
        echo -e "${CYAN}  • Tmux session management: ${GREEN}Ctrl-B + o${NC} (sessionx)"
        echo -e "${CYAN}  • Floating terminal: ${GREEN}Ctrl-B + p${NC} (floax)"
        echo -e "${CYAN}  • Your tmux uses the Catppuccin theme and custom key bindings${NC}"
        echo
    fi
    
    # Font information
    echo -e "${YELLOW}🔤 Font Configuration:${NC}"
    echo -e "${CYAN}  • JetBrains Mono Nerd Font has been installed${NC}"
    echo -e "${CYAN}  • Recommended settings: Size 13, Line spacing 1.2${NC}"
    echo -e "${CYAN}  • Configure your terminal/IDE to use 'JetBrainsMono Nerd Font' font${NC}"
    echo -e "${CYAN}  • This font provides excellent code readability, ligatures, and dev icons${NC}"
    echo
    
    # Development tools
    echo -e "${YELLOW}🛠️  Development Tools Available:${NC}"
    echo -e "${CYAN}  • ${GREEN}fzf${NC} - Fuzzy finder (integrated with zsh history and file search)"
    echo -e "${CYAN}  • ${GREEN}bat${NC} - Enhanced 'cat' with syntax highlighting"
    echo -e "${CYAN}  • ${GREEN}tree${NC} - Display directory structure as a tree"
    echo -e "${CYAN}  • ${GREEN}eza${NC} - Modern replacement for 'ls' with colors and icons"
    echo -e "${CYAN}  • ${GREEN}fd${NC} - Fast and user-friendly alternative to 'find'"
    echo -e "${CYAN}  • ${GREEN}fribidi${NC} - Unicode bidirectional text support (for Hebrew RTL)"
    echo -e "${CYAN}  • ${GREEN}zinit${NC} - Fast zsh plugin manager (auto-configured)"
    echo -e "${CYAN}  • Enhanced zsh with auto-suggestions, syntax highlighting, and more${NC}"
    echo
    
    # Configuration files
    echo -e "${YELLOW}📝 Configuration Files:${NC}"
    echo -e "${CYAN}  • All config files are symlinked to this dotfiles repository${NC}"
    echo -e "${CYAN}  • Edit configs here to keep them in version control${NC}"
    echo -e "${CYAN}  • Main configs: ~/.zshrc, ~/.vimrc, ~/.tmux.conf, ~/.config/ghostty/config${NC}"
    echo -e "${CYAN}  • oh-my-posh theme: ~/.config/oh-my-posh/base.json${NC}"
    echo
    
    # Terminal application
    if [[ -f "$HOME/.config/ghostty/config" ]]; then
        echo -e "${YELLOW}👻 Ghostty Terminal:${NC}"
        echo -e "${CYAN}  • Your Ghostty terminal is configured with JetBrains Mono Nerd Font${NC}"
        echo -e "${CYAN}  • Configuration will take effect when you restart Ghostty${NC}"
        echo -e "${CYAN}  • Settings are optimized for development work${NC}"
        echo
    fi
    
    # Troubleshooting
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo -e "${CYAN}  • If commands aren't found, restart your terminal${NC}"
    echo -e "${CYAN}  • If tmux plugins don't work, run tmux and press ${GREEN}Ctrl-B + I${NC}"
    echo -e "${CYAN}  • If fonts look wrong, ensure JetBrains Mono Nerd Font is selected in your terminal${NC}"
    echo -e "${CYAN}  • All configs are in: ${GREEN}$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)${NC}"
    echo
    
    echo -e "${GREEN}✨ Your development environment is ready! ✨${NC}"
    echo -e "${CYAN}Enjoy your new setup with enhanced productivity tools! 🚀${NC}"
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
    if ask_yes_no "Do you want to install required packages (tmux + tpm, fzf, bat, tree, eza, fd, fribidi, oh-my-posh, JetBrains Mono Nerd Font)?"; then
        install_packages
    else
        echo -e "${YELLOW}⚠ Skipped package installation${NC}"
    fi
    echo
    
    # Step 4: Create symlinks
    if ask_yes_no "Do you want to create symlinks for config files?"; then
        create_symlinks
    else
        echo -e "${YELLOW}⚠ Skipped creating symlinks${NC}"
    fi
    echo
    
    # Step 5: Source configuration files
    if ask_yes_no "Do you want to source/reload the configuration files now?"; then
        source_configs
    else
        echo -e "${YELLOW}⚠ Skipped sourcing configuration files${NC}"
        echo -e "${CYAN}  Remember to restart your terminal or manually source your configs${NC}"
    fi
    echo
    
    # Final verification of critical components
    echo -e "${BLUE}=== Final Verification ===${NC}"
    
    # Check if tpm is properly installed if tmux was installed
    if command -v tmux >/dev/null 2>&1; then
        if [[ ! -x "$HOME/.tmux/plugins/tpm/tpm" ]]; then
            echo -e "${RED}⚠ WARNING: Tmux Plugin Manager (tpm) is not properly installed!${NC}"
            echo -e "${YELLOW}Attempting to install tpm now...${NC}"
            
            # Try to install tpm one more time
            mkdir -p "$HOME/.tmux/plugins"
            if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null; then
                chmod +x "$HOME/.tmux/plugins/tpm/tpm"
                echo -e "${GREEN}✓ Successfully installed tpm${NC}"
            else
                echo -e "${RED}✗ Failed to install tpm. Manual installation required:${NC}"
                echo -e "${CYAN}  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm${NC}"
                echo -e "${CYAN}  chmod +x ~/.tmux/plugins/tpm/tpm${NC}"
            fi
        else
            echo -e "${GREEN}✓ Tmux Plugin Manager (tpm) is properly installed${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}🎉 Setup complete! 🎉${NC}"
    echo
    print_next_steps
}

# Run main function
main "$@"