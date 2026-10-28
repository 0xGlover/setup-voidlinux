#!/usr/bin/env bash
set -euo pipefail

if (( EUID == 0 )); then
    echo 'Execute como seu usuário normal, sem sudo antes do script.' >&2
    exit 1
fi

# Apenas os pacotes do sistema precisam de sudo.
sudo xbps-install -S neovim python3 python3-pip git
nvim --clean --headless '+lua if vim.fn.has("nvim-0.11") == 0 then vim.cmd("cquit 1") end' +qa

tools="$HOME/.local/share/nvim-python"
python3 -m venv "$tools"
"$tools/bin/python" -m pip install --upgrade python-lsp-server ruff

theme="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/themes/start/nord"
if [[ ! -d "$theme" ]]; then
    mkdir -p "$(dirname "$theme")"
    staging=$(mktemp -d)
    trap 'rm -rf -- "$staging"' EXIT
    git clone --depth 1 https://github.com/nordtheme/vim.git "$staging/nord"
    mv "$staging/nord" "$theme"
fi

"$tools/bin/pylsp" --version
"$tools/bin/ruff" --version
nvim --headless '+lua assert(vim.g.colors_name == "nord", "Tema Nord não carregou")' +qa
echo 'Pronto! Abra um arquivo com: nvim arquivo.py'
