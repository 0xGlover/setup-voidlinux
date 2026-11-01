# Void limpo → Niri + Dux Shell

Pós-instalação para **Void x86_64 com glibc**, já instalado no disco e iniciado
normalmente, com internet e usuário comum com sudo. Não é um instalador de
disco: particionamento, sistema de arquivos, bootloader, senha e criação do
usuário ficam a cargo do instalador oficial do Void.

O ponto de entrada é `install.sh`. Leve **esta pasta inteira**, não apenas o
arquivo `.sh`, para a instalação nova. Os outros arquivos são seus recursos.
O bootstrap i3 antigo, na pasta superior, é independente e não deve ser usado
para esta instalação.

## Antes de formatar

Copie seus documentos, chaves e outros dados importantes para outra unidade.
Guarde também o arquivo `void-niri-dux.tar.gz` fora do disco que será apagado.
O script não faz o backup dos seus documentos nem restaura seus aplicativos.

Use a ISO base x86_64 **glibc**, sem XFCE. Uma instalação limpa com o `/home`
antigo pode trazer configurações conflitantes: guarde os arquivos pessoais e
comece com um perfil de usuário novo. Faça backup antes de escolher isso no
instalador. Conexão Ethernet facilita a primeira instalação.

## Preparação mínima na instalação nova

Entre como root e instale os utilitários de administração:

```sh
xbps-install -S sudo nano
usermod -aG wheel SEU_USUARIO
EDITOR=nano visudo
```

No `visudo`, habilite a regra `%wheel ALL=(ALL:ALL) ALL` (ou a equivalente já
presente). Saia e entre novamente como seu usuário normal. Não use o nome
literal `SEU_USUARIO`. Se sudo já estiver preparado, pule esta etapa.

Extraia a cópia que você salvou:

```sh
tar -xzf /caminho/void-niri-dux.tar.gz
cd niri-dux
bash install.sh --plan
```

O planejamento lê `/proc`, `/sys`, arquitetura e serviços atuais. Não instala,
não pede sudo, não atualiza índices e não grava arquivos. Confira o hardware
e o plano. Depois, **em um TTY local**, fora de SSH e de qualquer desktop:

```sh
bash install.sh --apply
```

O script usa as confirmações normais do XBPS. A primeira consulta aos
repositórios Dux pede confiança nas chaves de assinatura. Confira a origem e
a impressão digital conforme a documentação oficial; o script não aceita
chaves automaticamente nem desativa a verificação de assinaturas.

Se houver uma falha, consulte o log indicado. Resolvido o problema, execute
o mesmo comando novamente. Downloads/pacotes já concluídos são reaproveitados;
a configuração Niri marcada como gerenciada é preservada nas execuções
seguintes. Mudanças de layout/teclado posteriores devem ser feitas no Dux ou
nos arquivos de configuração, pois repetir `--keyboard` não sobrescreve um
Niri já configurado.

## O que é preparado

1. Inventário de CPU, GPUs PCI, RAM, bateria, Bluetooth e armazenamento.
2. Atualização do sistema e do próprio XBPS; microcode Intel pelo repositório
   nonfree, com reconstrução dos initramfs dos kernels instalados.
3. Repositórios estáveis Dux, validação dos nomes de pacotes e simulação da
   transação antes da instalação.
4. Locale `pt_BR.UTF-8`, fuso `America/Sao_Paulo`, teclado gráfico `br`, áudio
   PipeWire + WirePlumber e interface PulseAudio/ALSA.
5. Niri, Xwayland Satellite, Quickshell, Dux, Matugen e portais GNOME/GTK.
   O shell é integrado diretamente ao Niri; não se executa um segundo
   instalador remoto sobre essas configurações.
6. Serviços runit de D-Bus, elogind, hora e logs; Bluetooth quando detectado.
7. Zram LZ4 com 25% da RAM, limitada a 2 GiB, em máquinas com até 16 GiB.
   Swap em disco existente é mantida. Zram já ativa mantém seus parâmetros.
8. TRIM semanal via cronie quando há disco não rotacional. `fstrim -a` atende
   os sistemas de arquivos montados que suportam descarte; não força a
   opção de montagem `discard` e não reformata unidades.
9. Por último, troca dos serviços de rede independentes pelo NetworkManager.
   Pode haver perda de conexão e necessidade de reintroduzir a senha Wi-Fi:
   use `nmtui`. A falha de inicialização do NetworkManager tenta restaurar os
   links de rede anteriores; isso não garante recuperar uma conexão Wi-Fi.

Aplicativos básicos: Firefox, Alacritty, Thunar com montagem/miniaturas,
gerenciador de arquivos compactados, mpv/FFmpeg, controle de áudio e fontes.
Não instala ferramentas de desenvolvimento, suíte de escritório, jogos,
visualizador de espectro ou indexador de arquivos por padrão.

Os links de áudio apontam para os exemplos do próprio Void. Os links em
`~/.local/bin` apontam para cópias em `~/.local/share/niri-dux`: remover o
pendrive ou a pasta do instalador depois não quebra a sessão. As configurações
do Niri são arquivos editáveis, com fragmentos que o Dux pode gerenciar.

## Escolhas de hardware e desempenho

No Dell i3-2310M / Intel HD 3000, o inventário seleciona `mesa-dri`, firmware
Intel e `libva-intel-driver` (i965), sem Vulkan e com animações Niri desativadas.
Não instala `xf86-video-intel`, que é um driver Xorg. Não força variáveis
globais de VA-API nem codecs que o hardware não decodifica.

GPUs AMD recebem Mesa VA-API e firmware AMD. Intel mais recente recebe os
backends VA-API Intel para seleção pelo libva. A detecção de Intel legado
usa famílias de IDs PCI conhecidas, não tenta deduzir a GPU só pelo nome da
CPU. Nem toda GPU histórica está catalogada: `vainfo` continua necessário.

NVIDIA bloqueia a aplicação automática, pois a escolha entre drivers depende
da geração e suporte. `--allow-nouveau` aceita explicitamente Mesa/Nouveau;
não instala driver proprietário, não altera blacklist nem parâmetros de boot.
Esse modo exige teste posterior, especialmente em notebooks híbridos.

O perfil de energia padrão é o do kernel. `--power=tlp` adiciona TLP somente
se houver bateria e recusa gerenciadores concorrentes. Não aplica undervolt,
governor permanente em performance, mitigations=off ou sysctls genéricos.
Uma lista de pacotes não comprova desempenho: áudio, GPU e suspensão precisam
ser testados no equipamento após o primeiro login.

Os efeitos do Dux ficam inicialmente nos padrões do projeto. Na HD 3000,
comece sem blur, papéis de parede animados e widgets de atualização contínua;
ajuste nas configurações do shell. O script não escreve opções de efeitos
em um formato interno não documentado do Dux.

## Primeiro login e uso

Depois de concluir, reinicie e entre novamente no TTY como usuário normal:

```sh
~/.local/bin/start-niri-dux
```

O launcher valida o runtime criado por elogind, abre um barramento D-Bus
próprio e inicia `niri --session`. O autostart exporta o ambiente para portais,
inicia PipeWire caso necessário e executa `dms run`. Não há `systemctl` nem
serviço PipeWire global. Os processos iniciados pelo autostart são encerrados
quando a sessão termina. Não há login automático nem greeter nesta versão.

| Atalho | Ação |
| --- | --- |
| Super+Enter | Terminal |
| Super+Space | Launcher Dux |
| Super+, | Configurações Dux |
| Super+E | Thunar |
| Super+V | Histórico da área de transferência |
| Super+N | Notificações |
| Super+Alt+L | Bloquear |
| Super+Tab | Overview |
| Super+setas | Navegar pelas janelas/colunas |
| Super+Shift+setas | Mover janelas/colunas |
| Super+PageUp/PageDown | Trocar workspace |
| Super+Shift+Space | Alternar janela flutuante |
| Super+Shift+E | Encerrar Niri |

## Diagnóstico e limites

Dentro da sessão:

```sh
~/.local/bin/niri-dux-check
```

Confere Niri, sessão elogind, dispositivos PipeWire/PulseAudio, monitores,
processos e VA-API. A falha do `vainfo` não significa necessariamente falha
do desktop: investigue driver e perfis suportados. Teste manualmente áudio
interno/HDMI, microfone, vídeo H.264, Wi-Fi, brilho, captura/compartilhamento
de tela e bloqueio/desbloqueio. Teste o desbloqueio antes de habilitar
suspensão/bloqueio automático no Dux.

Logs: `~/.local/state/niri-dux/`, incluindo `session.log`, `autostart.log` e
um log por aplicação do instalador. Backups de configurações de usuário,
pacotes e serviços anteriores ficam no subdiretório `backups/`. Configurações
de sistema substituídas são copiadas para `/var/backups/niri-dux/`.
Não existe rollback transacional de pacotes ou da atualização do sistema.

Configuração gráfica preexistente ou seat manager/greeter concorrente causa
interrupção antes das alterações. O script não apaga i3 nem limpa `/home`.
As opções `--network=keep`, `--no-zram`, `--no-microcode`, `--power=tlp`,
`--keyboard=us`, `--locale=en_US.UTF-8` e `--timezone=UTC` permitem ajustar o
plano. `--network=keep` preserva sua rede, mas o painel Dux pode não controlá-la.
O teclado do console e o RTC ficam como configurados no instalador do Void.

Verificações de desenvolvimento, sem instalar nada:

```sh
python3 -m unittest discover -s tests -v
bash -n install.sh
```

Os testes cobrem detecção com hardware simulado e as barreiras do instalador.
A instalação completa não foi executada numa máquina limpa nesta entrega;
o script valida a configuração com o binário Niri durante a instalação.

## Referências consultadas em 01/11/2026

- https://duxlabs.dev/docs/getting-started
- https://duxlabs.dev/docs/dms/installation/#void-linux
- https://duxlabs.dev/docs/dms/compositors
- https://duxlabs.dev/docs/dms/cli-setup
- https://docs.voidlinux.org/config/media/pipewire.html
- https://docs.voidlinux.org/config/session-management.html
- https://docs.voidlinux.org/config/graphical-session/wayland.html
- https://docs.voidlinux.org/config/graphical-session/graphics-drivers/intel.html
- https://niri-wm.github.io/niri/Getting-Started.html
