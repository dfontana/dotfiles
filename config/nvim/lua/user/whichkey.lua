local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
  return
end

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
  show_help = true, -- show help message on the command line when the popup is visible 
  triggers = "auto",
  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    i = { "j", "k" },
    v = { "j", "k" },
  },
}

local opts = {
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
    name = "Packer",
    c = { "<cmd>PackerCompile<cr>", "Compile" },
    i = { "<cmd>PackerInstall<cr>", "Install" },
    s = { "<cmd>PackerSync<cr>", "Sync" },
    S = { "<cmd>PackerStatus<cr>", "Status" },
    u = { "<cmd>PackerUpdate<cr>", "Update" },
  },
  o = {
    name = "Options",
    h = { "<cmd>nohlsearch<CR>", "No HL" },
    w = { '<cmd>lua require("user.functions").toggle_option("wrap")<cr>', "Wrap" },
    l = { '<cmd>lua require("user.functions").toggle_option("cursorline")<cr>', "Cursorline" },
    s = { '<cmd>lua require("user.functions").toggle_option("spell")<cr>', "Spell" },
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
  },
  l = {
    name = "LSP",
    a = {
      name = "Actions",
      a = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens" },
      j = { "<cmd>Jaq<cr>", "JaqRun" },
    },
    d = { "<cmd>Telescope lsp_definition<cr>", "Definition" },
    r = { "<cmd>Telescope lsp_references<cr>", "References" },
    k = { "<cmd>lua require('user.functions').show_documentation()<CR>", "Documentation"},
    f = { "<cmd>lua vim.lsp.buf.format({ async = true })<cr>", "Format" },
    h = { "<cmd>lua vim.diagnostic.open_float(0,{scope='line'})<cr>", "Hover Detail" },
    n = {
      "<cmd>lua vim.diagnostic.goto_next({buffer=0})<CR>",
      "Next Diagnostic",
    },
    p = {
      "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>",
      "Prev Diagnostic",
    },
    w = {
      "<cmd>Telescope diagnostics<cr>",
      "Workspace Diagnostics",
    },
    v = { "<cmd>lua require('lsp_lines').toggle()<cr>", "Virtual Text" },
    o = { "<cmd>SymbolsOutline<cr>", "Outline" },
    q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>", "Quickfix" },
    R = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
    i = { "<cmd>LspInfo<cr>", "LspInfo" },
  },
  t = {
    name = "Terminal",
    h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
    v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
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

which_key.setup(setup)
which_key.register(mappings, opts)
which_key.register(vmappings, vopts)
