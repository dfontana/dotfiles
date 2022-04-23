-- general
lvim.log.level = "warn"
lvim.format_on_save = false
lvim.lint_on_save = true
lvim.line_wrap_cursor_movement = true
lvim.colorscheme = "material"
vim.g.material_style = "darker"
vim.opt.inccommand = "split"
vim.opt.wrap = true
vim.cmd[[set shortmess-=S]]
vim.opt.guicursor = 'a:block-blinkwait175-blinkoff150-blinkon175-vCursor'

-- keymappings [view all the defaults by pressing <leader>Lk]
-- unmap a default keymapping: lvim.keys.normal_mode["<C-Up>"] = ""
-- edit a default keymapping:  lvim.keys.normal_mode["<C-q>"] = ":q<cr>"
lvim.leader = "space"

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings['l'] = {
  name = "LSP",
  a = { "<cmd>Telescope lsp_code_actions<cr>", "Code Action" },
  d = {
    name = "Diagnostics",
    d = {"<cmd>Telescope diagnostics<cr>", "Document"},
    n = {
      "<cmd>lua vim.diagnostic.goto_next({popup_opts = {border = lvim.lsp.popup_border}})<cr>",
      "Next Diagnostic",
    },
    p = {
      "<cmd>lua vim.diagnostic.goto_prev({popup_opts = {border = lvim.lsp.popup_border}})<cr>",
      "Prev Diagnostic",
    },
  },
  f = { "<cmd>lua vim.lsp.buf.formatting()<cr>", "Format" },
  p = {
    name = "Peek",
    d = { "<cmd>lua require('lsp.peek').Peek('definition')<cr>", "Definition" },
    t = { "<cmd>lua require('lsp.peek').Peek('typeDefinition')<cr>", "Type Definition" },
    i = { "<cmd>lua require('lsp.peek').Peek('implementation')<cr>", "Implementation" },
    s = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "Signature" },
  },
  g = {
    name = "Goto",
    d = { "<cmd>Telescope lsp_definitions<cr>", "Go To Definition" },
    i = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Go To Impl" },
    s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
    S = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace Symbols" },
  },
  q = { "<cmd>Telescope quickfix<cr>", "Quickfix" },
  r = {
    name = "Run",
    r = { "<cmd>RustRunnables<cr>", "Rust Runnables"},
    h = { "<cmd>RustHoverActions<cr><cmd>RustHoverActions<cr>", "Rust Hover Actions"},
    R = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
  }
}
lvim.builtin.which_key.vmappings['C'] =  {"Cursors at line start", noremap = true}

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.active = true
lvim.builtin.nvimtree.side = "left"
lvim.builtin.nvimtree.show_icons.git = 0

-- if you don't want all the parsers change this to a table of the ones you want
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
lvim.builtin.treesitter.highlight.enabled = true

-- Shutoff default formatting for rust
vim.cmd[[let g:rust_recommended_style=0]]
lvim.plugins = {
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
      vim.g.indent_blankline_filetype_exclude = {"help", "terminal", "dashboard"}
      vim.g.indent_blankline_buftype_exclude = {"terminal"}
      vim.g.indent_blankline_show_trailing_blankline_indent = false
      vim.g.indent_blankline_show_first_indent_level = false
    end
  },
  {
    "mg979/vim-visual-multi",
    config = function()
      vim.cmd ("let g:VM_quit_after_leaving_insert_mode = 1")
      vim.cmd ("let g:VM_skip_empty_lines = 1")
      vim.cmd ("let g:VM_default_mappings = 0")
      vim.cmd ("let g:VM_mouse_mappings = 1")
      vim.cmd ("let g:VM_theme = 'sand'")
      vim.cmd ("let g:VM_maps = {}")
      vim.cmd ("let g:VM_maps['Add Cursor Down'] = '<S-Down>'")
      vim.cmd ("let g:VM_maps['Add Cursor Up'] = '<S-Up>'")
      vim.cmd ("let g:VM_maps['Mouse Cursor'] = '<S-LeftMouse>'")
      vim.cmd ("let g:VM_maps['Visual Cursors'] = '<Space-S-c>'")
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


