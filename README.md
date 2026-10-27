# Linux AutoSetup — Void Linux + XFCE

Instalador pós-instalação experimental para Void Linux (preferencialmente glibc). Não formata discos nem modifica bootloader.

## Executar

```bash
bash bootstrap.sh --plan
bash bootstrap.sh --apply
```

O modo `--plan` apresenta pacotes e estado de serviços sem alterações. O modo `--apply` pede confirmação, instala Xorg, XFCE, LightDM, rede, áudio e ferramentas, e cria links runit de `dbus`, `elogind` e `NetworkManager` quando não encontra conflitos. O script **não desativa** gerenciadores de rede existentes. `LightDM` permanece desabilitado até validação manual.

## Falhas e segurança

Em caso de falha, o script interrompe as etapas seguintes e registra o erro em `~/.local/state/linux-autosetup/`. Pacotes e links já aplicados **não são revertidos automaticamente**. Antes de reexecutar, examine o log. A execução preserva symlinks existentes e bloqueia links conflitantes. Não executa alterações de kernel nem instala drivers proprietários por detecção automática.

**Ainda não testado em Void real.** Confirme os nomes dos pacotes e compatibilidade da versão instalada. Não publique logs sem remover informações sensíveis.

## Documentação oficial
- https://docs.voidlinux.org/config/services/index.html
- https://docs.voidlinux.org/config/network/networkmanager.html
- https://docs.voidlinux.org/config/graphical-session/xorg.html
- https://docs.voidlinux.org/config/media/pipewire.html
