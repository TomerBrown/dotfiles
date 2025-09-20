alias fix_civ6="rm /Users/tomerbrown/Library/Application Support/Sid Meier's Civilization VI/Firaxis Games/Sid Meier's Civilization VI/AppOptions.txt"
alias say_hello="echo Hello"
export EDITOR="code -w"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
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

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Initialize oh-my-posh theme
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/dotfiles/oh-my-posh/base.json)"
fi

# Load plugins with zinit
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions

# Load fzf with proper shell integration
if command -v fzf >/dev/null 2>&1; then
    # Try to source fzf key bindings from various locations
    local fzf_key_bindings=""
    local fzf_completion=""
    
    if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
        fzf_key_bindings="/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
        fzf_completion="/opt/homebrew/opt/fzf/shell/completion.zsh"
    elif [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
        fzf_key_bindings="/usr/local/opt/fzf/shell/key-bindings.zsh"
        fzf_completion="/usr/local/opt/fzf/shell/completion.zsh"
    elif [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    fi
    
    # Source the files if found
    if [[ -n "$fzf_key_bindings" && -f "$fzf_key_bindings" ]]; then
        source "$fzf_key_bindings"
    fi
    if [[ -n "$fzf_completion" && -f "$fzf_completion" ]]; then
        source "$fzf_completion"
    fi
    
    # If sourcing didn't work, create a simple Ctrl+R binding manually
    if ! type fzf-history-widget >/dev/null 2>&1; then
        # Create a simple fzf history function
        fzf-history-widget() {
            local selected
            selected=$(fc -rl 1 | fzf --tac --no-sort --tiebreak=index --query="$LBUFFER" \
                --height=40% --layout=reverse --border --prompt="History: " \
                --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected" ]]; then
                BUFFER=$(echo "$selected" | sed 's/^[ ]*[0-9]*[ ]*//')
                CURSOR=$#BUFFER
            fi
            zle redisplay
        }
        zle -N fzf-history-widget
        bindkey '^R' fzf-history-widget
    fi
fi

# Additional fzf configuration
if command -v fzf >/dev/null 2>&1; then
    # Set fzf default options for better appearance
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info --color=16"
    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --color=16"
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}' --color=16"
    export FZF_ALT_C_OPTS="--preview 'tree -C {}' --color=16"
fi

# Oh My Zsh plugins
zinit snippet OMZP::git
zinit snippet OMZP::tmux
zinit snippet OMZP::docker
zinit snippet OMZP::node
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::web-search
zinit snippet OMZP::sudo
