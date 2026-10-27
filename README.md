# Linux AutoSetup — Void Linux + XFCE (protótipo seguro)

Implementação inicial para **Void glibc**. Não formata discos, não modifica bootloader, não habilita serviços e não reinicia automaticamente. Requer conexão de rede para instalar pacotes.

## Rodar

```bash
bash bootstrap.sh --plan
bash bootstrap.sh --apply
```

O modo `--plan` não instala pacotes. O modo `--apply` pede confirmação explícita, valida a existência dos pacotes no índice XBPS e solicita privilégios via sudo. Ambos salvam logs em `~/.local/state/linux-autosetup/`.

**Limitações:** a auditoria de hardware é informativa. Este script ainda **não** escolhe drivers especializados nem otimiza a máquina automaticamente. Os nomes/disponibilidade dos pacotes devem ser verificados na versão atual do Void. Em falhas o Bash interrompe etapas posteriores, mas o XBPS pode ter instalado parte dos pacotes; **não há rollback transacional**. Consulte o log e o banco XBPS antes de retomar. Revise os serviços necessários em `/etc/sv` e seus links em `/var/service` antes de habilitar dbus, elogind, NetworkManager e LightDM.

Nunca envie logs brutos publicamente sem remover hostnames, endereços MAC, serial e outros dados sensíveis.
