#
# ~/.bashrc — fallback shell, same colours and aliases as the zsh setup
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PATH="$HOME/.local/bin:$HOME/.local/share/bin:$HOME/bin:/usr/local/bin:$PATH"
export EDITOR="${EDITOR:-nano}"
export TERMINAL="${TERMINAL:-kitty}"

# Prompt: blue path, accent caret — the palette, in 256 colours
PS1='\[\e[38;5;111m\]\w\[\e[0m\] \[\e[38;5;81m\]❯\[\e[0m\] '

if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd --group-directories-first'
    alias lt='ls --tree'
else
    alias ls='ls --color=auto --group-directories-first'
fi
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias grep='grep --color=auto'
alias update='~/.local/share/bin/systemupdate.sh up'
alias gpu='nvidia-smi'

HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize

[[ -r "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
