return {
  "williamboman/mason.nvim",
  lazy = false,
  dependencies = {
    "neovim/nvim-lspconfig",
    "williamboman/mason-lspconfig.nvim",
    "simrat39/rust-tools.nvim",
    "b0o/SchemaStore.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local lspconfig = require("lspconfig")

    local servers = {
      "cssls",
      "cssmodules_ls",
      "html",
      "jsonls",
      "sumneko_lua",
      "tflint",
      "terraformls",
      "tsserver",
      "pyright",
      "yamlls",
      "bashls",
      "clangd",
      "rust_analyzer",
      "taplo",
      "lemminx"
    }
    local settings = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "◍",
          package_pending = "◍",
          package_uninstalled = "◍",
        },
      },
      log_level = vim.log.levels.INFO,
      max_concurrent_installers = 4,
    }
    mason.setup(settings)
    mason_lspconfig.setup {
      ensure_installed = servers,
      automatic_installation = true,
    }
    local opts = {}
    for _, server in pairs(servers) do
      opts = {
        on_attach = require("config.plugins.lsp.handlers").on_attach,
        capabilities = require("config.plugins.lsp.handlers").capabilities,
      }

      server = vim.split(server, "@")[1]

      if server == "jsonls" then
        local schemastore = require("schemastore")
        local jsonls_opts = require("config.plugins.lsp.settings.jsonls")
        opts = vim.tbl_deep_extend("force", jsonls_opts(schemastore), opts)
      end

      if server == "yamlls" then
        local yamlls_opts = require "config.plugins.lsp.settings.yamlls"
        opts = vim.tbl_deep_extend("force", yamlls_opts, opts)
      end

      if server == "sumneko_lua" then
        local sumneko_lua_opts = require "config.plugins.lsp.settings.sumneko_lua"
        opts = vim.tbl_deep_extend("force", sumneko_lua_opts, opts)
      end

      if server == "tsserver" then
        local tsserver_opts = require "config.plugins.lsp.settings.tsserver"
        opts = vim.tbl_deep_extend("force", tsserver_opts, opts)
      end

      if server == "pyright" then
        local pyright_opts = require "config.plugins.lsp.settings.pyright"
        opts = vim.tbl_deep_extend("force", pyright_opts, opts)
      end

      if server == "rust_analyzer" then
        local rust_opts = require("config.plugins.lsp.settings.rust")
        local rust_tools = require("rust-tools")
        rust_tools.setup(rust_opts)
        goto continue
      end

      lspconfig[server].setup(opts)
      ::continue::
    end
  end
}
