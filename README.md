# Tomer Brown's Dotfiles

A comprehensive dotfiles repository for setting up a modern development environment on macOS and Linux.

## 🚀 Quick Setup

Run the automated setup script:

```bash
git clone https://github.com/tomerbrown/dotfiles.git
cd dotfiles
./setup.sh
```

## 📦 What's Included

### Configuration Files
- **Zsh** (`zshrc`) - Shell configuration with Zinit plugin manager
- **Tmux** (`tmux.conf`) - Terminal multiplexer configuration  
- **Ghostty** (`ghostty.config`) - Modern terminal emulator config
- **Oh My Posh** (`oh-my-posh/`) - Beautiful shell themes

### Features
- 🎨 **Catppuccin Mocha** theme across all tools
- ⚡ **Fast shell** with autocomplete, syntax highlighting, and suggestions
- 🔧 **Cross-platform** setup script (macOS, Linux)
- 🎯 **Interactive installation** - choose what you want to install
- 🔗 **Symlink management** - safe backup and restore
- 📦 **Auto package installation** - tmux, fzf, bat, fonts, and more

## 🛠 Setup Script Features

The setup script (`setup.sh`) provides an interactive installation with these steps:

1. **Change default shell to zsh** 
2. **Initialize Zinit** (zsh plugin manager)
3. **Install packages**: tmux, fzf, bat, oh-my-posh, JetBrains Mono Nerd Font
4. **Create symlinks** for all config files with backup protection
5. **Source configurations** to apply changes immediately

### Package Manager Support
- **macOS**: Homebrew
- **Debian/Ubuntu**: APT
- **RedHat/CentOS**: YUM  
- **Arch Linux**: Pacman

## 🎨 Theme & Appearance

All configurations use the **Catppuccin Mocha** color scheme for a consistent, modern look:

- **Zsh prompt**: Oh My Posh with Catppuccin theme
- **Terminal**: Ghostty with transparency and blur effects
- **Font**: JetBrains Mono Nerd Font (19pt) with programming ligatures

## ⚙️ Individual Configurations

### Zsh (`zshrc`)
- **Zinit** plugin manager
- **Fast syntax highlighting**
- **Autosuggestions** based on history
- **fzf** integration for fuzzy finding
- **Git, tmux, docker, node** plugins
- **Oh My Posh** theming

### Ghostty (`ghostty.config`)
- Catppuccin Mocha theme
- Background transparency (90%) with blur
- JetBrains Mono Nerd Font
- macOS-optimized keybindings
- Shell integration

### Tmux (`tmux.conf`)
- Custom key bindings
- Status bar configuration
- Mouse support
- Copy/paste integration


## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---