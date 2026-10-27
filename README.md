# Setup Void Linux — i3 Nord ou XFCE

Instalador experimental para Void Linux, sem particionamento, alterações de bootloader ou reboot. **Padrão: i3**. Não testado em máquina Void real.

## Uso

```bash
bash bootstrap.sh --plan --desktop=i3
bash bootstrap.sh --apply --desktop=i3
```

Para XFCE, substitua por `--desktop=xfce`. `--plan` não modifica arquivos. `--apply` exige sudo e confirmação `APLICAR`.

O perfil i3 instala Xorg, i3, Polybar, Rofi, Dunst, Alacritty, feh, xinit e Thunar; aplica os arquivos Nord em `config/` por symlinks, preservando configurações existentes. Se `~/.xinitrc` não existir, cria `exec dbus-run-session i3`. Inicie manualmente com `startx`. O tema é escuro, sem compositor e sem animações. O papel de parede ainda precisa ser configurado pelo usuário.

O perfil XFCE instala XFCE e LightDM, mas não habilita LightDM automaticamente. Ambos instalam componentes básicos de rede e áudio. O script cria symlinks runit para dbus, elogind e NetworkManager **apenas** se não detectar serviços concorrentes; não desativa rede existente.

## Limitações

O script ainda não implementa zram, drivers específicos de hardware, rollback ou migração automática entre gerenciadores de rede. Se ocorrer erro após instalar pacotes, alterações anteriores permanecem. Logs em `~/.local/state/linux-autosetup/`; revise dados sensíveis antes de compartilhar.

## Referências
- https://docs.voidlinux.org/config/services/index.html
- https://docs.voidlinux.org/config/network/networkmanager.html
- https://docs.voidlinux.org/config/graphical-session/xorg.html
- https://docs.voidlinux.org/config/media/pipewire.html
