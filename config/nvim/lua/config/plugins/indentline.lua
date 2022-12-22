return {
  "lukas-reineke/indent-blankline.nvim",
  lazy = false,
  config = function()
    local indent_blankline = require("indent_blankline")
    vim.g.indent_blankline_buftype_exclude = { "terminal", "nofile" }
    vim.g.indent_blankline_filetype_exclude = {
      "help",
      "startify",
      "dashboard",
      "packer",
      "neogitstatus",
      "NvimTree",
      "Trouble",
      "text"
    }
    vim.g.indentLine_enabled = 1
    vim.g.indent_blankline_char = "▏"
    vim.g.indent_blankline_show_trailing_blankline_indent = false
    vim.g.indent_blankline_show_first_indent_level = true
    vim.g.indent_blankline_use_treesitter = false
    vim.g.indent_blankline_show_current_context = true
    indent_blankline.setup {
      show_current_context = true,
    }
  end
}
