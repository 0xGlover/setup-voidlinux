# Captura, teclado e menus

Execute no terminal gráfico, como usuário comum:

```bash
bash ~/setup-voidlinux/scripts/setup-desktop-extras.sh
```

Instala flameshot e clipmenu com suas dependências, aplica US intl e
recarrega o i3. Não altera serviços de sistema. Registra a transação em
~/.local/state/linux-autosetup/package-records/.

- Print ou Super+Shift+S: selecionar uma área no Flameshot.
- Dentro da captura: Ctrl+C copia, Ctrl+S salva, Esc cancela.
- Super+Shift+V: histórico de textos copiados, no Rofi.
- Super+Shift+P: menu de energia no Rofi.
- Super+Ctrl+L: bloqueio manual já existente.

O histórico coleta apenas a seleção clipboard (copiar explicitamente),
com limite aproximado de 100 entradas, no diretório privado de runtime da
sessão. O bloqueio automático foi configurado posteriormente: 10 minutos de
inatividade e antes da suspensão, via xss-lock/i3lock. A opção fica em
~/.local/state/linux-autosetup/enable-sleep-lock. Suspender pelo menu bloqueia
primeiro; desligar, reiniciar e sair exigem confirmação no menu.

O teclado usa layout us, variante intl, preservando opções XKB existentes.
Acentos são teclas mortas: apóstrofo depois a produz á; til depois a produz
ã. Para apóstrofo isolado, pressione apóstrofo e espaço. Alt direito+vírgula
produz ç. Aplica no início/reload do i3; não altera o teclado do console TTY.

Configurações do i3 e gerador de temas foram sincronizados. O backup
anterior está em ~/.local/state/linux-autosetup/extras-backups/.

## Bloqueio automático

Após esta alteração, execute no terminal gráfico:

```bash
bash ~/setup-voidlinux/scripts/session-start.sh
```

Nos próximos logins, o início é automático. Tempo: 600 segundos, configurado
por `xset s 600 600`. Para bloquear manualmente: Super+Ctrl+L. Para
interromper o bloqueio automático e impedir o início nos próximos logins:

```bash
rm -f ~/.local/state/linux-autosetup/enable-sleep-lock
pkill -u "$(id -u)" -x xss-lock
```

A interface gráfica e o desbloqueio precisam ser testados na sessão real.
