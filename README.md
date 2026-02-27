# Arch Eren Config (dotfiles)

Arch Linux kurulumumun ayarlarını burada yedekleyip GitHub’da tutuyorum. Dotfiles tarzında; istersen symlink ile sisteme bağlayabilirsin.

---

## İçerik

| Klasör / dosya | Açıklama |
|----------------|----------|
| `zsh/.zshrc` | Zsh + Oh-My-Zsh + Powerlevel10k (Eren Edition) |
| `bash/.bashrc` | Basit Bash ayarları |
| `config/waybar/` | Waybar (config, style, sys_stats, gpu_stats) – Win11 tarzı auto-hide |
| `config/hypr/` | Hyprland config, waybar-autohide.sh, brightness-osd.sh |
| `greetd-config-fix/` | Giriş ekranı (tuigreet + start-hyprland) düzeltmesi |
| `boot-speed/` | Hızlı açılış için mkinitcpio ayarları |

---

## Kurulum (dotfiles gibi kullanmak)

### 1. Repoyu klonla

```bash
git clone git@github.com:StxSaryus/arch-eren-config.git ~/arch-eren-config
cd ~/arch-eren-config
```

### 2. Symlink ile bağla

Mevcut dosyaları yedekleyip repodakilere symlink verebilirsin:

```bash
REPO="$HOME/arch-eren-config"

# Zsh
mv ~/.zshrc ~/.zshrc.bak 2>/dev/null
ln -s "$REPO/zsh/.zshrc" ~/.zshrc

# Bash
mv ~/.bashrc ~/.bashrc.bak 2>/dev/null
ln -s "$REPO/bash/.bashrc" ~/.bashrc

# Waybar
mkdir -p ~/.config/waybar
for f in config.jsonc style.css gpu_stats.sh sys_stats.sh; do
  mv ~/.config/waybar/$f ~/.config/waybar/$f.bak 2>/dev/null
  ln -sf "$REPO/config/waybar/$f" ~/.config/waybar/$f
done

# Hyprland
mkdir -p ~/.config/hypr
for f in hyprland.conf waybar-autohide.sh brightness-osd.sh; do
  mv ~/.config/hypr/$f ~/.config/hypr/$f.bak 2>/dev/null
  ln -sf "$REPO/config/hypr/$f" ~/.config/hypr/$f
done
chmod +x ~/.config/hypr/waybar-autohide.sh ~/.config/hypr/brightness-osd.sh
```

### 3. Greetd ve boot (isteğe bağlı, sudo gerekir)

- **Giriş ekranı:** `sudo cp greetd-config-fix/config.toml /etc/greetd/config.toml` → `sudo systemctl restart greetd`
- **Hızlı açılış:** `boot-speed/README.md` içindeki adımları uygula (mkinitcpio + bootloader timeout).

---

## Güncellemeleri GitHub’a yüklemek

Yerelde bir şeyi değiştirdikten sonra:

```bash
cd ~/arch-eren-config   # veya reponun olduğu klasör

git add .
git status              # ne eklendi kontrol et
git commit -m "waybar/hypr/greetd/boot güncellemeleri"
git push origin main
```

Yeni bir makinede veya temiz kurulumda:

```bash
git clone git@github.com:StxSaryus/arch-eren-config.git ~/arch-eren-config
cd ~/arch-eren-config
# Yukarıdaki symlink komutlarını çalıştır
```

---

## Notlar

- Repoda sadece seçtiğim config’ler var; cache, log, şifre vb. yok.
- Waybar’ı `waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css` ile başlatıyorsan (veya hyprland.conf’taki gibi tam path), symlink’ten sonra aynen çalışır.
