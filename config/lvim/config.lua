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
  "toml",
  "yaml",
}
lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true



vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "stylua", filetypes = { "lua" } },
}

local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
local codelldb_adapter = {
  type = "server",
  port = "${port}",
  executable = {
    command = mason_path .. "bin/codelldb",
    args = { "--port", "${port}" },
    -- On windows you may have to uncomment this:
    -- detached = false,
  },
}

pcall(function()
  require("rust-tools").setup {
    tools = {
      executor = require("rust-tools/executors").termopen, -- can be quickfix or termopen
      reload_workspace_from_cargo_toml = true,
      runnables = {
        use_telescope = true,
      },
      inlay_hints = {
        auto = true,
        only_current_line = false,
        show_parameter_hints = false,
        parameter_hints_prefix = "<-",
        other_hints_prefix = "=>",
        max_len_align = false,
        max_len_align_padding = 1,
        right_align = false,
        right_align_padding = 7,
        highlight = "Comment",
      },
      hover_actions = {
        border = "rounded",
      },
      on_initialized = function()
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "CursorHold", "InsertLeave" }, {
          pattern = { "*.rs" },
          callback = function()
            local _, _ = pcall(vim.lsp.codelens.refresh)
          end,
        })
      end,
    },
    dap = {
      adapter = codelldb_adapter,
    },
    server = {
      on_attach = function(client, bufnr)
        require("lvim.lsp").common_on_attach(client, bufnr)
        local rt = require "rust-tools"
        vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
      end,

      capabilities = require("lvim.lsp").common_capabilities(),
      settings = {
        ["rust-analyzer"] = {
          lens = {
            enable = true,
          },
          checkOnSave = {
            enable = true,
            command = "clippy",
          },
        },
      },
    },
  }
end)

lvim.builtin.dap.on_config_done = function(dap)
  dap.adapters.codelldb = codelldb_adapter
  dap.configurations.rust = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }
end
