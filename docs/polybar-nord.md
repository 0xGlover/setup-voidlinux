# Polybar Nord

Barra de 34 px com paleta Nord, lançador à esquerda, workspaces com
sublinhado ciano no ativo, calendário/relógio no centro e volume, CPU,
memória, bandeja e menu de energia à direita.

Usa DejaVu Sans e FontAwesome (pacote font-awesome, versão 4).
Execute scripts/setup-polybar-icons.sh para instalar a fonte e recarregar a barra.

- Clique no símbolo à esquerda para abrir Rofi.
- Volume: clique esquerdo alterna mute; roda ajusta volume; direito abre pavucontrol.
- Clique no botão de energia para abrir o menu de ações.

Para aplicar na sessão gráfica:

```bash
bash ~/setup-voidlinux/scripts/reload-bar.sh
```

O gerador de temas mantém a estrutura e adapta as cores à paleta escolhida.
O visual final precisa ser conferido na sessão gráfica; o sandbox não
consegue se conectar ao servidor X.
