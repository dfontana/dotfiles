vim.opt.backup = false -- creates a backup file
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.cmdheight = 2 -- more space in the neovim command line for displaying messages
vim.opt.colorcolumn = "99999" -- fixes indentline for now
vim.opt.completeopt = { "menuone", "noselect" }
vim.opt.conceallevel = 0 -- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8" -- the encoding written to a file
vim.opt.foldmethod = "manual" -- folding set to "expr" for treesitter based folding
vim.opt.foldexpr = "" -- set to "nvim_treesitter#foldexpr()" for treesitter based folding
vim.opt.hidden = true -- required to keep multiple buffers and open multiple buffers
vim.opt.hlsearch = true -- highlight all matches on previous search pattern
vim.opt.ignorecase = true -- ignore case in search patterns
vim.opt.mouse = "a" -- allow the mouse to be used in neovim
vim.opt.pumheight = 10 -- pop up menu height
vim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 2 -- always show tabs
vim.opt.smartcase = true -- smart case
vim.opt.smartindent = true -- make indenting smarter again
vim.opt.splitbelow = true -- force all horizontal splits to go below current window
vim.opt.splitright = true -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false -- creates a swapfile
vim.opt.termguicolors = true -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 100 -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.title = true -- set the title of window to the value of the titlestring
vim.opt.titlestring = "%<%F%=%l/%L - nvim" -- what the title of the window will be set to
vim.opt.undodir = vim.fn.stdpath "cache" .. "/undo"
vim.opt.undofile = true -- enable persistent undo
vim.opt.updatetime = 300 -- faster completion
vim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program) it is not allowed to be edited
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.shiftwidth = 2 -- the number of spaces inserted for each indentation
vim.opt.tabstop = 2 -- insert 2 spaces for a tab
vim.opt.cursorline = true -- highlight the current line
vim.opt.number = true -- set numbered lines
vim.opt.relativenumber = false -- set relative numbered lines
vim.opt.numberwidth = 4 -- set number column width to 2 {default 4}
vim.opt.signcolumn = "yes" -- always show the sign column otherwise it would shift the text each time
vim.opt.wrap = true -- display lines as one long line
vim.opt.spell = false
vim.opt.spelllang = "en"
vim.opt.scrolloff = 8 -- is one of my fav
vim.opt.sidescrolloff = 8
vim.opt.shortmess:append "c"



lvim.builtin.lir.active = false
lvim.builtin.alpha.active = true
lvim.builtin.terminal.active = true
lvim.plugins = {
  {
    "shaunsingh/solarized.nvim",
    config = function()
      vim.opt.background="light"
      vim.g.solarized_italic_keywords = false
      vim.g.solarized_italic_functions = false
      vim.g.solarized_italic_comments = true
    end
  },
  {
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
  },
  {"mg979/vim-visual-multi"},
  "simrat39/rust-tools.nvim",
  {
    "saecki/crates.nvim",
    tag = "v0.3.0",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crates").setup {
        null_ls = {
          enabled = true,
          name = "crates.nvim",
        },
        popup = {
          border = "rounded",
        },
      }
    end,
  },
  {
    "j-hui/fidget.nvim",
    config = function()
      require("fidget").setup()
    end,
  },
}



lvim.log.level = "warn"
lvim.format_on_save.enabled = false
lvim.colorscheme = "solarized"
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true


lvim.leader = "space"
lvim.builtin.which_key.mappings['w'] = {}
lvim.builtin.which_key.mappings['b'] = {}
lvim.builtin.which_key.mappings['T'] = {}
lvim.builtin.which_key.mappings['f'] = {}
lvim.builtin.which_key.mappings['q'] = {}
lvim.builtin.which_key.mappings['h'] = {}
lvim.builtin.which_key.mappings['sC'] = {}
lvim.builtin.which_key.mappings['sH'] = {}
lvim.builtin.which_key.mappings['sR'] = {}
lvim.builtin.which_key.mappings['sb'] = {"<cmd>Telescope buffers<cr>", "Buffers"}
lvim.builtin.which_key.mappings['sT'] = { "<cmd>TodoTelescope<cr>", "TODO"}
lvim.builtin.which_key.mappings['sp'] = { "<cmd>Telescope projects<cr>", "Projects"}
lvim.builtin.which_key.mappings['o'] = {
    name = "Options",
    h = { "<cmd>nohlsearch<CR>", "No HL" },
    w = { '<cmd>lua require("user.functions").toggle_option("wrap")<cr>', "Wrap" },
    l = { '<cmd>lua require("user.functions").toggle_option("cursorline")<cr>', "Cursorline" },
    s = { '<cmd>lua require("user.functions").oggle_option("spell")<cr>', "Spell" },
}
lvim.builtin.which_key.mappings['t'] = {
    name = "Terminal",
    h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
    v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" }
}
lvim.builtin.which_key.mappings['lI'] = {}
lvim.builtin.which_key.mappings['la'] = {}
lvim.builtin.which_key.mappings['lq'] = {}
lvim.builtin.which_key.mappings['ll'] = {}
-- TODO
-- lsp documentation? lk -> vim.lsp.buf.hover()
-- h = { "<cmd>lua vim.diagnostic.open_float(0,{scope='line'})<cr>", "Hover Detail" }
-- d = { "<cmd>Telescope lsp_definitions<cr>", "Definition" },
-- r = { "<cmd>Telescope lsp_references<cr>", "References" },
-- a = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens" },
-- f = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Fix" },
-- s = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature"},
-- v = { "<cmd>lua require('lsp_lines').toggle()<cr>", "Virtual Text" },
--  q = { "<cmd>lua vim.diagnostic.setloclist()<cr>", "Quickfix" },
--  R = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
lvim.builtin.which_key.mappings['gg'] = {}
lvim.builtin.which_key.mappings['gb'] = {}
lvim.builtin.which_key.mappings['gc'] = {}
lvim.builtin.which_key.mappings['gC'] = {}
lvim.builtin.which_key.mappings['go'] = {}
lvim.builtin.which_key.mappings['gs'] = {}
lvim.builtin.which_key.mappings['gu'] = {}
lvim.builtin.which_key.mappings['K'] = {
  name = "Keymappings",
  ["<M-Up>"] = "Resize Split Up",
  ["<M-Down>"] = "Resize Split Down",
  ["<M-Left>"] = "Resize Split Left",
  ["<M-Right>"] = "Resize Split Right",
  ["<S-Up>"] = "Add Cursor Above",
  ["<S-Down>"] = "Add Cursor Below",
}

-- Multiple Cursors, via vim-visual-multi
-- (More here: https://github.com/mg979/vim-visual-multi/wiki/Mappings)
vim.cmd("let g:VM_maps = {}")
vim.cmd("let g:VM_maps['Add Cursor Down'] = '<S-Down>'")
vim.cmd("let g:VM_maps['Add Cursor Up'] = '<S-Up>'")
vim.cmd("let g:VM_maps['Mouse Cursor'] = '<S-LeftMouse>'")
vim.cmd("let g:VM_maps['Visual Cursors'] = '<Space-S-c>'") 

-- Resize splits Alt+Arrows
lvim.keys.normal_mode["<M-Up>"] = ":resize -2<CR>"
lvim.keys.normal_mode["<M-Down>"] = ":resize +2<CR>"
lvim.keys.normal_mode["<M-Right>"] = ":vertical resize -2<CR>"
lvim.keys.normal_mode["<M-Left>"] = ":vertical resize +2<CR>"



lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
-- lvim.lsp.installer.setup.ensure_installed = {
--     "sumneko_lua",
--     "jsonls",
-- }
-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }

-- ---@usage disable automatic installation of servers
-- lvim.lsp.installer.setup.automatic_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
-- local formatters = require "lvim.lsp.null-ls.formatters"
-- formatters.setup {
--   { command = "black", filetypes = { "python" } },
--   { command = "isort", filetypes = { "python" } },
--   {
--     -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "prettier",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--print-with", "100" },
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "typescript", "typescriptreact" },
--   },
-- }

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "shellcheck",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--severity", "warning" },
--   },
--   {
--     command = "codespell",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "javascript", "python" },
--   },
-- }

-- Additional Plugins
-- lvim.plugins = {
--     {
--       "folke/trouble.nvim",
--       cmd = "TroubleToggle",
--     },
-- }

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
