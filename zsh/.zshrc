# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- StxSaryus EDITION v1.0 (FINAL OPTIMIZED) ---

# 1. Path Ayarları
export PATH=$HOME/bin:/usr/local/bin:$PATH

# 2. Oh-My-Zsh Kurulumu
export ZSH="$HOME/.oh-my-zsh"

# 3. Tema
ZSH_THEME="powerlevel10k/powerlevel10k"

# 4. Pluginler (Aradaki boşluklara dikkat)
plugins=(git archlinux zsh-autosuggestions zsh-syntax-highlighting)

# 5. Oh-My-Zsh Başlat
source $ZSH/oh-my-zsh.sh

# 6. Telemetri (Minimalist Fastfetch)

# 7. Akıllı Alias'lar
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias update='sudo pacman -Syu'
alias nvidiatest='nvidia-smi'

# 8. FZF & Geçmiş Ayarları
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory

# 9. Tuş Atamaları
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

# --- OKUNABİLİRLİK FIX ---
# Yorum satırlarını (comments) belirgin gri yap
ZSH_HIGHLIGHT_STYLES[comment]='fg=#94e2d5'
# Hatalı komutları (unknown-token) parlak kırmızı yap
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8,bold'
# Stringleri (yazıları) sarı/yeşil yap
ZSH_HIGHLIGHT_STYLES[string]='fg=#a6e3a1'

# --- OKUNABİLİRLİK FIX ---
# Yorum satırlarını (comments) belirgin gri yap
ZSH_HIGHLIGHT_STYLES[comment]='fg=#94e2d5'
# Hatalı komutları (unknown-token) parlak kırmızı yap
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8,bold'
# Stringleri (yazıları) sarı/yeşil yap
ZSH_HIGHLIGHT_STYLES[string]='fg=#a6e3a1'

# --- SOFT READABILITY FIX ---
# Yorum satırlarını sönük gri yap (Göz yormaz)
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
# Hatalı komutları 'parlak kırmızı' yerine 'koyu kırmızı' yap
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#a61e22'
# Komutların kendisini çok parlak olmayan beyaz yap
ZSH_HIGHLIGHT_STYLES[command]='fg=#bac2de'

# Prompt'taki kullanıcı adı (StxSaryus) rengini mat maviye sabitle
# %F{...} rengi belirler, %f sıfırlar. 110 numaralı renk çok dengeli bir mavidir.
PROMPT='%F{110}%n%f%F{242}@%m%f %F{147}%~%f %F{105}❯%f '

# --- SMART FASTFETCH ---

# --- STXSARYUS SMART FASTFETCH ---
# Sadece genişlik 120 karakterden fazlaysa logoyu göster
# Bu sayede ekranı 2'ye veya 4'e böldüğünde görüntü bozulmaz.

# --- SMART FASTFETCH ---
if [[ -o interactive ]] && (( COLUMNS >= 120 )); then
    fastfetch
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Güç profilleri
