# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# If you see warnings about console output during initialization and don't care
# about instant prompt, you can disable it:
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- StxSaryus EDITION v1.0 (FINAL OPTIMIZED) ---

# 1. PATH setup
export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH

# 2. Oh-My-Zsh location
export ZSH="$HOME/.oh-my-zsh"

# 3. Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# 4. Plugins
plugins=(git archlinux zsh-autosuggestions zsh-syntax-highlighting)

# 5. Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# 6. Visual telemetry (Fastfetch)

# 7. Handy aliases
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias update='sudo pacman -Syu'
alias nvidiatest='nvidia-smi'

# 8. FZF & history settings
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory

# 9. Key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

# --- READABILITY FIX ---
# Make comments more visible
ZSH_HIGHLIGHT_STYLES[comment]='fg=#94e2d5'
# Make unknown tokens bright red
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8,bold'
# Make strings yellow/green
ZSH_HIGHLIGHT_STYLES[string]='fg=#a6e3a1'

# --- READABILITY FIX ---
# Make comments more visible
ZSH_HIGHLIGHT_STYLES[comment]='fg=#94e2d5'
# Make unknown tokens bright red
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8,bold'
# Make strings yellow/green
ZSH_HIGHLIGHT_STYLES[string]='fg=#a6e3a1'

# --- SOFT READABILITY FIX ---
# Make comments dim gray (less eye strain)
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
# Use darker red for unknown tokens instead of bright red
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#a61e22'
# Make commands slightly off-white
ZSH_HIGHLIGHT_STYLES[command]='fg=#bac2de'

# Fix prompt username (StxSaryus) color to soft blue
# %F{...} sets color, %f resets. 110 is a nice balanced blue.
PROMPT='%F{110}%n%f%F{242}@%m%f %F{147}%~%f %F{105}❯%f '

# --- SMART FASTFETCH ---

# --- STXSARYUS SMART FASTFETCH ---
# Only show the logo when terminal width >= 120
# This prevents layout issues when tiling terminals.

# --- SMART FASTFETCH ---
if [[ -o interactive ]] && (( COLUMNS >= 120 )); then
    fastfetch
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Power profiles (reserved for future use)
