local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"git@github.com:folke/lazy.nvim.git",
		lazypath,
	})
end 
vim.opt.runtimepath:prepend(lazypath)

-- Nuance: These have to be set before lazy, period
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("lazy").setup("config.plugins", {
	defaults = { lazy = true },
	checker = { enabled = true },
})
require("config.keymaps")
require("config.autocommands")
require("config.winbar")
