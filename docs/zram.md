# Zram no Void

Inspeção: 7,7 GiB de RAM, 6,7 GiB disponíveis, sem swap e sem pressão
PSI de memória no momento da leitura. Zram é uma margem para picos de uso,
não uma correção de lentidão comprovada.

Execute como usuário comum:

```bash
bash ~/setup-voidlinux/scripts/setup-zram.sh
```

O script instala zramen, salva a configuração anterior em /var/backups/
linux-autosetup e habilita o serviço runit. Usa 25% da RAM com teto de
2048 MiB e compressão lz4. Não reserva imediatamente esse volume de RAM.
Não altera partições, fstab, boot ou parâmetros sysctl. Não oferece
hibernação. Preserva configurações caso detecte zram ativa ou serviço
já habilitado.

Validação:

```bash
swapon --show
zramctl
```

Para desabilitar (com memória livre suficiente para retirar a swap):

```bash
sudo sv down /var/service/zramen
sudo rm /var/service/zramen
```

Referências:
- https://docs.kernel.org/admin-guide/blockdev/zram.html
- https://github.com/atweiden/zramen/tree/1.0.1/sv/zramen
