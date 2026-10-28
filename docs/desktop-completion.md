# Complementação aprovada do i3 — 27/10/2026

O usuário aprovou os conjuntos básico e visual da auditoria. Foram preparados
os scripts e as configurações abaixo. A instalação real ainda depende da
senha sudo no terminal do usuário: a tentativa `sudo -n xbps-install ...`
retornou `sudo: a password is required`. Não fornecer senha no chat.
Não foram alterados PAM, serviços runit, rede, initramfs ou boot.

## Estado e evidência

- Simulação XBPS aprovada tecnicamente: somente novas instalações e
  dependências, sem remoções ou atualizações dos pacotes instalados.
  Inclui bibliotecas GTK2 e libadwaita por dependência; não instala outro
  ambiente desktop nem habilita NetworkManager.
- Pacotes solicitados em `packages/desktop-essential.txt`. Nenhum deles foi
  instalado pela tentativa que exigiu senha.
- Login original no TTY: 07:18:20. Elogind e D-Bus de sistema iniciados às
  20:34:13; i3 às 20:39:39. `pam_elogind.so` já consta no system-login e o
  arquivo do módulo está instalado. Provável causa da sessão sem registro:
  o login precede elogind. Primeiro refazer login; não editar PAM sem evidência.
- Novo gerador validado para Nord, Gruvbox e Solarized, com duas aplicações
  de cada, em HOME temporário. `i3 -C`, leitura do tema Rofi, preservação de
  valores GTK não relacionados e backup de conteúdo/links passaram.
- Exemplos versionados de i3, Rofi e Polybar sincronizados com a geração Nord.
- Configurações ativas ainda não receberam esta etapa enquanto faltam pacotes.

## Aplicar após a instalação

No terminal do usuário, a partir deste repositório:

```bash
bash scripts/install-desktop-packages.sh --plan
bash scripts/install-desktop-packages.sh --apply
bash scripts/complete-desktop.sh --plan
bash scripts/complete-desktop.sh --apply
bash scripts/reload-desktop.sh
```

O instalador de pacotes pede sudo, registra inventário antes/depois e a
simulação em `~/.local/state/linux-autosetup/package-records/`. Não atualiza
índices nem executa upgrade global. Se pacotes não estiverem mais disponíveis,
revisar a transação antes de atualizar índices; não ignorar erros.

`complete-desktop.sh` bloqueia aplicação se algum pacote aprovado estiver
ausente. Com dependências presentes, preserva `.xinitrc`, associações MIME e
configuração de áudio, aplica o tema atual e cria a interface PulseAudio de
PipeWire por usuário. Se já existir configuração dessa interface, preserva
seu conteúdo em vez de sobrescrever. Altera `.xinitrc` somente quando encontra
exatamente a forma original `exec dbus-run-session i3`, adicionando a identidade
i3 ao ambiente; arquivos personalizados ficam preservados.

Após salvar os aplicativos, sair do i3 e **encerrar o login do TTY**, entrar
novamente e executar `startx`. Só sair e abrir o i3 de novo não recria o login
PAM. Não foi encerrada nenhuma sessão automaticamente.

## Comportamento configurado

- `session-start.sh`: inicia xsettingsd, Dunst, agente polkit e PipeWire como
  usuário, evitando duplicatas. PipeWire só inicia com runtime pertencente ao
  usuário, modo 0700 e sem symlink. Se faltar, registra motivo em session.log;
  não inventa diretório em /tmp nem altera elogind. PipeWire inicia seus
  componentes por seus arquivos .conf, em vez de lançar tudo em paralelo.
- `bar-start.sh`: inicia somente uma Polybar por usuário; mantém lock de
  inicialização e log em polybar.log. Lançamento ordenado após o monitor.
- Polybar ganha volume, indicação de mute e pavucontrol no clique direito.
- GTK2/3 usa Arc-Dark, ícones Papirus-Dark, cursor Adwaita 24 e fonte DejaVu
  Sans 10. GTK4 recebe fonte/ícones/cursor e preferência escura por GSettings;
  não recebe CSS GTK3 forçado. Todos os três temas mantêm essa base visual;
  as paletas dos componentes i3 continuam Nord/Gruvbox/Solarized.
- `apply-visual.sh` preserva valores INI não relacionados e faz backup dos
  arquivos e valores GSettings antes da gravação. Pode reorganizar comentários
  e formatação dos arquivos INI; conteúdo original fica no backup.
- Vídeos e formatos de áudio listados no script usam mpv como padrão. Sem
  alterações nas associações de documentos, navegador ou imagens.

| Atalho | Ação |
| --- | --- |
| Super+Shift+T | Menu de temas no Rofi |
| Super+E | Thunar |
| Super+Ctrl+L | Bloqueio manual |
| Super+R | Modo de redimensionamento: H/J/K/L; Enter/Escape para sair |
| Teclas de volume/mute | Controle da saída de áudio padrão |
| Tecla de microfone | Mute do microfone padrão |
| Teclas multimídia | Play/pause, próxima e anterior via playerctl |
| Teclas de brilho | Brilho interno via brightnessctl; não controla a TV HDMI |

O menu de temas aplica os arquivos, recarrega i3 e XSettings, recarrega Dunst
e reinicia a Polybar do usuário, aguardando liberação da bandeja. Aplicativos
com configurações próprias ou sem recarga dinâmica podem precisar reabrir.
`reload-desktop.sh` inicia processos via i3 para ficarem ligados à sessão.

## Bloqueio automático: teste antes de habilitar

O bloqueio manual está configurado; a automação antes de suspensão permanece
inativa até testar desbloqueio com sua senha. Não foi bloqueada a tela durante
a instalação. Depois de testar Super+Ctrl+L e desbloquear, habilitar com:

```bash
mkdir -p ~/.local/state/linux-autosetup
touch ~/.local/state/linux-autosetup/enable-sleep-lock
bash scripts/session-start.sh
```

O marcador faz iniciar xss-lock nas sessões com runtime válido. Se elogind
continuar sem registrar sessão, resolver isso antes de confiar em suspensão.

## Verificação real pendente

```bash
loginctl list-sessions
printf '%s\n' "$XDG_RUNTIME_DIR"
wpctl status
pactl info
pactl list short sinks
glxinfo -B
LIBVA_DRIVER_NAME=i965 vainfo
xdg-mime query default video/mp4
```

Testar reprodução local e som nas saídas interna/HDMI no pavucontrol, microfone,
miniaturas e montagem autorizada no Thunar. A HD3000 requer o driver legado
i965 para VA-API; não foi imposto driver global nem ativado Vulkan/HEVC/AV1.
Não houve validação real desses recursos porque a instalação depende de sudo.

Se após novo login ainda não existir sessão/runtime válido, revisar logs e
propor a mudança específica em PAM/elogind antes de aplicar. Serviços e rede
continuam sujeitos a aprovação separada.

## Backups e restauração

Backup do repositório antes das alterações:
`backups/before-desktop-completion-20261027.tar.gz`.

Ao aplicar, os backups de tema ficam em
`~/.local/state/linux-autosetup/theme-backups/<data>-<pid>/`:
`content/` guarda configs dos componentes, `links/` guarda os caminhos antigos,
`generated/` guarda a geração anterior e `visual/` guarda GTK/XSettings/cursor.
O arquivo `visual/gsettings.json` registra preferências anteriores. Arquivos
`.absent` indicam que o caminho não existia antes.

Para restaurar, copiar o conteúdo original para cada destino, restaurar links
se necessário e remover somente arquivos marcados como ausentes originalmente,
após revisão. Restaurar valores GSettings com `gsettings set` conforme JSON.
`.xinitrc` e MIME ficam em `completion-backups/`. Recarregar o desktop depois.
Pacotes instalados não são removidos automaticamente: revisar o inventário e
as dependências antes de qualquer desinstalação.

Referências: [PipeWire no Void](https://docs.voidlinux.org/config/media/pipewire.html),
[sessão no Void](https://docs.voidlinux.org/config/session-management.html),
[gráficos Intel](https://docs.voidlinux.org/config/graphical-session/graphics-drivers/intel.html).

## Atualização — aplicação efetiva às 22:45 (27/10)

Pacotes do manifesto confirmados instalados. `complete-desktop.sh --apply`
concluído e desktop recarregado via i3; configuração ativa passou em `i3 -C`.
Backups efetivos:

- `theme-backups/20261028T014530-19201/`
- `completion-backups/20261028T014529-19158/`

Caminhos relativos a `~/.local/state/linux-autosetup/`.
XSettings em execução, preferência GSettings `prefer-dark` e associação de
video/mp4 para `mpv.desktop` confirmadas. Polybar em execução. VA-API i965
inicializou via X11 e listou decodificação H.264, MPEG2 e VC1. `glxinfo` não
foi encontrado mesmo com mesa-demos instalado; esse teste permanece pendente.

A sessão antiga ainda não possui runtime/registro elogind. O agente polkit
encerrou com `No session for pid`; o módulo de volume da Polybar foi desativado
por ausência do servidor de áudio. É necessário encerrar o login no TTY e
entrar novamente. O início da barra agora aguarda até cinco segundos pela
interface PulseAudio quando existe runtime, evitando a corrida de inicialização.
Após novo login, validar áudio/polkit e teste manual de bloqueio. Não foi
reproduzido som nem bloqueada ou encerrada a sessão automaticamente.
