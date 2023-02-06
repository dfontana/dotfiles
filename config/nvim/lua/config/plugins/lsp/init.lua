return {
  "VonHeikemen/lsp-zero.nvim",
  lazy = false,
  dependencies = {
    -- LSP Support
    "neovim/nvim-lspconfig",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",

    -- Autocompletion
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-nvim-lua",

    -- Snippets
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",

    -- Virtual text
    { url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim" },

    -- Inlay hints (For non-rust code)
    "lvimuser/lsp-inlayhints.nvim",

    -- Rust
    "simrat39/rust-tools.nvim",

    -- json
    "b0o/SchemaStore.nvim",
  },
  config = function()
    local lsp = require("lsp-zero")
    lsp.preset("recommended")

    lsp.set_preferences({
      set_lsp_keymaps = false,
    })

    lsp.setup_nvim_cmp({
      preselect = "none",
      completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      },
    })

    lsp.on_attach(function(client, bufnr)
      vim.g.navic_silence = true
      local status_ok, navic = pcall(require, "nvim-navic")
      if not status_ok then
        return
      end
      navic.attach(client, bufnr)

      if client.name == "tsserver" then
        require("lsp-inlayhints").on_attach(client, bufnr)
      end
    end)

    -- Neovim+Lua
    lsp.nvim_workspace()

    -- Rust
		local rust_opts = require("config.plugins.lsp.settings.rust")
		local rust_lsp = lsp.build_options("rust_analyzer", {})

    -- JSON
    local schemastore = require("schemastore")
    local jsonls = require("config.plugins.lsp.settings.jsonls")
    local jsonls_opts = jsonls(schemastore)
    lsp.configure("jsonls", jsonls_opts)

    -- YAML
    local yamlls_opts = require("config.plugins.lsp.settings.yamlls")
    lsp.configure("yamlls", yamlls_opts)

    -- Javascript + Typescript
    local tsserver_opts = require("config.plugins.lsp.settings.tsserver")
    lsp.configure("tsserver", tsserver_opts)

    -- Python
    local pyright_opts = require("config.plugins.lsp.settings.pyright")
    lsp.configure("pyright", pyright_opts)

    lsp.setup()

    -- Additional setups that should happen after setup()
    vim.cmd("let g:rust_recommended_style = 0")
		require("rust-tools").setup(rust_opts(rust_lsp))
		require("lsp_lines").setup()
	end,
}
