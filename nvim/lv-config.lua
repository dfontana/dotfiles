--[[
O is the global options object

Formatters and linters should be
filled in as strings with either
a global executable or a path to
an executable
]]

-- general
O.format_on_save = false
O.colorscheme = 'gruvbox-material'
O.default_options.wrap = true

-- Plugins
O.plugin.dashboard.active = true

-- if you don't want all the parsers change this to a table of the ones you want
O.treesitter.ensure_installed = "all"
O.treesitter.ignore_install = {"haskell"}
O.treesitter.highlight.enabled = true

O.user_plugins = {
  {
    "mg979/vim-visual-multi",
    config = function() require"vim-visual-multi" end,
  },
  {
    "sainnhe/gruvbox-material"
  }
}

O.user_which_key = {
	b = { ":Telescope buffers<CR>", "Find Buffer"},
  l = {
    name = "LSP",
    a = { "<cmd>Telescope lsp_code_actions<cr>", "Code Action" },
    d = { "<cmd>Telescope lsp_definitions<cr>", "Go To Definition" },
    D = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Document Errors"},
    i = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Go To Impl" },
    u = { "<cmd>Telescope lsp_references<cr>", "Usages" },
    f = { "<cmd>Neoformat<cr>", "Format" },
    q = { "<cmd>Telescope quickfix<cr>", "Quickfix" },
    r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
    s = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "Signature Help" },
  },
}

-- vim settings
vim.cmd[[highlight vCursor guifg=white guibg=steelblue]]
vim.cmd[[set shortmess-=S]]
vim.cmd[[set background=dark]]
vim.cmd[[let g:gruvbox_material_background = 'soft']]
vim.cmd[[let g:gruvbox_material_palette = 'original']]
vim.o.guicursor = 'a:block-blinkwait175-blinkoff150-blinkon175-vCursor'

-- Show diagnostics on cursor hover (no movement)
vim.o.updatetime=300
O.user_autocommands = {
  {"CursorHold", "*", "lua", "vim.lsp.diagnostic.show_line_diagnostics()"}
}

-- Rust
vim.cmd[[let g:rust_recommended_style=0]]
O.lang.rust.rust_tools.active = true

