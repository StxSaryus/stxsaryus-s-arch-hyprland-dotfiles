# ============================================================
#  StxSaryus — Zsh
#  Prompt colours mirror config/theme/palette.conf
# ============================================================

# Powerlevel10k instant prompt must stay near the top. Anything that can
# print or ask for input belongs above it.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$HOME/.local/share/bin:$HOME/bin:/usr/local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export EDITOR="${EDITOR:-nano}"
export TERMINAL="${TERMINAL:-kitty}"

ZSH_THEME="powerlevel10k/powerlevel10k"
# Only the plugins Oh My Zsh ships. Arch installs zsh-autosuggestions and
# zsh-syntax-highlighting under /usr/share, where Oh My Zsh does not look,
# so those are sourced by hand further down.
plugins=(git archlinux sudo)

# ── Prompt ───────────────────────────────────────────────────
# A lean two-segment prompt in the rice palette. Defining these means
# Powerlevel10k skips its configuration wizard; run `p10k configure`
# any time you want the full interactive version instead.
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=
typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=81      # accent
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=211  # red
typeset -g POWERLEVEL9K_DIR_FOREGROUND=111                      # blue
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=245            # muted
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=81
typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_LAST=1
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=151                # green
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=223             # yellow
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=245
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=211
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=245
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=183          # mauve
typeset -g POWERLEVEL9K_TIME_FOREGROUND=245
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# ── Autosuggestions ──────────────────────────────────────────
for _p in /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
          "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
    [[ -r "$_p" ]] && { source "$_p"; break; }
done
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

# ── History ──────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups hist_ignore_space hist_reduce_blanks

# ── Keys ─────────────────────────────────────────────────────
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ── Aliases (each one degrades gracefully if the tool is absent) ──
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
alias reload='exec zsh'

# ── fzf ──────────────────────────────────────────────────────
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -r /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# ── Syntax highlighting ──────────────────────────────────────
# Has to be sourced after everything else it should highlight, and the
# styles have to be set after the plugin has filled in its defaults.
for _p in /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
          "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    [[ -r "$_p" ]] && { source "$_p"; break; }
done
unset _p

if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
    ZSH_HIGHLIGHT_STYLES[comment]='fg=245'
    ZSH_HIGHLIGHT_STYLES[command]='fg=81'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=81'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=81'
    ZSH_HIGHLIGHT_STYLES[function]='fg=111'
    ZSH_HIGHLIGHT_STYLES[path]='fg=252,underline'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=151'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=151'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=211'
fi

# ── Greeting: only on a terminal wide enough for the logo ────
if [[ -o interactive ]] && (( COLUMNS >= 120 )) && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Personal overrides, never tracked by the repo
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
