GIRIŞ EKRANI (GREETD) DÜZELTMESİ
================================

Sorun 1: "uwsm-start" yoktu; girişten sonra oturum açılmıyordu.
Sorun 2: "Hyprland started without start-hyprland" uyarısı.

Yapılan değişiklik:
- Oturum artık doğrudan start-hyprland ile başlıyor (uwsm yok).
- Komut: --cmd '/usr/bin/start-hyprland'
- Ek: --asterisks (şifre alanında yıldız)
- Bu sayede start-hyprland uyarısı da kaybolur.

UYGULAMA (tek sefer, terminalde):

  sudo cp "~/dotfiles/greetd-config-fix/config.toml" /etc/greetd/config.toml

Ardından greetd’i yeniden başlat (isteğe bağlı):

  sudo systemctl restart greetd

Sonra çıkış yapıp tekrar giriş yap; kullanıcı adı ve şifre ile Hyprland açılmalı.
