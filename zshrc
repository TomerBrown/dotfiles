# Fast zshrc configuration optimized for speed

# Basic exports and aliases
export EDITOR="code -w"

# Needed for android simulator
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export ANDROID_HOME="/Users/tomerbrown/Library/Android/sdk"
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Zinit initialization (fast path)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$(dirname $ZINIT_HOME)" && command chmod g-rwX "$ZINIT_HOME"
    command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi
source "$ZINIT_HOME/zinit.zsh"

# Load essential plugins with turbo mode for speed
zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf \
        zsh-users/zsh-completions

# Load Oh My Zsh plugins with turbo mode
zinit wait lucid for \
    OMZP::git \
    OMZP::docker \
    OMZP::node \
    OMZP::colored-man-pages \
    OMZP::web-search \
    OMZP::sudo

# Lazy-load conda (defer initialization for speed)
__conda_lazy_init() {
    unfunction __conda_lazy_init
    # Actual conda initialization
    __conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/anaconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/anaconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
}
# Create conda alias that triggers lazy loading
conda() { __conda_lazy_init; conda "$@"; }

# Add fzf to PATH
export PATH="$PATH:$HOME/.fzf/bin"

# Fast fzf integration with single check
if command -v fzf >/dev/null 2>&1; then
    # Set fzf to use fd as default command (faster and more user-friendly than find)
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
        # Ctrl+T should include both files and directories
        export FZF_CTRL_T_COMMAND="fd --hidden --follow --exclude .git"
    fi
    
    # Set clean fzf defaults - no forced previews for generic use
    export FZF_DEFAULT_OPTS="--style full --height=100% --layout=reverse --border --inline-info --color=16"
    
    # Ctrl+T with your specific configuration
    export FZF_CTRL_T_OPTS="--ansi --style full --preview '~/dotfiles/fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}' --height=100%"
    export FZF_ALT_C_OPTS="--ansi --preview 'eza --tree --icons --level=2 --color=always {} 2>/dev/null || tree -C {} 2>/dev/null || ls -la {}'"
    
    # Enhanced Ctrl+R with syntax-highlighted command preview
    export FZF_CTRL_R_OPTS="--preview 'echo {} | sed \"s/^[ ]*[0-9]*[ ]*//\" | bat --color=always --language=bash --style=numbers --wrap=never -' --preview-window=right:50%:wrap"
    
    # Lazy-load fzf integration for speed
    __fzf_lazy_init() {
        unfunction __fzf_lazy_init
        # Try homebrew locations (most likely on macOS)
        if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
            source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
            source /opt/homebrew/opt/fzf/shell/completion.zsh
        elif [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
            source /usr/local/opt/fzf/shell/key-bindings.zsh
            source /usr/local/opt/fzf/shell/completion.zsh
        elif [[ -f ~/.fzf.zsh ]]; then
            source ~/.fzf.zsh
        else
            # Fallback: create lightweight Ctrl+R binding
            fzf-history-widget() {
                local selected
                selected=$(fc -rl 1 | fzf --tac --no-sort --query="$LBUFFER" \
                    --height=40% --layout=reverse --border --prompt="History: ")
                if [[ -n "$selected" ]]; then
                    BUFFER=$(echo "$selected" | sed 's/^[ ]*[0-9]*[ ]*//')
                    CURSOR=$#BUFFER
                fi
                zle redisplay
            }
            zle -N fzf-history-widget
            bindkey '^R' fzf-history-widget
        fi
    }
    
    # Trigger fzf loading on first Ctrl+R press
    __fzf_history_trigger() { __fzf_lazy_init; fzf-history-widget; }
    zle -N __fzf_history_trigger
    bindkey '^R' __fzf_history_trigger
    
    # Simple directory browser with fzf
    fzf-directory-browser() {
        local selected
        # Use fd if available, fallback to find
        if command -v fd >/dev/null 2>&1; then
            selected=$(fd --type d --hidden --follow --exclude .git . | \
                fzf --prompt="📁 Directories: " \
                    --header="Press ENTER to cd into directory, ESC to cancel" \
                    --ansi \
                    --preview 'eza --tree --icons --level=2 --color=always {} | head -20')
        else
            selected=$(find . -type d -not -path '*/.*' 2>/dev/null | \
                fzf --prompt="📁 Directories: " \
                    --header="Press ENTER to cd into directory, ESC to cancel" \
                    --ansi \
                    --preview 'eza --tree --icons --level=2 --color=always {} | head -20')
        fi
        
        if [[ -n "$selected" ]]; then
            cd "$selected"
            echo "Changed to: $(pwd)"
        fi
    }
fi

export FZF_DEFAULT_OPTS=" \
--color=bg+:#414559,bg:#303446,spinner:#F2D5CF,hl:#E78284 \
--color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#F2D5CF \
--color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
--color=selected-bg:#51576D \
--color=border:#737994,label:#C6D0F5"

# Zoxide related
eval "$(zoxide init zsh)"


# Lazy-load oh-my-posh (defer for speed)
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
    eval "$(oh-my-posh init zsh --config ~/dotfiles/oh-my-posh/base.json)"
fi
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/tomerbrown/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Aliases
alias ls=eza
alias d='fzf-directory-browser'  # Directory browser with tree preview
alias find='fd'

# Eza Aliases
alias ls='eza --long -a --header --icons --git --color=auto'
alias ll='eza -al --header --icons --git --color=auto --group-directories-first'
alias lt='eza --tree --level=2 --icons --color=auto' # Tree view of directories up to level 2

# Yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
