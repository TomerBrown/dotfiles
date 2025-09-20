# Fast zshrc configuration optimized for speed

# Basic exports and aliases
export EDITOR="code -w"
alias fix_civ6="rm /Users/tomerbrown/Library/Application Support/Sid Meier's Civilization VI/Firaxis Games/Sid Meier's Civilization VI/AppOptions.txt"
alias say_hello="echo Hello"

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
    OMZP::tmux \
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

# Fast fzf integration with single check
if command -v fzf >/dev/null 2>&1; then
    # Set fzf options first (fast)
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info --color=16"
    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --color=16"
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || echo {}' --color=16"
    export FZF_ALT_C_OPTS="--preview 'tree -C {} 2>/dev/null || ls -la {}' --color=16"
    
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
fi

# Lazy-load oh-my-posh (defer for speed)
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
    eval "$(oh-my-posh init zsh --config ~/dotfiles/oh-my-posh/base.json)"
fi
