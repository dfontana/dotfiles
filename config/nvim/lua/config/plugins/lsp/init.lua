return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim"},
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    require("lspconfig")
    require("config.plugins.lsp.handlers").setup()
    require("lsp_lines").setup()
  end
}
