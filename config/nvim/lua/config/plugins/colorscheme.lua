return {
  -- "shaunsingh/solarized.nvim",
  -- lazy = false,
  -- config = function()
  --   vim.opt.background = "light"
  --   vim.g.solarized_italic_keywords = false
  --   vim.g.solarized_italic_functions = false
  --   vim.g.solarized_italic_comments = true
  --   require('solarized').set()
  -- end
  "catppuccin/nvim",
  lazy = false,
  config = function()
    require("catppuccin").setup({
      integrations = {
        gitsigns = true,
        hop = true,
        mason = true,
        neotree = true,
        noice = true,
        cmp = true,
        notify = true,
        treesitter = true,
        ts_rainbow = true,
        symbols_outline = true,
        telescope = true,
        illuminate = true,
        which_key = true,

        -- Special ones
        dap = {
            enabled = true,
            enable_ui = true,
        },
        indent_blankline = {
            enabled = true,
            colored_indent_levels = false,
        },
        native_lsp = {
            enabled = true,
            virtual_text = {
                errors = { "italic" },
                hints = { "italic" },
                warnings = { "italic" },
                information = { "italic" },
            },
            underlines = {
                errors = { "underline" },
                hints = { "underline" },
                warnings = { "underline" },
                information = { "underline" },
            },
        },
        navic = {
            enabled = true,
            custom_bg = "NONE",
        },
      }
    })
    vim.cmd('colorscheme catppuccin-macchiato')
  end
}
