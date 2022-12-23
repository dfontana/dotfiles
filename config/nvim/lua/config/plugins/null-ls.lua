return {
  "jose-elias-alvarez/null-ls.nvim",
  lazy = false,
  config = function()
    local null_ls = require("null-ls")
    local formatting = null_ls.builtins.formatting
    local diagnostics = null_ls.builtins.diagnostics
    null_ls.setup {
      debug = false,
      sources = {
        formatting.prettier.with {
          extra_filetypes = { "toml", "solidity", "scss" },
          extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
        },
        formatting.black.with { extra_args = { "--fast" } },
        formatting.stylua,
        formatting.shfmt,
        diagnostics.shellcheck,
      },
    }
  end
}
