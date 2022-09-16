local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
---@diagnostic disable-next-line: missing-parameter
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  snapshot = "stable-2022-09-16",
  snapshot_path = fn.stdpath "config" .. "/snapshots",
  max_jobs = 50,
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
    prompt_border = "rounded", -- Border style of prompt popups.
  },
}

-- Install your plugins here
return packer.startup(function(use)
  -- Plugin Mangager
  use "wbthomason/packer.nvim" -- Have packer manage itself

  -- Lua Development
  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins
  use "nvim-lua/popup.nvim"
  use "christianchiarulli/lua-dev.nvim"

  -- LSP
  use "neovim/nvim-lspconfig" -- enable LSP
  use "williamboman/mason.nvim"
  use "williamboman/mason-lspconfig.nvim"
  use "jose-elias-alvarez/null-ls.nvim" -- for formatters and linters
  use "ray-x/lsp_signature.nvim"
  use "SmiteshP/nvim-navic"
  use "simrat39/symbols-outline.nvim"
  use "b0o/SchemaStore.nvim"
  use "RRethy/vim-illuminate"
  use "j-hui/fidget.nvim"
  use "lvimuser/lsp-inlayhints.nvim"
  use "https://git.sr.ht/~whynothugo/lsp_lines.nvim"

  -- Completion
  use "christianchiarulli/nvim-cmp"
  use "hrsh7th/cmp-buffer" -- buffer completions
  use "hrsh7th/cmp-path" -- path completions
  use "hrsh7th/cmp-cmdline" -- cmdline completions
  use "saadparwaiz1/cmp_luasnip" -- snippet completions
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-emoji"
  use "hrsh7th/cmp-nvim-lua"
  use { "tzachar/cmp-tabnine", commit = "1a8fd2795e4317fd564da269cc64a2fa17ee854e", run = "./install.sh" }

  -- Snippet
  use "L3MON4D3/LuaSnip" --snippet engine
  use "rafamadriz/friendly-snippets" -- a bunch of snippets to use

  -- Syntax/Treesitter
  use "nvim-treesitter/nvim-treesitter"
  use "JoosepAlviste/nvim-ts-context-commentstring"
  use "p00f/nvim-ts-rainbow"
  use "nvim-treesitter/playground"
  use "windwp/nvim-ts-autotag"
  use "nvim-treesitter/nvim-treesitter-textobjects"
  use {
    "abecodes/tabout.nvim",
    wants = { "nvim-treesitter" }, -- or require if not used so far
  }

  -- Fuzzy Finder/Telescope
  use "nvim-telescope/telescope.nvim"
  use "nvim-telescope/telescope-media-files.nvim"
  use "tom-anders/telescope-vim-bookmarks.nvim"

  -- Color / Theme
  use "NvChad/nvim-colorizer.lua"
  use "ziontee113/color-picker.nvim"
  use 'shaunsingh/solarized.nvim'
  use "kyazdani42/nvim-web-devicons"

  -- Utility
  use "rcarriga/nvim-notify"
  use "stevearc/dressing.nvim"
  use "moll/vim-bbye"
  use "lewis6991/impatient.nvim"

  -- Debugging
  use "mfussenegger/nvim-dap"
  use "rcarriga/nvim-dap-ui"

  -- Tabline
  use "akinsho/bufferline.nvim"

  -- Statusline
  use "christianchiarulli/lualine.nvim"

  -- Startup
  use "goolord/alpha-nvim"

  -- Indent
  use "lukas-reineke/indent-blankline.nvim"

  -- File Explorer
  use "kyazdani42/nvim-tree.lua"

  -- Comment
  use "numToStr/Comment.nvim"
  use "folke/todo-comments.nvim"

  -- Terminal
  use "akinsho/toggleterm.nvim"

  -- Project
  use "ahmedkhalf/project.nvim"

  -- Quickfix
  use "kevinhwang91/nvim-bqf"

  -- Code Runner
  use "is0n/jaq-nvim"

  -- Git
  use "lewis6991/gitsigns.nvim"
  use "f-person/git-blame.nvim"
  use "ruifm/gitlinker.nvim"
  use "mattn/webapi-vim"

  -- Editing Support
  use "windwp/nvim-autopairs"
  use "nacro90/numb.nvim"
  use "andymass/vim-matchup"
  use "junegunn/vim-slash"
  use "mg979/vim-visual-multi"

  -- Keybinding
  use "folke/which-key.nvim"

  -- Java
  use "mfussenegger/nvim-jdtls"

  -- Rust
  use { "christianchiarulli/rust-tools.nvim", branch = "modularize_and_inlay_rewrite" }
  use "Saecki/crates.nvim"

  -- Markdown
  use {
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    ft = "markdown",
  }

  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
