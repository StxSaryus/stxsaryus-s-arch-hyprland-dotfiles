# Daha hızlı açılış (loader ~11 sn → hedef ~3–4 sn)

## 1. Initramfs’i küçült (en büyük kazanç)

Şu an initramfs **~285 MB** (NVIDIA modülleri yüzünden). Bunları initramfs’ten çıkarınca dosya ~30 MB’a iner, loader süresi belirgin kısalır.

```bash
sudo cp "~/dotfiles/boot-speed/mkinitcpio-optimized.conf" /etc/mkinitcpio.conf
sudo mkinitcpio -P
```

- NVIDIA sürücüsü açılıştan sonra normal şekilde yüklenecek (Hyprland/Wayland zaten öyle kullanıyor).
- Kernel parametresinde `nvidia_drm.modeset=1` varsa (Hyprland için önerilir) aynen kalabilir; gerekirse bootloader entry’sine ekleyin.

## 2. Bootloader bekleme süresini kısalt

**systemd-boot** kullanıyorsan:

```bash
echo 'timeout 1' | sudo tee -a /boot/loader/loader.conf
# veya menü istemiyorsan:
echo 'timeout 0' | sudo tee -a /boot/loader/loader.conf
```

**GRUB** kullanıyorsan:

```bash
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 3. Sonuç

- `systemd-analyze` ile tekrar ölç: **loader** süresi 11 sn civarından 3–4 sn’e inebilir.
- Sorun olursa (siyah ekran / NVIDIA yüklenmiyor):  
  `sudo cp /etc/mkinitcpio.conf.bak /etc/mkinitcpio.conf && sudo mkinitcpio -P`  
  (önce yedek al: `sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak`)
