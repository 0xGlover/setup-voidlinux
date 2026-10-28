vim.g.mapleader = ' '
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.g.nord_italic_comments = 1
vim.g.nord_bold = 1
if not pcall(vim.cmd.colorscheme, 'nord') then
    vim.schedule(function() vim.notify('Instale o Nord com ~/.local/bin/preparar-nvim-python', vim.log.levels.WARN) end)
end

vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', { desc = 'Salvar' })
vim.keymap.set('n', '<leader>e', '<cmd>Explore<cr>', { desc = 'Arquivos' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Diagnóstico' })
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

if vim.fn.has('nvim-0.11') == 0 then
    vim.schedule(function() vim.notify('Esta configuração requer Neovim 0.11 ou mais recente.', vim.log.levels.ERROR) end)
    return
end

local tools = vim.fn.expand('~/.local/share/nvim-python/bin/')
vim.lsp.config('pylsp', {
    cmd = { tools .. 'pylsp' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', '.git' },
    settings = { pylsp = { plugins = {
        pycodestyle = { enabled = false },
        pyflakes = { enabled = false },
        mccabe = { enabled = false },
        jedi_completion = { include_params = true },
    } } },
    on_init = function(client)
        local root = client.config.root_dir
        local env = vim.env.VIRTUAL_ENV or (root and root .. '/.venv')
        if env and vim.fn.executable(env .. '/bin/python') == 1 then
            client.config.settings.pylsp.plugins.jedi = { environment = env .. '/bin/python' }
            client:notify('workspace/didChangeConfiguration', { settings = client.config.settings })
        end
    end,
})
vim.lsp.config('ruff', {
    cmd = { tools .. 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
})
for _, name in ipairs({ 'pylsp', 'ruff' }) do
    if vim.fn.executable(tools .. name) == 1 then vim.lsp.enable(name) end
end

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local opts = { buffer = event.buf }
        if client and client.name == 'pylsp' then
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        end
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>f', function()
            vim.lsp.buf.format({ bufnr = event.buf, name = 'ruff', timeout_ms = 3000 })
        end, opts)
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    callback = function(event)
        vim.keymap.set('n', '<F5>', function()
            vim.cmd.write()
            local file = vim.api.nvim_buf_get_name(0)
            local root = vim.fs.root(0, { 'pyproject.toml', '.git' }) or vim.fn.getcwd()
            local env = vim.env.VIRTUAL_ENV or root .. '/.venv'
            local python = vim.fn.executable(env .. '/bin/python') == 1 and env .. '/bin/python' or 'python3'
            vim.cmd('botright split')
            vim.cmd('resize 12')
            vim.fn.termopen({ python, file })
            vim.cmd.startinsert()
        end, { buffer = event.buf, desc = 'Executar Python' })
    end,
})
