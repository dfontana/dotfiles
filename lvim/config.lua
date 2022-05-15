lvim.log.level = "warn"
lvim.colorscheme = "material"
vim.g.material_style = "darker"
lvim.format_on_save = true
lvim.lint_on_save = true
lvim.line_wrap_cursor_movement = true
vim.opt.inccommand = "split"
vim.opt.wrap = true
vim.cmd [[set shortmess-=S]]
vim.opt.guicursor = 'a:block-blinkwait175-blinkoff150-blinkon175-vCursor'

lvim.leader = "space"
lvim.builtin.which_key.mappings["t"] = {
  name = "+Trouble",
  h = { "<cmd>lua vim.diagnostic.open_float(0,{scope='line'})<cr>", "Hover Detail" },
  r = { "<cmd>Trouble lsp_references<cr>", "References" },
  d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
  q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
  l = { "<cmd>Trouble loclist<cr>", "LocationList" },
  w = { "<cmd>Trouble workspace_diagnostics<cr>", "Wordspace Diagnostics" },
}
lvim.builtin.which_key.mappings['l'] = {
  name = "LSP",
  a = { "<cmd>Telescope lsp_code_actions<cr>", "Code Action" },
  d = { "<cmd>Telescope lsp_definitions<cr>", "Go To Definition" },
  f = { "<cmd>lua vim.lsp.buf.formatting()<cr>", "Format" },
  r = {
    name = "Run",
    r = { "<cmd>RustRunnables<cr>", "Rust Runnables" },
    h = { "<cmd>RustHoverActions<cr><cmd>RustHoverActions<cr>", "Rust Hover Actions" },
    R = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
  }
}
lvim.builtin.which_key.vmappings['C'] = { "Cursors at line start", noremap = true }

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.show_icons.git = 0

lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "javascript",
  "json",
  "lua",
  "python",
  "css",
  "rust",
  "java",
  "yaml",
}
lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    command = "prettier",
    filetypes = { "javascript", "css", "scss", "html" },
  },
}
local lvimLsp = require("lvim.lsp")
require("lvim.lsp.manager").setup("tsserver", {
  on_attach = function(client, bufnr)
    client.resolved_capabilities.document_formatting = false
    lvimLsp.common_on_attach(client, bufnr)
  end,
  on_init = lvimLsp.common_on_init,
  settings = {
    format = {
      enable = false,
    },
  },
})


-- Shutoff default formatting for rust
vim.cmd [[let g:rust_recommended_style=0]]

lvim.plugins = {
  { "folke/trouble.nvim", cmd = "TroubleToggle", },
  {
    'marko-cerovac/material.nvim',
    config = function()
      require('material').setup({
        contrast = true, -- Enable contrast for sidebars, floating windows and popup menus like Nvim-Tree
        borders = false, -- Enable borders between verticaly split windows
        italics = {
          comments = false, -- Enable italic comments
          keywords = false, -- Enable italic keywords
          functions = false, -- Enable italic functions
          strings = false, -- Enable italic strings
          variables = false -- Enable italic variables
        },
        text_contrast = {
          lighter = false, -- Enable higher contrast text for lighter style
          darker = false -- Enable higher contrast text for darker style
        },
        disable = {
          background = false, -- Prevent the theme from setting the background (NeoVim then uses your teminal background)
          term_colors = false, -- Prevent the theme from setting terminal colors
          eob_lines = false -- Hide the end-of-buffer lines
        }
      })
    end
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufRead",
    setup = function()
      vim.g.indentLine_enabled = 1
      vim.g.indent_blankline_char = "▏"
      vim.g.indent_blankline_filetype_exclude = { "help", "terminal", "dashboard" }
      vim.g.indent_blankline_buftype_exclude = { "terminal" }
      vim.g.indent_blankline_show_trailing_blankline_indent = false
      vim.g.indent_blankline_show_first_indent_level = false
    end
  },
  {
    "mg979/vim-visual-multi",
    config = function()
      vim.cmd("let g:VM_quit_after_leaving_insert_mode = 1")
      vim.cmd("let g:VM_skip_empty_lines = 1")
      vim.cmd("let g:VM_default_mappings = 0")
      vim.cmd("let g:VM_mouse_mappings = 1")
      vim.cmd("let g:VM_theme = 'sand'")
      vim.cmd("let g:VM_maps = {}")
      vim.cmd("let g:VM_maps['Add Cursor Down'] = '<S-Down>'")
      vim.cmd("let g:VM_maps['Add Cursor Up'] = '<S-Up>'")
      vim.cmd("let g:VM_maps['Mouse Cursor'] = '<S-LeftMouse>'")
      vim.cmd("let g:VM_maps['Visual Cursors'] = '<Space-S-c>'")
    end
  },
  {
    "simrat39/rust-tools.nvim",
    config = function()
      require("rust-tools").setup({
        tools = {
          autoSetHints = true,
          hover_with_actions = true,
          runnables = {
            use_telescope = true,
          },
        },
        server = {
          cmd = { vim.fn.stdpath "data" .. "/lsp_servers/rust/rust-analyzer" },
          on_attach = require("lvim.lsp").common_on_attach,
          on_init = require("lvim.lsp").common_on_init,
        },
      })
    end,
    ft = { "rust", "rs" },
  },
}
