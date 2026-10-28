# Auditoria do desktop — 27/10/2026

Ambiente real: Void Linux, X11/i3, Rofi 2.0.0 e Polybar 3.7.2.
Inspeção somente de leitura do sistema; nenhuma alteração em serviços,
rede, boot, energia, pacotes ou arquivos de /etc. Não foi executado bootstrap.

## Monitores identificados com xrandr --query

| Saída | Estado observado | Modo atual | Posição |
| --- | --- | --- | --- |
| LVDS-1 | Interna, conectada, principal | 1366x768, 59.99 Hz | 0x0 |
| HDMI-1 | Externa, conectada | 1920x1080, 60 Hz | 1366x0 |
| VGA-1 | Desconectada | — | — |
| DP-1 | Desconectada | — | — |

Área total na inspeção inicial: 3286x1080. Após aprovação, passou a 1920x1080. Consulta X exigiu execução
fora do sandbox, que inicialmente retornava `Can't open display :0`.

## Correções aplicadas

- Rofi: a configuração ativa tinha todo o bloco `configuration` em uma linha.
  Nesta instalação, `rofi -help` mostrou o modo inválido `window"; show-icons`.
  Propriedades agora estão em linhas separadas; leitura confirma os modos
  `drun,run,window`, fonte e ícones corretos. Cores explícitas de fundo/texto,
  seleção e widgets filhos transparentes evitam fundos herdados incompatíveis.
- Polybar: não havia processo em execução na inspeção. Configuração agora
  inclui espaçamento entre módulos e bandeja `internal/tray` (Polybar >=3.7),
  seleção padrão do monitor principal, fallback LVDS-1 e recarga quando a
  geometria das telas muda. `MONITOR` permite selecionar outra saída.
  Barra iniciada após correção: log inicial carregou i3, cpu, memory, date e
  tray, além da fonte DejaVu Sans Mono, sem erros.
- `scripts/theme.sh`: corrige também a geração, para que trocar de tema não
  reintroduza os problemas. Agora copia conteúdo ativo, symlinks e diretório
  gerado ANTES de sobrescrever. Antes, reaplicar o mesmo tema destruía o
  conteúdo anterior e removia links sem preservá-los.
- Exemplos versionados de Rofi/Polybar sincronizados com o gerador Nord.
- `scripts/apply-bar-launcher-fixes.sh`: aplica somente Rofi/Polybar, fazendo
  backup do conteúdo e do link antes de gravar no destino existente.
  Usa os exemplos Nord; não o use para preservar outro tema personalizado.

Os links existentes em ~/.config foram preservados; apontam para arquivos em
~/.local/state/linux-autosetup/generated/nord/. Rofi lê a correção na próxima
abertura. Nenhum reload/restart do i3 foi executado; a alteração de layout foi aplicada diretamente pelo script aprovado.

## Backups e restauração

Antes das alterações do repositório:
`backups/before-desktop-fixes-20261027.tar.gz`.

Antes das alterações ativas:
`~/.local/state/linux-autosetup/desktop-fix-backups/20261028T005812-13152/`.
A data do nome está em UTC; localmente ainda era 27/10.
Os arquivos `rofi/config.rasi` e `polybar/config.ini` nesse diretório contêm
os originais; os arquivos `.link` preservam os symlinks.

Para restaurar o conteúdo ativo, copiar os originais sobre os destinos
correspondentes em ~/.config (os symlinks continuam apontando para o mesmo
local). Reiniciar a Polybar depois; Rofi usa o arquivo na próxima abertura.
Para restaurar o repositório, primeiro extrair o tar em diretório temporário
para comparar e copiar apenas os arquivos desejados, preservando trabalho novo.

## Configuração permanente de monitor — APROVADA E APLICADA

`scripts/monitor-external.sh --plan` apenas consulta e imprime a ação.
Com HDMI conectado, `--apply` executa:

```sh
xrandr --output HDMI-1 --mode 1920x1080 --rate 60 --primary --pos 0x0 \
  --output LVDS-1 --off --output VGA-1 --off --output DP-1 --off
```

Sem HDMI conectado, ativa LVDS-1 como principal no modo preferido. Não altera
arquivos Xorg nem configurações de tampa/elogind. O fallback é avaliado na
execução do script, sem monitoramento automático de hotplug.

Após aprovação explícita do usuário, foi feito backup do conteúdo e link da
configuração ativa do i3 e sua linha de inicialização da Polybar foi substituída por:

```i3
exec --no-startup-id sh -c 'bash /home/glover/setup-voidlinux/scripts/monitor-external.sh --apply; exec polybar main'
```

Isso aplica o layout antes da barra em cada nova sessão. A barra também inicia
se o script de monitor falhar. Integração aplicada ao i3 ativo, ao exemplo
`config/i3/config` e ao gerador `scripts/theme.sh`; o gerador resolve o caminho
do repositório na geração. Manter o repositório neste local para a configuração
ativa continuar funcionando. Não exige serviço runit.

Layout aplicado na sessão atual após aprovação: `xrandr --query` confirmou
`HDMI-1 connected primary 1920x1080+0+0`, 60 Hz, e LVDS-1 sem modo ativo.
`xrandr --listactivemonitors` confirmou exatamente um monitor: HDMI-1.
Polybar confirmada em execução após a transição, com cinco módulos carregados.
O log registrou erro XCB_WINDOW ao incorporar uma janela cliente da bandeja;
a barra permaneceu ativa. A integração visual desse cliente não foi confirmada.

Backup adicional do repositório:
`backups/before-monitor-integration-20261027.tar.gz`.
Backup do i3 ativo (conteúdo, symlink, candidato validado e xrandr anterior):
`~/.local/state/linux-autosetup/monitor-backups/20261028T010206624541Z/`.
Para desfazer a persistência, copiar `config.content` desse backup sobre
`~/.config/i3/config` e restaurar a linha anterior nos exemplos/gerador.

Recuperação manual do layout observado:

```sh
xrandr --output LVDS-1 --auto --primary --pos 0x0 \
  --output HDMI-1 --mode 1920x1080 --rate 60 --pos 1366x0
```

## Validação realizada e limites

- `bash -n` nos scripts e bootstrap; `i3 -C` no exemplo e na geração Nord.
- `rofi -config ... -dump-config` e `-dump-theme`: leitura sem erro;
  modos, fonte, ícones e cores conferidos. Sem teste visual interativo.
- Polybar `--dump=modules-right`: `cpu memory date tray`.
- Execução real da Polybar e log inicial em `/tmp/setup-void-polybar.log`.
- Duas aplicações Nord em HOME/XDG_STATE_HOME temporários: exemplos iguais
  aos gerados e backups de links, conteúdo e geração anterior preservados.
- `git diff --check` sem erros. ShellCheck não instalado.
- Script de monitor validado sintaticamente e aplicado com HDMI conectado;
  integração i3 ativa e gerada passou em `i3 -C`. Fallback sem HDMI e hotplug
  não foram testados fisicamente.

## Outros achados para revisão futura

O bootstrap instala pacotes e habilita dbus/elogind/NetworkManager após sua
confirmação genérica `APLICAR`; não foi executado nesta auditoria. Seu `--plan`
e o de temas criam diretório de estado/log, apesar de o README anterior dizer
que não modificam arquivos. Não há rollback transacional da instalação.
O exemplo i3 referencia um wallpaper possivelmente ausente, enquanto o gerador
não configura wallpaper nem nm-applet. Esses pontos foram documentados sem
alterar serviços, rede ou preferências adicionais do desktop.

## Referências técnicas

- https://github.com/davatorium/rofi/blob/next/doc/rofi-theme.5.markdown
- https://polybar.readthedocs.io/en/latest/user/modules/tray.html
- https://github.com/polybar/polybar/wiki/Configuration
