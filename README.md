# Setup Void Linux — i3 Nord ou XFCE

Instalador experimental para Void Linux, sem particionamento, alterações de bootloader ou reboot. **Padrão: i3**. Não testado em máquina Void real.

## Uso

```bash
bash bootstrap.sh --plan --desktop=i3
bash bootstrap.sh --apply --desktop=i3
```

Para XFCE, substitua por `--desktop=xfce`. `--plan` não instala pacotes nem altera o desktop, mas cria diretório de estado e log. `--apply` exige sudo e confirmação `APLICAR`.

O perfil i3 instala Xorg, i3, Polybar, Rofi, Dunst, Alacritty, feh, xinit e Thunar; aplica os arquivos Nord em `config/` por symlinks, preservando configurações existentes. Se `~/.xinitrc` não existir, cria `exec dbus-run-session i3`. Inicie manualmente com `startx`. O tema é escuro, sem compositor e sem animações. O papel de parede ainda precisa ser configurado pelo usuário.

O perfil XFCE instala XFCE e LightDM, mas não habilita LightDM automaticamente. Ambos instalam componentes básicos de rede e áudio. O script cria symlinks runit para dbus, elogind e NetworkManager **apenas** se não detectar serviços concorrentes; não desativa rede existente.

## Limitações

O script ainda não implementa zram, drivers específicos de hardware, rollback ou migração automática entre gerenciadores de rede. Se ocorrer erro após instalar pacotes, alterações anteriores permanecem. Logs em `~/.local/state/linux-autosetup/`; revise dados sensíveis antes de compartilhar.

## Referências
- https://docs.voidlinux.org/config/services/index.html
- https://docs.voidlinux.org/config/network/networkmanager.html
- https://docs.voidlinux.org/config/graphical-session/xorg.html
- https://docs.voidlinux.org/config/media/pipewire.html

## Temas i3 (Nord padrão)

O instalador usa **Nord** por padrão no perfil i3. Os arquivos de tema gerados cobrem i3, Polybar, Rofi, Dunst e Alacritty. Para trocar o tema **sem reinstalar pacotes**:

```bash
git pull
bash scripts/theme.sh nord --plan
bash scripts/theme.sh nord --apply
# outras opções:
bash scripts/theme.sh gruvbox --apply
bash scripts/theme.sh solarized --apply
```

O script preserva arquivos de configuração existentes em `~/.local/state/linux-autosetup/theme-backups/` antes de substituir os caminhos; symlinks anteriores são redirecionados. Confira o `--plan` e mantenha backups externos das suas personalizações. O tema é aplicado em arquivos; para ver o resultado no i3, pressione **Super+Shift+C**, reinicie Polybar (`pkill -x polybar; polybar main &`) e reabra Rofi/Alacritty. Dunst pode precisar reiniciar. O gerador também configura GTK escuro (Arc-Dark), ícones Papirus-Dark, cursor Adwaita e fonte DejaVu Sans 10 quando o conjunto visual está instalado. Wallpaper e interfaces próprias dos aplicativos precisam de configuração específica. O script não faz rollback automático.

## Auditoria e correções do desktop

Consulte [a auditoria de 27/10/2026](docs/desktop-audit.md) para monitores, correções de Rofi/Polybar, backups, validação e configuração aprovada de HDMI exclusivo com fallback para a tela interna no início da sessão. A bandeja usa Polybar 3.7 ou superior.

## Complementação do sistema

[A auditoria de hardware, áudio, vídeo, sessão e temas](docs/system-audit-20261027.md) registra lacunas confirmadas, pacotes propostos e etapas de implementação pendentes de aprovação. Nenhum pacote ou serviço foi alterado nessa auditoria.

## Complementação aprovada do i3

[Implementação, atalhos, instalação e validação](docs/desktop-completion.md). Pacotes instalados e configurações aplicadas; falta refazer o login no TTY para registrar a sessão e validar áudio e autenticação gráfica. A lista reproduzível está em `packages/desktop-essential.txt`.

## Ajustes de uso diário

- [Neovim para Python, Yazi Nord, Obsidian e Anki](docs/python-e-estudos.md).
- [Captura, teclado US intl, clipboard e menu de energia](docs/desktop-extras.md).
- [Polybar com paleta Nord e ícones FontAwesome](docs/polybar-nord.md).
- [Zram opcional, configurada separadamente do bootstrap](docs/zram.md).

```bash
bash scripts/setup-desktop-extras.sh
bash scripts/setup-polybar-icons.sh
# Opcional: swap comprimida com início automático
bash scripts/setup-zram.sh
```

Atalhos: Print ou Super+Shift+S para captura, Super+Shift+V para histórico
de textos, Super+Shift+P para energia e Super+Ctrl+L para bloquear.
O bloqueio automático usa a opção local documentada em desktop-extras.md.
Backups locais em backups/ não são versionados.
