--[[
O is the global options object

Formatters and linters should be
filled in as strings with either
a global executable or a path to
an executable
]]

-- general
O.format_on_save = true
O.auto_complete = true
O.colorscheme = 'gruvbox'
O.auto_close_tree = 0
O.wrap_lines = true
O.timeoutlen = 100
O.leader_key = " "
O.ignore_case = true
O.smart_case = true
O.shift_width = 2
O.tab_stop = 2

-- Plugins
O.plugin.dashboard.active = true
O.plugin.colorizer.active = false
O.plugin.ts_playground.active = false
O.plugin.indent_line.active = false
O.plugin.zen.active = false

-- if you don't want all the parsers change this to a table of the ones you want
O.treesitter.ensure_installed = "all"
O.treesitter.ignore_install = {"haskell"}
O.treesitter.highlight.enabled = true

O.lang.tsserver.linter = nil

O.user_plugins = {
  {
    "mg979/vim-visual-multi",
    config = function() require"vim-visual-multi" end,
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
vim.o.guicursor = 'a:block-blinkwait175-blinkoff150-blinkon175-vCursor'

-- Show diagnostics on cursor hover (no movement)
vim.o.updatetime=300
O.user_autocommands = {
  {"CursorHold", "*", "lua", "vim.lsp.diagnostic.show_line_diagnostics()"}
}

-- Rust
vim.cmd[[let g:rust_recommended_style=0]]
O.lang.rust.rust_tools.active = true

