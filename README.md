## Arch Eren Config

Kendi Arch Linux kurulumumun ayarlarını (dotfiles) burada yedekleyip zamanla geliştirmek için kullandığım depo.

### İçerik

- `zsh/.zshrc`: Zsh + Oh-My-Zsh + Powerlevel10k ayarları (Eren Edition).
- `bash/.bashrc`: Basit Bash alias ve prompt ayarları.

İleride buraya eklemeyi planladıklarım:

- `~/.config` altındaki WM/DE ve terminal ayarları (ör. Hyprland/i3/sway, alacritty/kitty, waybar vs.).
- Kullanmak istediğim scriptler (`scripts/` klasörü).

### Kullanım

1. Depoyu klonla:

   ```bash
   git clone git@github.com:<kullanici-adi>/<repo-adi>.git
   cd <repo-adi>
   ```

2. Mevcut ayar dosyalarını bu depodan kullanmak için (örnek, zsh):

   ```bash
   # Eski dosyayı yedekle
   mv ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d-%H%M)

   # Bu depodaki dosyaya symlink oluştur
   ln -s "$(pwd)/zsh/.zshrc" ~/.zshrc
   ```

3. Bash için:

   ```bash
   mv ~/.bashrc ~/.bashrc.backup-$(date +%Y%m%d-%H%M)
   ln -s "$(pwd)/bash/.bashrc" ~/.bashrc
   ```

### Notlar

- Bu depo *sadece* elle seçtiğim ayar dosyalarını içerecek, cache/log/secrets gibi şeyleri **özellikle** eklemeyeceğim.
- Yeni config eklemek istediğimde önce burada düzenleyip sonra sisteme symlink ile bağlayacağım.
