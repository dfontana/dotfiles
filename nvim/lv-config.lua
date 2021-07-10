-- vim settings
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.cmd[[highlight vCursor guifg=white guibg=steelblue]]
vim.o.guicursor = 'a:block-blinkwait175-blinkoff150-blinkon175-vCursor'
vim.o.whichwrap = 'b,s,h,l'

-- Rust
vim.cmd[[autocmd BufNewFile,BufRead *.rs setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2]]


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
O.wrap_lines = false
O.timeoutlen = 100
O.leader_key = " "
O.ignore_case = true
O.smart_case = true

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
	b = { ":Telescope buffers<CR>", "Find Buffer"}
}
