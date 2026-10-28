# Auditoria do sistema e plano de complementação — 27/10/2026

Escopo: inventário de hardware, pacotes, serviços habilitados, processos,
sessão X11/i3, áudio, vídeo e integração visual. Nenhum pacote instalado,
serviço modificado, rede alterada ou configuração ativa escrita nesta etapa.
Não equivale a teste físico completo, diagnóstico de segurança ou teste SMART.

## Hardware e base já funcionais

- Dell, Intel Core i3-2310M 2.10 GHz, 2 núcleos/4 threads, Intel HD 3000
  (Sandy Bridge), 7.7 GiB de RAM. Disco sda de 223.6 GiB não rotacional.
- Kernel 6.18.59_1; i915 carregado; firmware Intel e mesa-dri instalados.
  Log do Xorg confirma modesetting, glamor/OpenGL 3.3, DRI3 e Crocus.
  A tentativa anterior de carregar o módulo Xorg `intel` falha, mas o fallback
  modesetting inicializa aceleração: isso não justifica trocar o driver.
- Áudio HDA Intel PCH com snd_hda_intel carregado e placa reconhecida pelo ALSA.
- Ethernet Realtek com r8169 e Wi-Fi Intel Wireless-N 1030 com iwlwifi.
  Presença do driver não comprova conexão Wi-Fi funcional.
- Webcam Dell HD USB e leitor Realtek reconhecidos no USB; captura não testada.
  Nenhum adaptador Bluetooth apareceu no inventário USB/PCI.
- HDMI-1 único monitor ativo, 1920x1080; configuração aprovada anteriormente.
- Xorg, i3, Rofi, Dunst, Alacritty, Thunar, Firefox, feh, fontes DejaVu,
  PipeWire, WirePlumber, pavucontrol, polkit e ícones Adwaita já instalados.
- Raiz: 53 GiB livres; /home: 151 GiB livres no momento da inspeção.
  Sem swap. Locale pt_BR.UTF-8 e timezone America/Sao_Paulo configurados.

## Problemas confirmados e prioridade

| Prioridade | Evidência | Ação proposta |
| --- | --- | --- |
| 1 | `pactl info` recusou conexão; `wpctl status` não conectou; nenhum processo PipeWire/WirePlumber | Corrigir sessão e iniciar PipeWire como usuário |
| 1 | XDG_RUNTIME_DIR ausente no ambiente real do i3 e Firefox; `loginctl list-sessions`: nenhuma sessão | Investigar PAM/login/elogind; corrigir origem da sessão antes de iniciar áudio |
| 1 | Link WirePlumber existente, mas sem 20-pipewire-pulse.conf | Adicionar interface PulseAudio do PipeWire, com backup |
| 2 | Sem i3lock, xss-lock ou atalhos de bloqueio | Instalar e integrar bloqueio manual/antes de suspensão, após testar |
| 2 | Polkit instalado, sem agente gráfico em execução | Instalar polkit-gnome e iniciar seu agente na sessão |
| 2 | Sem xdg-utils, gvfs, udisks2 ou tumbler | Integrar abertura de arquivos, montagem e miniaturas no Thunar |
| 2 | Sem mpv, ffmpeg, libva-intel-driver ou vainfo | Instalar reprodução local e testar decodificação VA-API i965 |
| 3 | Sem settings.ini GTK, tema externo ou xsettingsd | Integrar GTK, ícones, cursor e fonte ao gerador de temas |
| 3 | i3 sem atalhos de volume, reprodução, brilho, redimensionamento ou troca de tema | Acrescentar comandos e modo resize; sincronizar exemplo e gerador |

`dbus`, `elogind` e `dhcpcd` têm links habilitados e processos observados.
`sv status` não pôde ler supervise/ok sem privilégio; não foi elevado a root.
Usuário real pertence a audio, video e wheel: não há evidência para alterar
seus grupos. O sandbox apresenta grupos diferentes, por isso a conferência
foi repetida fora dele. D-Bus de usuário existe; .xinitrc usa dbus-run-session.

## Plano concreto para aprovação

### Etapa A — sessão, som e funcionamento básico

1. Inspecionar PAM de login e elogind, permissões de /run/user e logs
   disponíveis, sem gravar. Apresentar a correção específica de PAM/elogind
   para aprovação caso seja necessária. Não criar XDG_RUNTIME_DIR em /tmp
   nem exportar um caminho sem conferir proprietário/permissões.
2. Com sessão válida, preservar configs e adicionar o symlink por usuário
   `~/.config/pipewire/pipewire.conf.d/20-pipewire-pulse.conf` para o exemplo
   em `/usr/share/examples/pipewire/`. O link 10-wireplumber.conf já existe.
3. Iniciar somente `pipewire` na sessão do usuário; ele iniciará WirePlumber e
   sua interface PulseAudio. Não criar serviço de áudio global runit nem
   instalar outro servidor PulseAudio. Validar antes de incluir no autostart.
4. Instalar o conjunto básico abaixo e integrar agente polkit, atalhos de
   volume/mute com wpctl, playerctl, bloqueio e modo de redimensionamento.
   Não substituir a configuração de monitores aprovada.

Conjunto básico proposto, ausente e com nomes confirmados em `xbps-query -R`:

```text
mpv ffmpeg libva-intel-driver libva-utils mesa-demos
polkit-gnome gvfs udisks2 tumbler file-roller unzip zip
xdg-utils xdg-user-dirs i3lock xss-lock playerctl brightnessctl
```

Esses pacotes não são todos requisitos de boot: compõem um desktop prático.
Antes de instalar, simular a transação e revisar dependências/serviços envolvidos.
Não habilitar ou substituir serviços automaticamente. A montagem via udisks2
pode envolver ativação por D-Bus; revisar isso na aprovação da etapa.

`alsa-pipewire` é complemento para aplicativos ALSA, não requisito para Firefox
ou mpv usarem a interface PulseAudio. Sua configuração global em /etc/alsa
será uma ação separada, se necessária. pavucontrol e utilitários PulseAudio
já estão instalados e serão reaproveitados.

### Etapa B — aparência consistente

Conjunto visual sugerido, também ausente e confirmado nos repositórios:

```text
lxappearance xsettingsd arc-theme papirus-icon-theme
gnome-themes-extra noto-fonts-ttf noto-fonts-emoji
```

Padrão inicial proposto: Nord para componentes já gerados, Arc-Dark para GTK,
Papirus-Dark para ícones, cursor Adwaita existente e DejaVu Sans 10 para GUI.
Isso oferece consistência escura, mas Arc-Dark não é uma reprodução exata da
paleta Nord. Para identidade Nord exata nas aplicações GTK, será preciso
selecionar e revisar um tema compatível; não baixar temas aleatórios.

Implementação proposta no repositório, com backups:

- Estender o gerador para GTK 2/3, XSettings, cursor e preferência escura de
  aplicativos modernos, preservando configurações não relacionadas.
- Usar xsettingsd como responsável por XSettings e evitar gerenciadores
  concorrentes. lxappearance funciona como interface de escolha.
- Adicionar menu Rofi de temas para Nord/Gruvbox/Solarized; o comando aplicará
  o tema e recarregará apenas os componentes necessários, sem reinstalação.
- Manter esquema de ícones/fonte/cursor consistente nos três temas; mapear
  GTK para temas realmente instalados e documentar diferenças de paleta.
- Não sobrescrever gtk.css de GTK4/libadwaita indiscriminadamente. Preferência
  escura não garante que todos os aplicativos aceitem o mesmo tema.
- Qt: não foi identificada necessidade de instalar bibliotecas Qt apenas
  para temas. Quando houver aplicativos Qt, avaliar qt5ct/qt6ct e Kvantum;
  a seleção de plugin varia com a versão. Não exportar uma única variável
  QT_QPA_PLATFORMTHEME às cegas para ambas as versões.
- Firefox tem interface e páginas com preferências próprias; páginas web,
  aplicativos Electron e decorações próprias não obedecem todas ao i3.

Não é tecnicamente garantido que TODAS as janelas fiquem idênticas: bordas
são controladas pelo i3, conteúdo por GTK/Qt ou pelo próprio aplicativo.
É possível padronizar cores, fontes, ícones, cursor e preferência escura.

### Etapa C — opcionais e manutenção, aprovação separada

- `picom`: apenas se houver tearing ou desejo de sombras; testar custo na
  HD 3000, inicialmente sem blur, animações ou transparência.
- `xdg-desktop-portal` + `xdg-desktop-portal-gtk`: integração de aplicativos
  que utilizam portais. Em X11/i3 isso não garante suporte de captura de tela
  equivalente ao de um compositor Wayland; validar o aplicativo concreto.
- `smartmontools` e `lm_sensors`: verificar disco/temperaturas. Não houve
  teste SMART nem sensores; não afirmar saúde do hardware só pelo espaço livre.
- Sem swap: avaliar zram/swap conforme uso. Não há pressão de memória atual
  que justifique alterar imediatamente; requer aprovação por mudar o sistema.
- Sem serviço de sincronização de hora identificado: avaliar `chrony`, com
  aprovação antes da instalação/ativação. Fuso correto não garante hora certa.
- Microcode atual 0x1b; intel-ucode não instalado nem confirmado no repositório
  configurado. Avaliar repositório nonfree e procedimento de atualização,
  sem modificar repositórios, initramfs ou boot sem aprovação específica.
- SSD detectado: conferir TRIM suportado e agendamento; não foi executado fstrim.
- Bluetooth, impressão, LibreOffice, jogos e serviços de descoberta são
  opcionais conforme uso; não instalar conjuntos inteiros sem necessidade.

## Rede e energia preservadas

NetworkManager instalado, mas não em execução nem habilitado; dhcpcd ativo.
O nm-applet observado não implica NetworkManager funcional. Não habilitar
NetworkManager por cima de dhcpcd. Migração de rede exige plano e aprovação
separados e pode interromper a conexão atual.

Apenas alimentação AC apareceu em /sys/class/power_supply; não foi detectada
bateria. Não há motivo comprovado para instalar gerenciador de bateria.
Suspensão, tampa, teclado multimídia e brilho não foram testados fisicamente.

## Validação após implementação aprovada

- `loginctl` reconhece a sessão quando elogind for o mecanismo escolhido;
  XDG_RUNTIME_DIR existe, pertence ao usuário e tem permissões adequadas.
- `wpctl status` mostra dispositivos reais; `pactl info` identifica PipeWire;
  testar som interno/HDMI, microfone e troca de saída no pavucontrol.
- `glxinfo -B` confirma renderer Intel; `LIBVA_DRIVER_NAME=i965 vainfo`
  confirma perfis efetivamente suportados; mpv testa vídeo H.264 e áudio.
  Não esperar aceleração moderna de HEVC/VP9/AV1 da HD 3000; validar formatos
  e desempenho em vez de forçar opções de Firefox globalmente.
- `i3 -C`, `bash -n`, leitura do Rofi e carga dos módulos da Polybar.
- Testar bloqueio e desbloqueio manual antes de automatizar suspensão.
- Abrir Thunar, pavucontrol e Firefox para conferir aparência; conferir
  associação MIME, montagem autorizada e miniaturas com arquivos de teste.
- Validar geração dos três temas em HOME temporário e preservação de backups.

## Limites e rastreabilidade

Consulta de dispositivos/processos/sessão feita fora do sandbox quando
necessário. Não foram lidos conteúdos privados do navegador; só variáveis
selecionadas de sessão de i3/Firefox e nomes de arquivos/configurações.
Não foi feita atualização dos índices, instalação, reprodução audível,
reinício de sessão, mudança de PAM, teste de câmera ou alteração de rede.
Não há glxinfo/vainfo disponíveis para testes adicionais sem instalar pacotes.
Nesta inspeção não havia Polybar em execução; ela funcionou na etapa anterior,
mas sua persistência precisa ser verificada ao implementar o autostart completo.

Backup dos documentos antes desta etapa:
`backups/before-system-audit-20261027.tar.gz`.

Fontes primárias consultadas:

- https://docs.voidlinux.org/config/media/pipewire.html
- https://docs.voidlinux.org/config/graphical-session/graphics-drivers/intel.html
- https://docs.voidlinux.org/config/session-management.html
- https://github.com/intel/intel-vaapi-driver
- https://docs.gtk.org/gtk3/class.Settings.html
- https://docs.gtk.org/gtk4/class.Settings.html
- https://developer.gnome.org/hig/guidelines/ui-styling.html
