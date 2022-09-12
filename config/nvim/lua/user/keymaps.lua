local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
  return
end

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

M = {}
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Set the Leader (Space)
keymap("n", "<Space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
keymap("n", "<C-Space>", "<cmd>WhichKey \\<leader><cr>", opts)
keymap("n", "<C-i>", "<C-i>", opts)

-- Multiple Cursors, via vim-visual-multi
-- (More here: https://github.com/mg979/vim-visual-multi/wiki/Mappings)
vim.cmd("let g:VM_maps = {}")
vim.cmd("let g:VM_maps['Add Cursor Down'] = '<S-Down>'")
vim.cmd("let g:VM_maps['Add Cursor Up'] = '<S-Up>'")
vim.cmd("let g:VM_maps['Mouse Cursor'] = '<S-LeftMouse>'")
vim.cmd("let g:VM_maps['Visual Cursors'] = '<Space-S-c>'")

-- Resize splits Alt+Arrows
keymap("n", "<M-Up>", ":resize -2<CR>", opts)
keymap("n", "<M-Down>", ":resize +2<CR>", opts)
keymap("n", "<M-Right>", ":vertical resize -2<CR>", opts)
keymap("n", "<M-Left>", ":vertical resize +2<CR>", opts)

-- When indenting, don't leave after indent
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

local kopts = {
  mode = "n", -- NORMAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true, -- use `nowait` when creating keymaps
}
local mappings = {
  K = {
    name = "Keymappings",
    ["<M-Up>"] = "Resize Split Up",
    ["<M-Down>"] = "Resize Split Down",
    ["<M-Left>"] = "Resize Split Left",
    ["<M-Right>"] = "Resize Split Right",
    ["<S-Up>"] = "Add Cursor Above",
    ["<S-Down>"] = "Add Cursor Below",
  }
}
which_key.register(mappings, kopts)
return M
