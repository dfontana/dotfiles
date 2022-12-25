local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Set the Leader (Space)
keymap("n", "<Space>", "", opts)
keymap("n", "<C-Space>", "<cmd>WhichKey \\<leader><cr>", opts)
keymap("n", "<C-i>", "<C-i>", opts)

-- keymap("n", "<S-Up>", ":call vm#commands#add_cursor_up(0, v:count1)<cr>", opts)
-- keymap("n", "<S-Down>", ":call vm#commands#add_cursor_down(0, v:count1)<cr>", opts)

-- Resize splits Alt+Arrows
keymap("n", "<M-Up>", ":resize -2<CR>", opts)
keymap("n", "<M-Down>", ":resize +2<CR>", opts)
keymap("n", "<M-Right>", ":vertical resize -2<CR>", opts)
keymap("n", "<M-Left>", ":vertical resize +2<CR>", opts)

-- When indenting, don't leave after indent
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

local setup = {
  plugins = {
    marks = true,     -- shows a list of your marks on ' and `
    registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    spelling = {
      enabled = true,   -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      suggestions = 20, -- how many suggestions should be shown in the list?
    },
    presets = {
      operators = false,    -- Show help for things like d/y/c, etc
      motions = false,      -- Show help for motions
      text_objects = false, -- Show help for things to press after motions
      windows = true,       -- default bindings on <c-w>
      nav = true,           -- misc bindings to work with windows
      z = true,             -- bindings for folds, spelling and others prefixed with z
      g = false,            -- bindings for prefixed with g
    },
  },
  key_labels = {
    ["<leader>"] = "SPC",
  },
  icons = {
    breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
    separator = "➜",  -- symbol used between a key and it's label
    group = "+",      -- symbol prepended to a group
  },
  popup_mappings = {
    scroll_down = "<c-d>", -- binding to scroll down inside the popup
    scroll_up = "<c-u>",   -- binding to scroll up inside the popup
  },
  window = {
    border = "rounded",       -- none, single, double, shadow
    position = "bottom",      -- bottom, top
    margin = { 0, 0, 0, 0 },  -- extra window margin [top, right, bottom, left]
    padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
    winblend = 0,
  },
  layout = {
    height = { min = 4, max = 25 }, -- min and max height of the columns
    width = { min = 20, max = 50 }, -- min and max width of the columns
    spacing = 3,                    -- spacing between columns
    align = "center",               -- align columns left, center or right
  },
  ignore_missing = true, -- enable this to hide mappings for which you didn't specify a label
  hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
  show_help = false, -- show help message on the command line when the popup is visible 
  show_keys = false,
  triggers = "auto",
  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    i = { "j", "k" },
    v = { "j", "k" },
  },
}

local wk_opts = {
  mode = "n", -- NORMAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true, -- use `nowait` when creating keymaps
}

local mappings = {
  e = { "<cmd>NvimTreeToggle<cr>", "Explorer" },
  ["/"] = { '<cmd>lua require("Comment.api").toggle.linewise.current()<CR>', "Comment" },
  c = { "<cmd>Bdelete!<CR>", "Close Buffer" },
  z = "Folds & Spelling",
  p = {
    name = "Plugins",
    m = { "<cmd>Mason<cr>", "Mason" },
    l = { "<cmd>Lazy<cr>", "Lazy" },
    i = { "<cmd>LspInfo<cr>", "LspInfo" },
  },
  o = {
    name = "Options",
    h = { "<cmd>nohlsearch<CR>", "No HL" },
    w = { '<cmd>lua require("config.functions").toggle_option("wrap")<cr>', "Wrap" },
    l = { '<cmd>lua require("config.functions").toggle_option("cursorline")<cr>', "Cursorline" },
    s = { '<cmd>lua require("config.functions").toggle_option("spell")<cr>', "Spell" },
  },
  d = {
    name = "Debug",
    b = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Breakpoint" },
    c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
    i = { "<cmd>lua require'dap'.step_into()<cr>", "Into" },
    o = { "<cmd>lua require'dap'.step_over()<cr>", "Over" },
    O = { "<cmd>lua require'dap'.step_out()<cr>", "Out" },
    r = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Repl" },
    l = { "<cmd>lua require'dap'.run_last()<cr>", "Last" },
    u = { "<cmd>lua require'dapui'.toggle()<cr>", "UI" },
    x = { "<cmd>lua require'dap'.terminate()<cr>", "Exit" },
  },
  s = {
    name = "Search",
    b = { "<cmd>Telescope buffers<cr>", "Buffers" },
    f = { "<cmd>Telescope find_files<cr>", "Files" },
    t = { "<cmd>Telescope live_grep<cr>", "Text" },
    T = { "<cmd>TodoTelescope<cr>", "TODO"},
    p = { "<cmd>Telescope projects<cr>", "Projects"},
    h = { "<cmd>Telescope help_tags<cr>", "Help" },
    l = { "<cmd>Telescope resume<cr>", "Last Search" },
    r = { "<cmd>Telescope oldfiles<cr>", "Recent File" },
    C = { "<cmd>Telescope commands<cr>", "Commands" },
    n = { "<cmd>Telescope noice layout_strategy=vertical layout_config={width=0.5}<cr>", "Notifications" },
  },
  g = {
    name = "Git",
    b = { "<cmd>GitBlameToggle<cr>", "Blame" },
    p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
    r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
    o = { "<cmd>Telescope git_status<cr>", "Open changed file" },
    s = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
    c = { "<cmd>Telescope git_commits<cr>", "Checkout commit" },
    d = {
      "<cmd>Gitsigns diffthis HEAD<cr>",
      "Diff",
    },
    y = {"Open line on GitHub"},
  },
  l = {
    name = "LSP",
    a = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens" },
    f = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Fix"},
    d = { "<cmd>Telescope lsp_definitions<cr>", "Definition" },
    r = { "<cmd>Telescope lsp_references<cr>", "References" },
    k = { "<cmd>lua require('config.functions').show_documentation()<CR>", "Documentation"},
    F = { "<cmd>lua vim.lsp.buf.format({ async = true })<cr>", "Format" },
    h = { "<cmd>lua vim.diagnostic.open_float(0,{scope='line'})<cr>", "Hover Detail" },
    w = {
      "<cmd>Telescope diagnostics<cr>",
      "Workspace Diagnostics",
    },
    s = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature"},
    v = { "<cmd>lua require('lsp_lines').toggle()<cr>", "Virtual Text" },
    o = { "<cmd>SymbolsOutline<cr>", "Outline" },
    R = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
  },
  t = {
    name = "Terminal",
    h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
    v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
  },
  K = {
    name = "Keymappings",
    ["<M-Up>"] = "Resize Split Up",
    ["<M-Down>"] = "Resize Split Down",
    ["<M-Left>"] = "Resize Split Left",
    ["<M-Right>"] = "Resize Split Right",
    ["<S-Up>"] = "Add Cursor Above",
    ["<S-Down>"] = "Add Cursor Below",
    ["<C-n>"] = "Add Cursor at Word",
  },
}

local vopts = {
  mode = "v", -- VISUAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true, -- use `nowait` when creating keymaps
}
local vmappings = {
  ["/"] = { '<ESC><CMD>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', "Comment" },
}

local which_key = require("which-key")
which_key.setup(setup)
which_key.register(mappings, wk_opts)
which_key.register(vmappings, vopts)
