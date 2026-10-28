# Python, arquivos e estudos

As configurações de Neovim e Yazi usam a paleta Nord. São complementos
opcionais; o bootstrap e o seletor de temas do desktop não os aplicam.
Os instaladores precisam de acesso à internet e devem ser executados como
usuário comum. O sudo é solicitado apenas para pacotes do Void Linux.

## Neovim para Python

Preserve sua configuração anterior antes de copiar os arquivos, caso exista:

```bash
mkdir -p ~/.config/nvim
cp config/nvim/init.lua ~/.config/nvim/init.lua
bash scripts/preparar-nvim-python.sh
```

Requer Neovim 0.11 ou posterior. O instalador baixa o tema oficial
[nordtheme/vim](https://github.com/nordtheme/vim) e instala python-lsp-server
(autocompletar e navegação) e Ruff (diagnósticos e formatação) em um ambiente
isolado em `~/.local/share/nvim-python`. Não instala bibliotecas nos projetos.
Para reconhecer as dependências do projeto, ative seu ambiente virtual antes
de abrir o editor ou use uma pasta `.venv` na raiz do projeto.

Abra com `nvim arquivo.py`. Atalhos: F5 executa o arquivo, Espaço f formata,
Espaço w salva, Espaço e abre o explorador, gd vai à definição, K exibe
ajuda e Espaço rn renomeia um símbolo. O autocompletar usa o LSP nativo.

## Yazi Nord

```bash
sudo xbps-install -S yazi
mkdir -p ~/.config/yazi
cp config/yazi/theme.toml ~/.config/yazi/theme.toml
yazi
```

Preserve qualquer `theme.toml` anterior antes de copiar. O tema foi validado
no Yazi 26.9.1 e configura a interface e as cores da lista de arquivos.

## Obsidian e Anki

```bash
bash scripts/instalar-obsidian-anki.sh
```

O script instala Flatpak se necessário, adiciona Flathub no escopo do usuário
e instala `md.obsidian.Obsidian` e `net.ankiweb.Anki` no mesmo escopo.
Para abrir:

```bash
flatpak run md.obsidian.Obsidian
flatpak run net.ankiweb.Anki
```

Os aplicativos devem aparecer no Rofi no modo `drun`. Após instalar Flatpak
pela primeira vez, encerre e inicie a sessão para atualizar os caminhos de
aplicativos, caso necessário.

Os arquivos versionados não incluem notas, baralhos, dados dos aplicativos,
ambientes virtuais nem downloads dos temas.
