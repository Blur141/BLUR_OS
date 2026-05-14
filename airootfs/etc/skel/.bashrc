# NiyasOS default .bashrc

[[ $- != *i* ]] && return

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Window size
shopt -s checkwinsize

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza -la --icons --tree --level=2'
alias cat='bat --style=auto'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -m'
alias vim='nvim'
alias vi='nvim'
alias python='python3'
alias pip='pip3'

# Docker shorthand
alias dk='docker'
alias dkc='docker compose'
alias pd='podman'

# Git shorthand
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# zoxide integration
eval "$(zoxide init bash)"

# fzf
source /usr/share/fzf/key-bindings.bash 2>/dev/null
source /usr/share/fzf/completion.bash 2>/dev/null
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Prompt (simple, fast)
PS1='\[\e[1;34m\]\u\[\e[0m\]@\[\e[1;36m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]\$ '

# Dev environments
export EDITOR=nvim
export VISUAL=nvim
export BROWSER=firefox
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Node version manager (if using nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
